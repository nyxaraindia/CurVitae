
import 'dart:async';
import 'dart:convert';


import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'core.dart';

class NyxaraException implements Exception {
  NyxaraException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Nyxara AI: the CV generation engine for CurVitae.
class NyxaraAI {
  NyxaraAI._();

  // Primary model followed by fallbacks.
  // Verify the exact model IDs in your Gemini API model list.
  static const List<String> _candidateModels = [
    'gemini-3.1-flash-lite',
    'gemini-3.8-flash',
    'gemini-3.6-flash',
    'gemini-3.5-flash-lite',
    'gemini-3-flash',
  ];

  static const String _busyMessage =
      'Nyxara AI is busy right now. Please try again in a moment.';

  static const String _systemInstruction = r'''
You are Nyxara AI, the CV intelligence engine inside the CurVitae app.
Act as a senior recruiter, ATS specialist and professional resume writer.

MISSION
Create a polished, recruiter-ready CV while staying completely truthful.

NON-NEGOTIABLE RULES
1. Never invent employers, job titles, degrees, institutions, dates,
   certifications, tools, achievements or numbers.
2. Missing information must be empty strings or empty lists.
   Never use placeholders such as N/A, Lorem ipsum or Your Name.
3. Preserve the candidate's real name, email, phone and links exactly.
4. Return exactly one valid JSON object. No Markdown or commentary.

WRITING STANDARDS
- Headline: concise, maximum 8 words, tailored to the target role.
- Summary: exactly 3 sentences, maximum 55 words.
- Experience bullets: use strong action verbs and specific facts supplied.
  Never invent metrics or outcomes.
- Skills: 8 to 16 relevant, de-duplicated items when the information supports
  them. Do not invent skills just to reach a target count.
- Projects: describe the problem solved and result only when supported
  by the supplied information, and include a tech list.
- Freshers: emphasize education, projects, internships and skills.
- Order experience and education in reverse chronological order.
- Use flawless grammar and consistent date formats.
- Professional tone: polished and measured.
- Confident tone: assertive and achievement-led.
- Creative tone: vivid but recruiter-safe.

OUTPUT SCHEMA
{
  "name": "",
  "title": "",
  "summary": "",
  "skills": [],
  "experience": [
    {
      "role": "",
      "company": "",
      "location": "",
      "duration": "",
      "highlights": []
    }
  ],
  "projects": [
    {
      "title": "",
      "tech": [],
      "description": ""
    }
  ],
  "education": [
    {
      "degree": "",
      "institution": "",
      "year": "",
      "details": ""
    }
  ],
  "certifications": [],
  "languages": [],
  "contact": {
    "email": "",
    "phone": "",
    "location": "",
    "links": []
  }
}
''';

  /// Builds a CV from an uploaded PDF resume.
  static Future<Map<String, dynamic>> cvFromResume({
    required Uint8List resumeBytes,
    String targetRole = '',
    String tone = 'Professional',
  }) {
    if (resumeBytes.isEmpty) {
      throw NyxaraException(
        'The selected resume PDF is empty. Please choose the PDF again.',
      );
    }

    final headerLength =
        resumeBytes.length < 5 ? resumeBytes.length : 5;
    final header = String.fromCharCodes(
      resumeBytes.sublist(0, headerLength),
    );

    if (!header.startsWith('%PDF-')) {
      throw NyxaraException(
        'The selected file does not look like a valid PDF. '
        'Please upload a PDF resume.',
      );
    }

    final prompt = '''
TASK
Read the attached resume PDF and rebuild it as a polished,
recruiter-ready CV. Extract information from all pages, including
tables, sidebars and multi-column layouts where readable.

PROFILE HINTS FROM THE APP
Use these only when the resume does not contain the information.

Name: ${UserProfile.hasName ? UserProfile.name : ''}
Headline: ${UserProfile.title}
Email: ${UserProfile.email}

TARGET ROLE:
${targetRole.trim().isEmpty ? 'Not specified. Infer the best-fitting role from the resume.' : targetRole.trim()}

TONE: $tone

INSTRUCTIONS
1. Extract the facts before rewriting the CV.
2. Tailor the headline, summary and skill order to the target role.
3. Merge duplicates and keep dates consistent without inventing dates.
4. Preserve all real contact information.
5. Return only the JSON object following your system instructions.
''';

    return _withStatus(
      const [
        'Nyxara AI is reading your resume...',
        'Understanding your experience...',
        'Writing sharper bullet points...',
        'Polishing your CV...',
      ],
      () => _generate(
        Content.multi([
          TextPart(prompt),
          DataPart('application/pdf', resumeBytes),
        ]),
      ),
    );
  }

  /// Builds a CV from manually entered details.
  static Future<Map<String, dynamic>> cvFromDetails({
    required String detailsBlock,
    String tone = 'Professional',
  }) {
    final prompt = '''
TASK
Build a complete, polished, recruiter-ready CV from the details below.

CANDIDATE DETAILS
$detailsBlock

TONE: $tone

INSTRUCTIONS
1. Use the candidate's details as the only source of truth.
2. Improve wording without adding facts, employers, dates or metrics.
3. Write a professional headline and summary aligned with the candidate's
   stated target role and career level.
4. Convert notes into clear, action-oriented bullet points when supported.
5. For freshers, emphasize education, projects and skills.
6. Return only the JSON object following your system instructions.
''';

    return _withStatus(
      const [
        'Nyxara AI is studying your details...',
        'Crafting your professional summary...',
        'Turning notes into powerful bullets...',
        'Polishing your CV...',
      ],
      () => _generate(Content.text(prompt)),
    );
  }

  /// Displays progress messages while a request is running.
  static Future<T> _withStatus<T>(
    List<String> messages,
    Future<T> Function() task,
  ) async {
    var index = 0;
    AiBusy.update(messages.first);

    final timer = Timer.periodic(
      const Duration(seconds: 4),
      (_) {
        index = (index + 1) % messages.length;
        AiBusy.update(messages[index]);
      },
    );

    try {
      return await task();
    } finally {
      timer.cancel();
    }
  }

  /// Identifies errors that may be temporary or caused by quota limits.
  static bool _isTemporaryOrQuotaError(Object error) {
    final message = error.toString().toUpperCase();

    return message.contains('503') ||
        message.contains('UNAVAILABLE') ||
        message.contains('429') ||
        message.contains('RESOURCE_EXHAUSTED') ||
        message.contains('500') ||
        message.contains('502') ||
        message.contains('504') ||
        message.contains('SOCKETEXCEPTION') ||
        message.contains('TIMEOUT');
  }

  /// Tries each configured model and retries temporary failures once.
  static Future<Map<String, dynamic>> _generate(
    Content content,
  ) async {
    Object? lastError;

    for (final modelName in _candidateModels) {
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          final model = GenerativeModel(
            model: modelName,
            apiKey: AppConfig.geminiApiKey,
            systemInstruction: Content.system(_systemInstruction),
            generationConfig: GenerationConfig(
              temperature: 0.5,
              responseMimeType: 'application/json',
            ),
          );

          final response = await model.generateContent([content]);
          final responseText = response.text ?? '';

          if (responseText.trim().isEmpty) {
            throw const FormatException(
              'The AI returned an empty response.',
            );
          }

          final result = _extractJson(responseText);

          if (result.isEmpty) {
            throw const FormatException(
              'The AI response did not contain a valid CV.',
            );
          }

          return result;
        } catch (error, stackTrace) {
          lastError = error;

          // Technical details appear only in the developer console.
          debugPrint(
            'Nyxara AI model $modelName, '
            'attempt ${attempt + 1}: $error',
          );
          debugPrintStack(stackTrace: stackTrace);

          final shouldRetry =
              attempt == 0 && _isTemporaryOrQuotaError(error);

          if (shouldRetry) {
            await Future<void>.delayed(
              Duration(seconds: attempt + 2),
            );
            continue;
          }

          // Move to the next model.
          break;
        }
      }
    }

    debugPrint(
      'Nyxara AI failed after trying configured models: $lastError',
    );

    // Do not expose API errors, model names or technical details to users.
    throw NyxaraException(_busyMessage);
  }

  /// Extracts the JSON object from the model response.
  static Map<String, dynamic> _extractJson(String raw) {
    var text = raw.trim();

    if (text.contains('```json')) {
      text = text.split('```json')[1].split('```')[0].trim();
    } else if (text.contains('```')) {
      text = text.split('```')[1].split('```')[0].trim();
    }

    final first = text.indexOf('{');
    final last = text.lastIndexOf('}');

    if (first == -1 || last == -1 || last < first) {
      return {};
    }

    final decoded = jsonDecode(
      text.substring(first, last + 1),
    );

    return decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : {};
  }
}
