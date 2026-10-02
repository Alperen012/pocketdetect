import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/category_group.dart';
import '../models/resolution_profile.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs) {
    _settings = _loadSettings();
    _selectedLabels = _loadSelectedLabels();
  }

  final SharedPreferences _prefs;
  late AppSettings _settings;
  late Set<String> _selectedLabels;

  static const String _keyResolution = 'resolution_profile';
  static const String _keyModelId = 'model_id';
  static const String _keyConfidence = 'confidence_threshold';
  static const String _keyIou = 'iou_threshold';
  static const String _keyUseNms = 'use_nms';
  static const String _keyMaxDetections = 'max_detections';
  static const String _keyLowMemoryWarningSeen = 'low_memory_warning_seen';
  static const String _keySelectedLabels = 'selected_labels';
  static const String _keyUseCustomModel = 'use_custom_model';
  static const String _keyCustomModelPath = 'custom_model_path';
  static const String _keyCustomLabelsPath = 'custom_labels_path';
  static const String _keyCustomModelName = 'custom_model_name';
  static const String _keyCustomModelInputWidth = 'custom_model_input_width';
  static const String _keyCustomModelInputHeight = 'custom_model_input_height';
  static const String _keyCustomModelClassCount = 'custom_model_class_count';
  static const String _keyCustomModelQuantType = 'custom_model_quant_type';

  AppSettings get settings => _settings;
  Set<String> get selectedLabels => _selectedLabels;

  bool get isAllSelected => _selectedLabels.length == _allLabels.length;

  void toggleLabel(String label) {
    final updated = Set<String>.from(_selectedLabels);
    if (updated.contains(label)) {
      updated.remove(label);
    } else {
      updated.add(label);
    }
    _selectedLabels = updated;
    _prefs.setStringList(_keySelectedLabels, _selectedLabels.toList());
    notifyListeners();
  }

  void setGroupSelection(CategoryGroup group, bool selected) {
    final updated = Set<String>.from(_selectedLabels);
    if (selected) {
      updated.addAll(group.items);
    } else {
      updated.removeAll(group.items);
    }
    _selectedLabels = updated;
    _prefs.setStringList(_keySelectedLabels, _selectedLabels.toList());
    notifyListeners();
  }

  bool isGroupSelected(CategoryGroup group) {
    return group.items.every(_selectedLabels.contains);
  }

  bool isGroupPartiallySelected(CategoryGroup group) {
    final selectedCount = group.items.where(_selectedLabels.contains).length;
    return selectedCount > 0 && selectedCount < group.items.length;
  }

  void updateResolution(ResolutionProfile profile) {
    _settings = _settings.copyWith(resolutionProfile: profile);
    _prefs.setString(_keyResolution, profile.id);
    notifyListeners();
  }

  void updateModelId(String modelId) {
    _settings = _settings.copyWith(modelId: modelId);
    _prefs.setString(_keyModelId, modelId);
    notifyListeners();
  }

  void updateUseCustomModel(bool value) {
    _settings = _settings.copyWith(useCustomModel: value);
    _prefs.setBool(_keyUseCustomModel, value);
    notifyListeners();
  }

  void updateCustomModelPath(String? path) {
    _settings = _settings.copyWith(
      customModelPath: path,
      clearCustomModelPath: path == null || path.isEmpty,
    );
    if (path == null || path.isEmpty) {
      _prefs.remove(_keyCustomModelPath);
    } else {
      _prefs.setString(_keyCustomModelPath, path);
    }
    notifyListeners();
  }

  void updateCustomLabelsPath(String? path) {
    _settings = _settings.copyWith(
      customLabelsPath: path,
      clearCustomLabelsPath: path == null || path.isEmpty,
    );
    if (path == null || path.isEmpty) {
      _prefs.remove(_keyCustomLabelsPath);
    } else {
      _prefs.setString(_keyCustomLabelsPath, path);
    }
    notifyListeners();
  }

  void updateCustomModelMetadata({
    String? name,
    int? inputWidth,
    int? inputHeight,
    int? classCount,
    String? quantType,
  }) {
    _settings = _settings.copyWith(
      customModelName: name,
      customModelInputWidth: inputWidth,
      customModelInputHeight: inputHeight,
      customModelClassCount: classCount,
      customModelQuantType: quantType,
    );
    if (name != null) _prefs.setString(_keyCustomModelName, name);
    if (inputWidth != null) _prefs.setInt(_keyCustomModelInputWidth, inputWidth);
    if (inputHeight != null) _prefs.setInt(_keyCustomModelInputHeight, inputHeight);
    if (classCount != null) _prefs.setInt(_keyCustomModelClassCount, classCount);
    if (quantType != null) _prefs.setString(_keyCustomModelQuantType, quantType);
    notifyListeners();
  }

  void clearCustomModelMetadata() {
    _settings = _settings.copyWith(
      clearCustomModelName: true,
      clearCustomModelInputWidth: true,
      clearCustomModelInputHeight: true,
      clearCustomModelClassCount: true,
      clearCustomModelQuantType: true,
    );
    _prefs.remove(_keyCustomModelName);
    _prefs.remove(_keyCustomModelInputWidth);
    _prefs.remove(_keyCustomModelInputHeight);
    _prefs.remove(_keyCustomModelClassCount);
    _prefs.remove(_keyCustomModelQuantType);
    notifyListeners();
  }

  void updateConfidence(double value) {
    _settings = _settings.copyWith(confidenceThreshold: value);
    _prefs.setDouble(_keyConfidence, value);
    notifyListeners();
  }

  void updateIou(double value) {
    _settings = _settings.copyWith(iouThreshold: value);
    _prefs.setDouble(_keyIou, value);
    notifyListeners();
  }

  void updateUseNms(bool value) {
    _settings = _settings.copyWith(useNms: value);
    _prefs.setBool(_keyUseNms, value);
    notifyListeners();
  }

  void updateMaxDetections(int value) {
    _settings = _settings.copyWith(maxDetections: value);
    _prefs.setInt(_keyMaxDetections, value);
    notifyListeners();
  }

  void markLowMemoryWarningSeen() {
    if (_settings.lowMemoryWarningSeen) {
      return;
    }
    _settings = _settings.copyWith(lowMemoryWarningSeen: true);
    _prefs.setBool(_keyLowMemoryWarningSeen, true);
    notifyListeners();
  }

  void resetToDefaults() {
    _settings = AppSettings.defaults;
    _selectedLabels = _allLabels.toSet();
    _prefs.setString(_keyModelId, _settings.modelId);
    _prefs.setBool(_keyUseCustomModel, _settings.useCustomModel);
    _prefs.remove(_keyCustomModelPath);
    _prefs.remove(_keyCustomLabelsPath);
    _prefs.remove(_keyCustomModelName);
    _prefs.remove(_keyCustomModelInputWidth);
    _prefs.remove(_keyCustomModelInputHeight);
    _prefs.remove(_keyCustomModelClassCount);
    _prefs.remove(_keyCustomModelQuantType);
    _prefs.setString(_keyResolution, _settings.resolutionProfile.id);
    _prefs.setDouble(_keyConfidence, _settings.confidenceThreshold);
    _prefs.setDouble(_keyIou, _settings.iouThreshold);
    _prefs.setBool(_keyUseNms, _settings.useNms);
    _prefs.setInt(_keyMaxDetections, _settings.maxDetections);
    _prefs.setStringList(_keySelectedLabels, _selectedLabels.toList());
    _prefs.setBool(_keyLowMemoryWarningSeen, _settings.lowMemoryWarningSeen);
    notifyListeners();
  }

  AppSettings _loadSettings() {
    final resolutionId = _prefs.getString(_keyResolution);
    return AppSettings.defaults.copyWith(
      modelId: _prefs.getString(_keyModelId) ?? AppSettings.defaults.modelId,
      useCustomModel:
        _prefs.getBool(_keyUseCustomModel) ?? AppSettings.defaults.useCustomModel,
      customModelPath: _prefs.getString(_keyCustomModelPath),
      customLabelsPath: _prefs.getString(_keyCustomLabelsPath),
      customModelName: _prefs.getString(_keyCustomModelName),
      customModelInputWidth: _prefs.getInt(_keyCustomModelInputWidth),
      customModelInputHeight: _prefs.getInt(_keyCustomModelInputHeight),
      customModelClassCount: _prefs.getInt(_keyCustomModelClassCount),
      customModelQuantType: _prefs.getString(_keyCustomModelQuantType),
      resolutionProfile: ResolutionProfile.fromId(resolutionId),
      confidenceThreshold:
          _prefs.getDouble(_keyConfidence) ?? AppSettings.defaults.confidenceThreshold,
      iouThreshold: _prefs.getDouble(_keyIou) ?? AppSettings.defaults.iouThreshold,
      useNms: _prefs.getBool(_keyUseNms) ?? AppSettings.defaults.useNms,
      maxDetections:
          _prefs.getInt(_keyMaxDetections) ?? AppSettings.defaults.maxDetections,
      lowMemoryWarningSeen: _prefs.getBool(_keyLowMemoryWarningSeen) ?? false,
    );
  }

  Set<String> _loadSelectedLabels() {
    final stored = _prefs.getStringList(_keySelectedLabels);
    if (stored == null || stored.isEmpty) {
      return _allLabels.toSet();
    }
    return stored.toSet();
  }
}

final List<String> _allLabels = List<String>.unmodifiable(
  cocoGroups.expand((group) => group.items).toSet().toList()..sort(),
);
