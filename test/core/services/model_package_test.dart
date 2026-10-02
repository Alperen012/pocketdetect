import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:mobile_yolo/core/services/model_package.dart';

void main() {
  late Directory tmp;
  late Directory out;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('model_package_test');
    out = Directory(p.join(tmp.path, 'out'));
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  String writeZip(Map<String, List<int>> entries, {String name = 'pkg.zip'}) {
    final archive = Archive();
    entries.forEach((entryName, bytes) {
      archive.addFile(ArchiveFile(entryName, bytes.length, bytes));
    });
    final path = p.join(tmp.path, name);
    File(path).writeAsBytesSync(ZipEncoder().encode(archive));
    return path;
  }

  List<int> text(String s) => utf8.encode(s);

  group('extractModelPackage', () {
    test('extracts the model and labels.txt', () async {
      final zip = writeZip(<String, List<int>>{
        'helmets/best.tflite': <int>[1, 2, 3, 4],
        'helmets/labels.txt': text('helmet\nvest\n'),
        'helmets/README.md': text('hi'),
      });

      final pkg = await extractModelPackage(zip, out);

      expect(File(pkg.modelPath).readAsBytesSync(), <int>[1, 2, 3, 4]);
      expect(p.basename(pkg.modelPath), 'model.tflite');
      expect(File(pkg.labelsPath!).readAsStringSync(), 'helmet\nvest\n');
    });

    test('labels are optional', () async {
      final zip = writeZip(<String, List<int>>{
        'm.tflite': <int>[9],
      });

      final pkg = await extractModelPackage(zip, out);

      expect(pkg.labelsPath, isNull);
    });

    test('prefers labels.txt over other text files', () async {
      final zip = writeZip(<String, List<int>>{
        'm.tflite': <int>[9],
        'notes.txt': text('not labels'),
        'labels.txt': text('a\nb\n'),
      });

      final pkg = await extractModelPackage(zip, out);

      expect(File(pkg.labelsPath!).readAsStringSync(), 'a\nb\n');
    });

    test('uses a lone text file as labels', () async {
      final zip = writeZip(<String, List<int>>{
        'm.tflite': <int>[9],
        'my_classes_list.txt': text('x\ny\n'),
      });

      final pkg = await extractModelPackage(zip, out);

      expect(File(pkg.labelsPath!).readAsStringSync(), 'x\ny\n');
    });

    test('does not guess among several unnamed text files', () async {
      final zip = writeZip(<String, List<int>>{
        'm.tflite': <int>[9],
        'a.txt': text('1'),
        'b.txt': text('2'),
      });

      final pkg = await extractModelPackage(zip, out);

      expect(pkg.labelsPath, isNull);
    });

    test('takes the largest model when there are several', () async {
      final zip = writeZip(<String, List<int>>{
        'small.tflite': <int>[1],
        'big.tflite': <int>[1, 2, 3, 4, 5, 6],
      });

      final pkg = await extractModelPackage(zip, out);

      expect(File(pkg.modelPath).lengthSync(), 6);
    });

    test('ignores macOS resource forks and hidden files', () async {
      final zip = writeZip(<String, List<int>>{
        '__MACOSX/._m.tflite': <int>[7, 7, 7, 7, 7, 7, 7, 7],
        '._hidden.tflite': <int>[7, 7],
        'm.tflite': <int>[1],
      });

      final pkg = await extractModelPackage(zip, out);

      expect(File(pkg.modelPath).readAsBytesSync(), <int>[1]);
    });

    test('a path-traversal entry name cannot escape the output folder',
        () async {
      final zip = writeZip(<String, List<int>>{
        '../../evil.tflite': <int>[1, 2],
      });

      final pkg = await extractModelPackage(zip, out);

      expect(p.isWithin(out.path, pkg.modelPath), isTrue);
      expect(File(p.join(tmp.path, 'evil.tflite')).existsSync(), isFalse);
    });

    test('a zip without a model is rejected', () async {
      final zip = writeZip(<String, List<int>>{
        'labels.txt': text('a'),
      });

      await expectLater(
        extractModelPackage(zip, out),
        throwsA(isA<ModelPackageException>().having(
          (e) => e.error,
          'error',
          ModelPackageError.noModelFile,
        )),
      );
    });

    test('a file that is not a zip is rejected', () async {
      final path = p.join(tmp.path, 'fake.zip');
      File(path).writeAsStringSync('this is not a zip');

      await expectLater(
        extractModelPackage(path, out),
        throwsA(isA<ModelPackageException>().having(
          (e) => e.error,
          'error',
          ModelPackageError.notAZip,
        )),
      );
    });
  });
}
