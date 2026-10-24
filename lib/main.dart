

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'core.dart';
import 'cv_pdf.dart';
import 'firebase_options.dart';
import 'nyxara_ai.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('Firebase initialized successfully.');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  try {
    await dotenv.load(fileName: 'key.env');
  } catch (e) {
    debugPrint('key.env load error: $e');
  }

  runApp(const CurVitaeApp());
}

// =============================================================================
// App
// =============================================================================

class CurVitaeApp extends StatelessWidget {
  const CurVitaeApp({super.key});

  ThemeData _theme(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConfig.brandSeed,
        brightness: brightness,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: ThemeMode.system,
      // The Nyxara loading overlay sits above every screen while AiBusy is set.
      builder: (context, child) {
        return ValueListenableBuilder<String?>(
          valueListenable: AiBusy.status,
          builder: (context, status, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                ?child,
                if (status != null)
                  Positioned.fill(
                    // Blocks taps on the screen underneath while the AI works.
                    child: AbsorbPointer(child: NyxaraLoadingOverlay(status: status)),
                  ),
              ],
            );
          },
        );
      },
      home: const LoginScreen(),
    );
  }
}

// =============================================================================
// Login
// =============================================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase is not initialized yet.');
      }

      late final UserCredential userCredential;

      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final googleSignIn = GoogleSignIn();
        try {
          await googleSignIn.signOut();
        } catch (_) {}

        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }

        final googleAuth = await googleUser.authentication;
        if (googleAuth.accessToken == null && googleAuth.idToken == null) {
          throw Exception('Failed to obtain Google authentication tokens.');
        }

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user != null) {
        final display = user.displayName?.trim() ?? '';
        UserProfile.name = display.isNotEmpty ? display : 'Google User';
        UserProfile.email = user.email ?? UserProfile.email;
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } catch (e) {
      debugPrint('Sign-in exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in error: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: CurVitaeLogo(height: 110)),
                  const SizedBox(height: 28),
                  Text(
                    'Your CV, written by AI.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload a resume or type your details and get a recruiter-ready PDF.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 36),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    FilledButton.icon(
                      onPressed: _handleGoogleSignIn,
                      icon: const Icon(Icons.g_mobiledata, size: 30),
                      label: const Text('Continue with Google'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const NyxaraLogo(size: 22),
                      const SizedBox(width: 8),
                      Text('Powered by Nyxara AI',
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Home shell: Home / From Resume / From Details / Profile
// =============================================================================

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  // Shared CV options
  CvStyle _style = CvStyle.ocean;
  String _tone = kTones.first;
  PlatformFile? _resume;
  PlatformFile? _photo;
  final _role = TextEditingController();

  // "From details" form
  final _skills = TextEditingController();
  final _about = TextEditingController();
  final _certs = TextEditingController();
  final _languages = TextEditingController();
  final _experience = EntryListController(4, initialRows: 1);
  final _education = EntryListController(3, initialRows: 1);
  final _projects = EntryListController(3);

  // Profile form
  final _pName = TextEditingController(text: UserProfile.name);
  final _pTitle = TextEditingController(text: UserProfile.title);
  final _pEmail = TextEditingController(text: UserProfile.email);
  final _pPhone = TextEditingController(text: UserProfile.phone);
  final _pLocation = TextEditingController(text: UserProfile.location);
  final _pLink = TextEditingController(text: UserProfile.link);

  @override
  void dispose() {
    for (final c in [
      _role, _skills, _about, _certs, _languages,
      _pName, _pTitle, _pEmail, _pPhone, _pLocation, _pLink,
    ]) {
      c.dispose();
    }
    _experience.dispose();
    _education.dispose();
    _projects.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // helpers
  // ---------------------------------------------------------------------------

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<PlatformFile?> _pick({required bool pdf}) async {
    final result = await FilePicker.platform.pickFiles(
      type: pdf ? FileType.custom : FileType.image,
      allowedExtensions: pdf ? ['pdf'] : null,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.first;
  }

  /// Runs an AI job, builds the PDF and opens the preview/print sheet.
  Future<void> _generate(Future<Map<String, dynamic>> Function() job) async {
    if (AiBusy.isBusy) return;

    AiBusy.start('Nyxara AI is getting ready...');
    Uint8List? pdfBytes;
    var name = UserProfile.name;

    try {
      final data = await job();
      AiBusy.update('Designing your PDF...');
      pdfBytes = await CvPdf.build(data, photo: _photo?.bytes, style: _style);
      final n = data['name']?.toString().trim() ?? '';
      if (n.isNotEmpty) name = n;
    } on NyxaraException catch (e) {
      _snack(e.message);
    } catch (e) {
      debugPrint('CV generation error: $e');
      _snack('Something went wrong while creating your CV. Please try again.');
    } finally {
      AiBusy.stop();
    }

    if (pdfBytes != null && mounted) {
      await CvPdf.preview(pdfBytes, name);
    }
  }

  Future<void> _createFromResume() async {
    final bytes = _resume?.bytes;
    if (bytes == null) {
      _snack('Please upload your resume PDF first.');
      return;
    }
    await _generate(() => NyxaraAI.cvFromResume(
          resumeBytes: bytes,
          targetRole: _role.text,
          tone: _tone,
        ));
  }

  String _detailsBlock() {
    final b = StringBuffer();
    void line(String label, String value) {
      if (value.trim().isNotEmpty) b.writeln('$label: ${value.trim()}');
    }

    line('Name', UserProfile.hasName ? UserProfile.name : '');
    line('Target role', _role.text);
    line('Current headline', UserProfile.title);
    line('Email', UserProfile.email);
    line('Phone', UserProfile.phone);
    line('Location', UserProfile.location);
    line('Link', UserProfile.link);
    line('About / notes', _about.text);
    line('Skills', _skills.text);

    final exp = _experience.values();
    if (exp.isNotEmpty) {
      b.writeln('\nExperience:');
      for (final r in exp) {
        b.writeln('- ${r[0]}'
            '${r[1].isNotEmpty ? ' at ${r[1]}' : ''}'
            '${r[2].isNotEmpty ? ' (${r[2]})' : ''}'
            '${r[3].isNotEmpty ? ': ${r[3]}' : ''}');
      }
    }

    final edu = _education.values();
    if (edu.isNotEmpty) {
      b.writeln('\nEducation:');
      for (final r in edu) {
        b.writeln('- ${r[0]}'
            '${r[1].isNotEmpty ? ', ${r[1]}' : ''}'
            '${r[2].isNotEmpty ? ' (${r[2]})' : ''}');
      }
    }

    final proj = _projects.values();
    if (proj.isNotEmpty) {
      b.writeln('\nProjects:');
      for (final r in proj) {
        b.writeln('- ${r[0]}'
            '${r[1].isNotEmpty ? ' [Tech: ${r[1]}]' : ''}'
            '${r[2].isNotEmpty ? ': ${r[2]}' : ''}');
      }
    }

    if (_certs.text.trim().isNotEmpty) {
      b.writeln('\nCertifications:\n${_certs.text.trim()}');
    }
    line('Languages', _languages.text);

    return b.toString().trim();
  }

  Future<void> _createFromDetails() async {
    if (!UserProfile.hasName) {
      _snack('Add your name in the Profile tab first.');
      setState(() => _tab = 3);
      return;
    }
    final hasContent = _skills.text.trim().isNotEmpty ||
        _about.text.trim().isNotEmpty ||
        _experience.values().isNotEmpty ||
        _education.values().isNotEmpty ||
        _projects.values().isNotEmpty;
    if (!hasContent) {
      _snack('Add some skills, education, experience or projects first.');
      return;
    }
    final block = _detailsBlock();
    await _generate(() => NyxaraAI.cvFromDetails(detailsBlock: block, tone: _tone));
  }

  void _saveProfile() {
    setState(() {
      UserProfile.name = _pName.text.trim().isEmpty ? 'Guest' : _pName.text.trim();
      UserProfile.title = _pTitle.text.trim();
      UserProfile.email = _pEmail.text.trim();
      UserProfile.phone = _pPhone.text.trim();
      UserProfile.location = _pLocation.text.trim();
      UserProfile.link = _pLink.text.trim();
    });
    FocusScope.of(context).unfocus();
    _snack('Profile saved.');
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!kIsWeb) await GoogleSignIn().signOut();
    } catch (_) {}
    UserProfile.name = 'Guest';
    UserProfile.title = '';
    UserProfile.email = '';
    UserProfile.phone = '';
    UserProfile.location = '';
    UserProfile.link = '';
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // ---------------------------------------------------------------------------
  // tabs
  // ---------------------------------------------------------------------------

  Widget _homeTab() {
    final cs = Theme.of(context).colorScheme;
    final greeting = UserProfile.hasName ? 'Hello, ${UserProfile.name}' : 'Hello';

    Widget action(IconData icon, String title, String subtitle, int tab) {
      return Card.outlined(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cs.outlineVariant),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: cs.primaryContainer,
            child: Icon(icon, color: cs.onPrimaryContainer),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_rounded),
          onTap: () => setState(() => _tab = tab),
        ),
      );
    }

    return TabBody(children: [
      const SizedBox(height: 4),
      Text(greeting,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text('What would you like to do today?',
          style: TextStyle(color: cs.onSurfaceVariant)),
      const SizedBox(height: 16),
      const NyxaraCard(),
      const SizedBox(height: 16),
      action(Icons.upload_file_rounded, 'Improve my resume',
          'Upload a PDF and get a polished CV', 1),
      action(Icons.edit_note_rounded, 'Build from scratch',
          'No resume? Type your details instead', 2),
    ]);
  }

  /// Target role, tone, style and photo, shared by both creation tabs.
  List<Widget> _optionsSection() {
    return [
      const SectionTitle('Target role', icon: Icons.track_changes_rounded),
      TextField(
        controller: _role,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Job you are aiming for (optional)',
          hintText: 'e.g. Flutter Developer',
        ),
      ),
      const SectionTitle('Tone', icon: Icons.record_voice_over_rounded),
      ToneSelector(value: _tone, onChanged: (v) => setState(() => _tone = v)),
      const SectionTitle('CV colour', icon: Icons.palette_rounded),
      StyleSelector(value: _style, onChanged: (v) => setState(() => _style = v)),
      const SectionTitle('Photo', icon: Icons.account_circle_rounded),
      FilePickTile(
        icon: Icons.add_a_photo_outlined,
        title: 'Add a profile photo',
        subtitle: 'Optional, shown in the CV header',
        file: _photo,
        onTap: () async {
          final f = await _pick(pdf: false);
          if (f != null) setState(() => _photo = f);
        },
        onClear: () => setState(() => _photo = null),
      ),
    ];
  }

  Widget _resumeTab() {
    return TabBody(children: [
      const SectionTitle('Your resume', icon: Icons.description_rounded),
      FilePickTile(
        icon: Icons.upload_file_rounded,
        title: 'Upload resume (PDF)',
        subtitle: 'Nyxara AI reads every page',
        file: _resume,
        onTap: () async {
          final f = await _pick(pdf: true);
          if (f != null) setState(() => _resume = f);
        },
        onClear: () => setState(() => _resume = null),
      ),
      ..._optionsSection(),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: _createFromResume,
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('Create my CV'),
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
      ),
    ]);
  }

  Widget _detailsTab() {
    return TabBody(children: [
      const SectionTitle('About you', icon: Icons.person_rounded),
      TextField(
        controller: _about,
        minLines: 3,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Short notes about yourself',
          hintText: 'Who you are, what you do, what you want next',
        ),
      ),
      const SectionTitle('Skills', icon: Icons.bolt_rounded),
      TextField(
        controller: _skills,
        minLines: 1,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Skills, separated by commas',
          hintText: 'Flutter, Dart, Firebase, Git',
        ),
      ),
      EntryListSection(
        title: 'Experience',
        icon: Icons.work_rounded,
        addLabel: 'Add experience',
        emptyHint: 'Internships and jobs. Skip this if you are a fresher.',
        controller: _experience,
        labels: const ['Role', 'Company', 'Duration (e.g. Jun 2024 - Present)', 'What you did'],
        multilineIndex: 3,
      ),
      EntryListSection(
        title: 'Education',
        icon: Icons.school_rounded,
        addLabel: 'Add education',
        emptyHint: 'Add your degrees and schools.',
        controller: _education,
        labels: const ['Degree', 'Institution', 'Year'],
      ),
      EntryListSection(
        title: 'Projects',
        icon: Icons.rocket_launch_rounded,
        addLabel: 'Add project',
        emptyHint: 'Add projects you built.',
        controller: _projects,
        labels: const ['Project title', 'Tech used', 'What it does'],
        multilineIndex: 2,
      ),
      const SectionTitle('Certifications', icon: Icons.workspace_premium_rounded),
      TextField(
        controller: _certs,
        minLines: 2,
        maxLines: 5,
        decoration: const InputDecoration(labelText: 'One certification per line'),
      ),
      const SectionTitle('Languages', icon: Icons.translate_rounded),
      TextField(
        controller: _languages,
        decoration: const InputDecoration(
          labelText: 'Languages, separated by commas',
          hintText: 'English, Malayalam, Hindi',
        ),
      ),
      ..._optionsSection(),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: _createFromDetails,
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('Create my CV'),
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
      ),
    ]);
  }

  Widget _profileTab() {
    Widget field(TextEditingController c, String label, IconData icon,
        {TextInputType? keyboard}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          controller: c,
          keyboardType: keyboard,
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        ),
      );
    }

    return TabBody(children: [
      const SectionTitle('Your profile', icon: Icons.badge_rounded),
      field(_pName, 'Full name', Icons.person_outline_rounded),
      field(_pTitle, 'Professional headline', Icons.work_outline_rounded),
      field(_pEmail, 'Email', Icons.email_outlined, keyboard: TextInputType.emailAddress),
      field(_pPhone, 'Phone', Icons.phone_outlined, keyboard: TextInputType.phone),
      field(_pLocation, 'Location', Icons.location_on_outlined),
      field(_pLink, 'LinkedIn / portfolio link', Icons.link_rounded, keyboard: TextInputType.url),
      const SizedBox(height: 6),
      FilledButton(
        onPressed: _saveProfile,
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        child: const Text('Save profile'),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Log out'),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  // build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: AiBusy.status,
      builder: (context, status, child) => PopScope(
        canPop: status == null, // no back-press while Nyxara AI is working
        child: child!,
      ),
      child: _scaffold(context),
    );
  }

  Widget _scaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: CurVitaeLogo(height: 34, radius: 8),
        ),
        actions: [
          IconButton(
            tooltip: 'About Nyxara AI',
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: NyxaraCard(),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [_homeTab(), _resumeTab(), _detailsTab(), _profileTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.upload_file_outlined), selectedIcon: Icon(Icons.upload_file_rounded), label: 'Resume'),
          NavigationDestination(icon: Icon(Icons.edit_note_outlined), selectedIcon: Icon(Icons.edit_note_rounded), label: 'Details'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
