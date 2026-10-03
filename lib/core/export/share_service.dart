import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Hands text and files to the system share sheet. Subclass to intercept
/// exports in tests.
class ShareService {
  const ShareService();

  Future<void> shareText(String text, {String? subject}) async {
    await Share.share(text, subject: subject);
  }

  /// Writes [bytes] to a temporary file named [fileName] and shares it.
  Future<void> shareBytes(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
    String? subject,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, _safeName(fileName)));
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(<XFile>[
      XFile(file.path, mimeType: mimeType),
    ], subject: subject);
  }

  /// Keeps only characters that are safe in a file name on every platform.
  static String _safeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return cleaned.isEmpty ? 'export' : cleaned;
  }
}
