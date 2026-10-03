import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Texts for the crash screen. It is built by `ErrorWidget.builder`, which has
/// no `BuildContext` and so no `AppLocalizations`; the language comes from the
/// device instead.
@immutable
class CrashMessages {
  const CrashMessages({required this.title, required this.restartHint});

  final String title;
  final String restartHint;

  static const CrashMessages english = CrashMessages(
    title: 'Oops! Something went wrong.',
    restartHint: 'Please restart the app.',
  );

  static const CrashMessages turkish = CrashMessages(
    title: 'Hay aksi! Bir şeyler ters gitti.',
    restartHint: 'Lütfen uygulamayı yeniden başlatın.',
  );

  /// Turkish for `tr`, English for everything else.
  static CrashMessages forLanguage(String languageCode) =>
      languageCode == 'tr' ? turkish : english;
}

/// Friendly replacement for the red error widget. Shows the exception only in
/// debug builds.
Widget buildCrashScreen(
  FlutterErrorDetails details, {
  required String language,
}) {
  final messages = CrashMessages.forLanguage(language);
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                messages.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                kDebugMode
                    ? details.exception.toString()
                    : messages.restartHint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
