import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'core.dart';

/// Builds and previews the final CV PDF.
class CvPdf {
  CvPdf._();

  static String _s(dynamic v) => v == null ? '' : v.toString().trim();
  static List<dynamic> _l(dynamic v) => v is List ? v : const [];
  static Map<String, dynamic> _m(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  static List<String> _strings(dynamic v) =>
      _l(v).map(_s).where((e) => e.isNotEmpty).toList();

  static PdfColor _mix(PdfColor c, double t) => PdfColor(
        c.red + (1 - c.red) * t,
        c.green + (1 - c.green) * t,
        c.blue + (1 - c.blue) * t,
      );

  static Future<void> preview(Uint8List bytes, String name) async {
    await Printing.layoutPdf(
      name: 'CurVitae_${name.replaceAll(' ', '_')}',
      onLayout: (PdfPageFormat format) async => bytes,
    );
  }

  static Future<Uint8List> build(
    Map<String, dynamic> data, {
    Uint8List? photo,
    CvStyle style = CvStyle.ocean,
  }) async {
    final accent = PdfColor(style.color.r, style.color.g, style.color.b);
    final tint = _mix(accent, 0.88);
    final soft = _mix(accent, 0.70);

    final name =
        _s(data['name']).isNotEmpty ? _s(data['name']) : UserProfile.name;
    final title =
        _s(data['title']).isNotEmpty ? _s(data['title']) : UserProfile.title;

    final contact = _m(data['contact']);
    final email = _s(contact['email']).isNotEmpty
        ? _s(contact['email'])
        : UserProfile.email;
    final contactItems = <String>[
      email,
      _s(contact['phone']),
      _s(contact['location']),
      ..._strings(contact['links']),
    ].where((e) => e.isNotEmpty).toList();

    final photoImage = photo != null ? pw.MemoryImage(photo) : null;

    // ---- small builders -----------------------------------------------------
    pw.Widget heading(String text) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 16, bottom: 7),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                text.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                  color: accent,
                  letterSpacing: 1.3,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Divider(color: soft, thickness: 0.8, height: 1),
            ],
          ),
        );

    pw.Widget bullet(String text) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2.5, left: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 4, right: 7),
                width: 3.5,
                height: 3.5,
                decoration:
                    pw.BoxDecoration(color: accent, shape: pw.BoxShape.circle),
              ),
              pw.Expanded(
                child: pw.Text(text,
                    style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 2)),
              ),
            ],
          ),
        );

    pw.Widget chip(String text) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: pw.BoxDecoration(
            color: tint,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            border: pw.Border.all(color: soft, width: 0.6),
          ),
          child: pw.Text(text,
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey900)),
        );

    // ---- content ------------------------------------------------------------
    final summary = _s(data['summary']);
    final skills = _strings(data['skills']);
    final experience = _l(data['experience']).map(_m).toList();
    final projects = _l(data['projects']).map(_m).toList();
    final education = _l(data['education']).map(_m).toList();
    final certifications = _strings(data['certifications']);
    final languages = _strings(data['languages']);

    final doc = pw.Document(title: '$name - CV', author: name, creator: 'CurVitae');

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 34),
        ),
        footer: (ctx) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Created with CurVitae by Nyxara',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
              pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
            ],
          ),
        ),
        build: (ctx) => [
          // Header band
          pw.Container(
            padding: const pw.EdgeInsets.all(22),
            decoration: pw.BoxDecoration(
              color: accent,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(14)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(name,
                          style: pw.TextStyle(
                              fontSize: 26,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                      if (title.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(title,
                            style: pw.TextStyle(fontSize: 12.5, color: _mix(accent, 0.85))),
                      ],
                      if (contactItems.isNotEmpty) ...[
                        pw.SizedBox(height: 11),
                        pw.Wrap(
                          spacing: 14,
                          runSpacing: 4,
                          children: contactItems
                              .map((c) => pw.Text(c,
                                  style: const pw.TextStyle(
                                      fontSize: 9, color: PdfColors.white)))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                if (photoImage != null)
                  pw.Container(
                    width: 74,
                    height: 74,
                    margin: const pw.EdgeInsets.only(left: 16),
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: PdfColors.white, width: 2),
                      image: pw.DecorationImage(image: photoImage, fit: pw.BoxFit.cover),
                    ),
                  ),
              ],
            ),
          ),

          if (summary.isNotEmpty) ...[
            heading('Profile'),
            pw.Text(summary,
                style: const pw.TextStyle(fontSize: 10, lineSpacing: 3)),
          ],

          if (skills.isNotEmpty) ...[
            heading('Core Skills'),
            pw.Wrap(spacing: 5, runSpacing: 5, children: skills.map(chip).toList()),
          ],

          if (experience.isNotEmpty) ...[
            heading('Professional Experience'),
            ...experience.map((e) {
              final company = [_s(e['company']), _s(e['location'])]
                  .where((x) => x.isNotEmpty)
                  .join(', ');
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(_s(e['role']),
                              style: pw.TextStyle(
                                  fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Text(_s(e['duration']),
                            style: pw.TextStyle(
                                fontSize: 9, color: accent, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    if (company.isNotEmpty)
                      pw.Text(company,
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontStyle: pw.FontStyle.italic,
                              color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    ..._strings(e['highlights']).map(bullet),
                  ],
                ),
              );
            }),
          ],

          if (projects.isNotEmpty) ...[
            heading('Projects'),
            ...projects.map((p) {
              final tech = _strings(p['tech']).join(' | ');
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(_s(p['title']),
                        style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
                    if (tech.isNotEmpty)
                      pw.Text(tech, style: pw.TextStyle(fontSize: 8.5, color: accent)),
                    if (_s(p['description']).isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(_s(p['description']),
                          style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 2)),
                    ],
                  ],
                ),
              );
            }),
          ],

          if (education.isNotEmpty) ...[
            heading('Education'),
            ...education.map((e) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 7),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(_s(e['degree']),
                                style: pw.TextStyle(
                                    fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Text(_s(e['year']),
                              style: pw.TextStyle(
                                  fontSize: 9, color: accent, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Text(_s(e['institution']),
                          style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700)),
                      if (_s(e['details']).isNotEmpty)
                        pw.Text(_s(e['details']),
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                )),
          ],

          if (certifications.isNotEmpty) ...[
            heading('Certifications'),
            ...certifications.map(bullet),
          ],

          if (languages.isNotEmpty) ...[
            heading('Languages'),
            pw.Text(languages.join('  |  '), style: const pw.TextStyle(fontSize: 9.5)),
          ],
        ],
      ),
    );

    return doc.save();
  }
}
