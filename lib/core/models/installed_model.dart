import 'package:flutter/foundation.dart';

/// How a model got onto the device.
enum InstalledModelOrigin { builtIn, file, url, marketplace }

/// A model the user can run: the bundled one or any imported `.tflite`.
///
/// Labels are resolved as follows: a non-empty [labels] list wins; otherwise
/// the bundled COCO label file is used ([usesCocoLabels]).
@immutable
class InstalledModel {
  const InstalledModel({
    required this.id,
    required this.name,
    required this.origin,
    required this.inputWidth,
    required this.inputHeight,
    required this.classCount,
    required this.quantType,
    required this.addedAt,
    this.filePath,
    this.assetPath,
    this.labels = const <String>[],
    this.usesCocoLabels = false,
    this.fileSizeBytes = 0,
    this.sourceUrl,
    this.marketplaceModelId,
    this.version,
  }) : assert(
         (filePath == null) != (assetPath == null),
         'Exactly one of filePath / assetPath must be set',
       );

  /// Id of the bundled model; always present in the library.
  static const String builtInId = 'builtin';

  static const String builtInAssetPath = 'assets/models/yolo26n_int8.tflite';

  static final InstalledModel builtIn = InstalledModel(
    id: builtInId,
    name: 'YOLO26 Nano (INT8)',
    origin: InstalledModelOrigin.builtIn,
    assetPath: builtInAssetPath,
    inputWidth: 832,
    inputHeight: 832,
    classCount: 80,
    quantType: 'INT8',
    usesCocoLabels: true,
    addedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  final String id;
  final String name;
  final InstalledModelOrigin origin;

  /// Path of the `.tflite` file for imported models; null for the bundled one.
  final String? filePath;

  /// Flutter asset path for the bundled model; null for imported ones.
  final String? assetPath;

  final List<String> labels;
  final bool usesCocoLabels;
  final int inputWidth;
  final int inputHeight;
  final int classCount;
  final String quantType;
  final int fileSizeBytes;
  final DateTime addedAt;
  final String? sourceUrl;
  final String? marketplaceModelId;
  final String? version;

  bool get isBuiltIn => origin == InstalledModelOrigin.builtIn;

  /// The class-selection filter in preferences is built from COCO names, so it
  /// only applies when the model's classes are COCO's.
  bool get supportsLabelFilter => usesCocoLabels;

  InstalledModel copyWith({String? name}) {
    return InstalledModel(
      id: id,
      name: name ?? this.name,
      origin: origin,
      filePath: filePath,
      assetPath: assetPath,
      labels: labels,
      usesCocoLabels: usesCocoLabels,
      inputWidth: inputWidth,
      inputHeight: inputHeight,
      classCount: classCount,
      quantType: quantType,
      fileSizeBytes: fileSizeBytes,
      addedAt: addedAt,
      sourceUrl: sourceUrl,
      marketplaceModelId: marketplaceModelId,
      version: version,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'origin': origin.name,
    'filePath': filePath,
    'assetPath': assetPath,
    'labels': labels,
    'usesCocoLabels': usesCocoLabels,
    'inputWidth': inputWidth,
    'inputHeight': inputHeight,
    'classCount': classCount,
    'quantType': quantType,
    'fileSizeBytes': fileSizeBytes,
    'addedAt': addedAt.toUtc().toIso8601String(),
    'sourceUrl': sourceUrl,
    'marketplaceModelId': marketplaceModelId,
    'version': version,
  };

  factory InstalledModel.fromJson(Map<String, dynamic> json) {
    final originName = json['origin'] as String?;
    return InstalledModel(
      id: json['id'] as String,
      name: json['name'] as String,
      origin: InstalledModelOrigin.values.firstWhere(
        (o) => o.name == originName,
        orElse: () => InstalledModelOrigin.file,
      ),
      filePath: json['filePath'] as String?,
      assetPath: json['assetPath'] as String?,
      labels: (json['labels'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e as String)
          .toList(growable: false),
      usesCocoLabels: json['usesCocoLabels'] as bool? ?? false,
      inputWidth: (json['inputWidth'] as num).toInt(),
      inputHeight: (json['inputHeight'] as num).toInt(),
      classCount: (json['classCount'] as num).toInt(),
      quantType: json['quantType'] as String? ?? 'FLOAT32',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      addedAt: DateTime.parse(json['addedAt'] as String),
      sourceUrl: json['sourceUrl'] as String?,
      marketplaceModelId: json['marketplaceModelId'] as String?,
      version: json['version'] as String?,
    );
  }
}
