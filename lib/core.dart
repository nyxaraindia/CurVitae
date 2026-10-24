import 'package:flutter/material.dart';

/// App-wide constants. Keys stay on the frontend by design (business decision).
class AppConfig {
  AppConfig._();

  static const String appName = 'CurVitae';
  static const String aiName = 'Nyxara AI';

  // ignore: constant_identifier_names
  static const String geminiApiKey = 'AIzaSyAVqM2VezyjQmv817CXAgxWkVKesfeujCg';

  static const String curvitaeLogo = 'assets/curvitae_logo.png';
  static const String nyxaraLogo = 'assets/logo.png';

  /// Bluish brand seed, used when Dynamic Color (Material You) is unavailable.
  static const Color brandSeed = Color(0xFF1565C0);

  /// Set to false to force the bluish brand palette on every device.
  static const bool useDynamicColor = true;

  /// Background of the CurVitae logo artwork (paper white).
  static const Color logoPaper = Color(0xFFF7F7F3);
}

/// Signed-in user's editable profile.
class UserProfile {
  UserProfile._();

  static String name = 'Guest';
  static String title = '';
  static String email = '';
  static String phone = '';
  static String location = '';
  static String link = '';

  static bool get hasName => name.trim().isNotEmpty && name != 'Guest';
}

/// Global "Nyxara AI is working" state. A non-null status shows the full-screen
/// Nyxara loading overlay inside the app shell.
class AiBusy {
  AiBusy._();

  static final ValueNotifier<String?> status = ValueNotifier<String?>(null);

  static bool get isBusy => status.value != null;
  static void start(String message) => status.value = message;
  static void update(String message) {
    if (status.value != null) status.value = message;
  }

  static void stop() => status.value = null;
}

/// Accent styles available for the generated CV.
enum CvStyle {
  ocean('Ocean Blue', Color(0xFF1565C0)),
  teal('Teal', Color(0xFF00796B)),
  indigo('Indigo', Color(0xFF3949AB)),
  slate('Slate', Color(0xFF37474F));

  const CvStyle(this.label, this.color);
  final String label;
  final Color color;
}

const List<String> kTones = ['Professional', 'Confident', 'Creative'];
