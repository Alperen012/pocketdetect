import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

enum ModelPackageError { notAZip, noModelFile }

class ModelPackageException implements Exception {
  const ModelPackageException(this.error);

  final ModelPackageError error;

  @override
  String toString() => 'ModelPackageException(${error.name})';
}

/// Files pulled out of a model `.zip`.
class ModelPackage {
  const ModelPackage({required this.modelPath, this.labelsPath});

  final String modelPath;

  /// Path of the extracted label list, when the package had one.
  final String? labelsPath;
}

/// Extracts the `.tflite` model and, if present, a label list from the zip at
/// [zipPath] into [outDir].
///
/// Output files are always named `model.tflite` / `labels.txt` inside
/// [outDir], never after the archive entry, so a hostile entry name such as
/// `../x` cannot write outside it.
///
/// A label file is chosen by name (`labels.txt`, `classes.txt`, `names.txt`),
/// or else the only `.txt` file in the package.
Future<ModelPackage> extractModelPackage(
  String zipPath,
  Directory outDir,
) async {
  final input = InputFileStream(zipPath);
  try {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeStream(input);
    } catch (_) {
      throw const ModelPackageException(ModelPackageError.notAZip);
    }

    // The decoder does not throw on arbitrary bytes; it yields no entries.
    if (archive.files.isEmpty) {
      throw const ModelPackageException(ModelPackageError.notAZip);
    }

    final files = archive.files.where(_isUsable).toList();

    final models =
        files.where((f) => _base(f).endsWith('.tflite')).toList();
    if (models.isEmpty) {
      throw const ModelPackageException(ModelPackageError.noModelFile);
    }
    // Several models: take the largest, the most likely to be the real one.
    models.sort((a, b) => b.size.compareTo(a.size));

    final labelFile = _pickLabelFile(files);

    await outDir.create(recursive: true);
    final modelDest = p.join(outDir.path, 'model.tflite');
    await _writeEntry(models.first, modelDest);

    String? labelsDest;
    if (labelFile != null) {
      labelsDest = p.join(outDir.path, 'labels.txt');
      await _writeEntry(labelFile, labelsDest);
    }

    return ModelPackage(modelPath: modelDest, labelsPath: labelsDest);
  } finally {
    await input.close();
  }
}

bool _isUsable(ArchiveFile f) {
  if (!f.isFile) return false;
  final name = f.name.replaceAll('\\', '/');
  // macOS resource forks and hidden files.
  return !name.startsWith('__MACOSX/') && !_base(f).startsWith('.');
}

String _base(ArchiveFile f) =>
    f.name.replaceAll('\\', '/').split('/').last.toLowerCase();

ArchiveFile? _pickLabelFile(List<ArchiveFile> files) {
  final texts = files.where((f) => _base(f).endsWith('.txt')).toList();
  const preferred = <String>['labels.txt', 'classes.txt', 'names.txt'];
  for (final name in preferred) {
    for (final f in texts) {
      if (_base(f) == name) return f;
    }
  }
  return texts.length == 1 ? texts.first : null;
}

Future<void> _writeEntry(ArchiveFile entry, String destPath) async {
  final output = OutputFileStream(destPath);
  try {
    entry.writeContent(output);
  } finally {
    await output.close();
  }
}
