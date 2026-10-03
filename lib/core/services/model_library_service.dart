import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/installed_model.dart';
import 'model_validator.dart';

/// Where imported model files live (one sub-folder per model id).
typedef ModelsDirProvider = Future<Directory> Function();

/// The set of models available on the device and which one is active.
///
/// The bundled model is always present and cannot be removed. Imported model
/// files are copied into [ModelsDirProvider]'s directory so they survive the
/// file picker's temporary paths being cleaned up.
class ModelLibraryService extends ChangeNotifier {
  ModelLibraryService._(
    this._prefs,
    this._modelsDir,
    this._idGenerator,
    this._imported,
    this._activeId,
  );

  /// Loads the library, dropping entries whose file has disappeared and
  /// migrating the old single "custom model" settings once.
  static Future<ModelLibraryService> create(
    SharedPreferences prefs, {
    required ModelsDirProvider modelsDir,
    String Function()? idGenerator,
  }) async {
    final imported = <InstalledModel>[];
    final raw = prefs.getString(_keyModels);
    if (raw != null && raw.isNotEmpty) {
      try {
        for (final entry in jsonDecode(raw) as List<dynamic>) {
          final model = InstalledModel.fromJson(entry as Map<String, dynamic>);
          final path = model.filePath;
          if (path != null && File(path).existsSync()) {
            imported.add(model);
          }
        }
      } catch (e) {
        debugPrint('Failed to load model library: $e');
        imported.clear();
      }
    }

    final service = ModelLibraryService._(
      prefs,
      modelsDir,
      idGenerator ?? () => const Uuid().v4(),
      imported,
      prefs.getString(_keyActiveId) ?? InstalledModel.builtInId,
    );
    await service._migrateLegacySettings();
    if (service.byId(service._activeId) == null) {
      service._activeId = InstalledModel.builtInId;
    }
    await service._persist();
    return service;
  }

  static const String _keyModels = 'installed_models_v1';
  static const String _keyActiveId = 'active_model_id';
  static const String _keyMigrated = 'model_library_migrated_v1';

  // Keys used before the library existed (see SettingsController history).
  static const String _legacyUseCustom = 'use_custom_model';
  static const String _legacyModelPath = 'custom_model_path';
  static const String _legacyLabelsPath = 'custom_labels_path';
  static const String _legacyName = 'custom_model_name';
  static const String _legacyWidth = 'custom_model_input_width';
  static const String _legacyHeight = 'custom_model_input_height';
  static const String _legacyClasses = 'custom_model_class_count';
  static const String _legacyQuant = 'custom_model_quant_type';
  static const List<String> _legacyKeys = <String>[
    _legacyUseCustom,
    _legacyModelPath,
    _legacyLabelsPath,
    _legacyName,
    _legacyWidth,
    _legacyHeight,
    _legacyClasses,
    _legacyQuant,
    'model_id',
  ];

  final SharedPreferences _prefs;
  final ModelsDirProvider _modelsDir;
  final String Function() _idGenerator;
  final List<InstalledModel> _imported;
  String _activeId;

  /// Bundled model first, then imported models in the order they were added.
  List<InstalledModel> get models => List<InstalledModel>.unmodifiable(
    <InstalledModel>[InstalledModel.builtIn, ..._imported],
  );

  InstalledModel get activeModel => byId(_activeId) ?? InstalledModel.builtIn;

  InstalledModel? byId(String id) {
    if (id == InstalledModel.builtInId) return InstalledModel.builtIn;
    for (final m in _imported) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// First imported model that came from the marketplace entry [modelId].
  InstalledModel? byMarketplaceId(String modelId) {
    for (final m in _imported) {
      if (m.marketplaceModelId == modelId) return m;
    }
    return null;
  }

  /// Copies [sourcePath] into the library and registers it.
  ///
  /// [validation] must be a successful result from [ModelValidator.validate].
  /// Pass [labels] for a custom label list, or [usesCocoLabels] to use the
  /// bundled COCO names; with neither, generic `class_N` names are generated.
  Future<InstalledModel> installFile({
    required String sourcePath,
    required String name,
    required ModelValidationResult validation,
    List<String>? labels,
    bool usesCocoLabels = false,
    InstalledModelOrigin origin = InstalledModelOrigin.file,
    String? sourceUrl,
    String? marketplaceModelId,
    String? version,
  }) async {
    if (!validation.isValid) {
      throw ArgumentError('Cannot install a model that failed validation');
    }
    final classCount = validation.classCount!;
    if (labels != null && labels.isNotEmpty && labels.length != classCount) {
      throw ArgumentError(
        'Label count (${labels.length}) does not match model class count '
        '($classCount)',
      );
    }

    final id = _idGenerator();
    final root = await _modelsDir();
    final dir = Directory(p.join(root.path, id));
    await dir.create(recursive: true);
    final dest = File(p.join(dir.path, 'model.tflite'));
    try {
      await File(sourcePath).copy(dest.path);
    } catch (_) {
      await dir.delete(recursive: true);
      rethrow;
    }

    final hasLabels = labels != null && labels.isNotEmpty;
    final model = InstalledModel(
      id: id,
      name: name,
      origin: origin,
      filePath: dest.path,
      labels: hasLabels
          ? List<String>.unmodifiable(labels)
          : usesCocoLabels
          ? const <String>[]
          : List<String>.generate(classCount, (i) => 'class_$i'),
      usesCocoLabels: !hasLabels && usesCocoLabels,
      inputWidth: validation.inputWidth!,
      inputHeight: validation.inputHeight!,
      classCount: classCount,
      quantType: validation.inputType!,
      fileSizeBytes: await dest.length(),
      addedAt: DateTime.now().toUtc(),
      sourceUrl: sourceUrl,
      marketplaceModelId: marketplaceModelId,
      version: version,
    );

    _imported.add(model);
    await _persist();
    notifyListeners();
    return model;
  }

  Future<void> activate(String id) async {
    if (byId(id) == null || _activeId == id) return;
    _activeId = id;
    await _persist();
    notifyListeners();
  }

  Future<void> rename(String id, String name) async {
    final index = _imported.indexWhere((m) => m.id == id);
    if (index < 0) return;
    _imported[index] = _imported[index].copyWith(name: name);
    await _persist();
    notifyListeners();
  }

  /// Removes an imported model and deletes its file. The bundled model cannot
  /// be removed. If the removed model was active, the bundled one takes over.
  Future<void> remove(String id) async {
    final index = _imported.indexWhere((m) => m.id == id);
    if (index < 0) return;
    final model = _imported.removeAt(index);
    if (_activeId == id) {
      _activeId = InstalledModel.builtInId;
    }
    await _persist();
    notifyListeners();
    await _deleteFiles(model);
  }

  Future<void> _deleteFiles(InstalledModel model) async {
    final path = model.filePath;
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();

      // Remove the per-model folder when it lives in the library directory.
      final root = (await _modelsDir()).path;
      final parent = file.parent;
      if (p.equals(p.dirname(parent.path), root) &&
          await parent.exists() &&
          (await parent.list().isEmpty)) {
        await parent.delete();
      }
    } catch (e) {
      debugPrint('Failed to delete model files: $e');
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _keyModels,
      jsonEncode(_imported.map((m) => m.toJson()).toList()),
    );
    await _prefs.setString(_keyActiveId, _activeId);
  }

  /// Turns the old "one custom model" settings into a library entry.
  Future<void> _migrateLegacySettings() async {
    if (_prefs.getBool(_keyMigrated) ?? false) return;

    final path = _prefs.getString(_legacyModelPath);
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      final labelsPath = _prefs.getString(_legacyLabelsPath);
      var labels = const <String>[];
      if (labelsPath != null &&
          labelsPath.isNotEmpty &&
          File(labelsPath).existsSync()) {
        labels = (await File(labelsPath).readAsString())
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();
      }

      final model = InstalledModel(
        id: _idGenerator(),
        name: _prefs.getString(_legacyName) ?? p.basename(path),
        origin: InstalledModelOrigin.file,
        filePath: path,
        labels: labels,
        usesCocoLabels: labels.isEmpty,
        inputWidth: _prefs.getInt(_legacyWidth) ?? 640,
        inputHeight: _prefs.getInt(_legacyHeight) ?? 640,
        classCount:
            _prefs.getInt(_legacyClasses) ??
            (labels.isNotEmpty ? labels.length : 80),
        quantType: _prefs.getString(_legacyQuant) ?? 'FLOAT32',
        fileSizeBytes: File(path).lengthSync(),
        addedAt: DateTime.now().toUtc(),
      );
      _imported.add(model);
      if (_prefs.getBool(_legacyUseCustom) ?? false) {
        _activeId = model.id;
      }
    }

    for (final key in _legacyKeys) {
      await _prefs.remove(key);
    }
    await _prefs.setBool(_keyMigrated, true);
  }
}
