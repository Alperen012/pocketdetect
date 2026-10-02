import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Result of validating a TFLite model file before importing.
@immutable
class ModelValidationResult {
  const ModelValidationResult._({
    required this.isValid,
    this.inputWidth,
    this.inputHeight,
    this.inputType,
    this.outputShape,
    this.classCount,
    this.errorCode,
  });

  /// A valid model.
  const ModelValidationResult.success({
    required int inputWidth,
    required int inputHeight,
    required String inputType,
    required List<int> outputShape,
    required int classCount,
  }) : this._(
          isValid: true,
          inputWidth: inputWidth,
          inputHeight: inputHeight,
          inputType: inputType,
          outputShape: outputShape,
          classCount: classCount,
        );

  /// An invalid model.
  const ModelValidationResult.failure(ModelValidationError code)
      : this._(isValid: false, errorCode: code);

  final bool isValid;
  final int? inputWidth;
  final int? inputHeight;
  final String? inputType;
  final List<int>? outputShape;
  final int? classCount;
  final ModelValidationError? errorCode;
}

/// Error codes for user-friendly, localizable messages.
enum ModelValidationError {
  fileNotFound,
  notValidTflite,
  unsupportedInputShape,
  unsupportedInputType,
  unsupportedOutputShape,
  unsupportedOutputType,
}

/// Validates a `.tflite` model file for YOLO-compatible tensor layout.
///
/// Opens the model with CPU-only interpreter, inspects tensor shapes/types,
/// and closes immediately. No inference is run.
class ModelValidator {
  const ModelValidator._();

  /// Validate the model at [path]. Returns a [ModelValidationResult].
  static Future<ModelValidationResult> validate(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return const ModelValidationResult.failure(
        ModelValidationError.fileNotFound,
      );
    }

    Interpreter? interpreter;
    try {
      interpreter = Interpreter.fromFile(file);

      final input = interpreter.getInputTensor(0);
      final output = interpreter.getOutputTensor(0);

      // Input: [1, H, W, 3]
      final inputShape = input.shape;
      if (inputShape.length != 4 ||
          inputShape[0] != 1 ||
          inputShape[3] != 3) {
        return const ModelValidationResult.failure(
          ModelValidationError.unsupportedInputShape,
        );
      }

      if (input.type != TensorType.int8 &&
          input.type != TensorType.float32) {
        return const ModelValidationResult.failure(
          ModelValidationError.unsupportedInputType,
        );
      }

      // Output: [1, C, N]  where C = 4 + num_classes
      final outputShape = output.shape;
      if (outputShape.length != 3 ||
          outputShape[0] != 1 ||
          outputShape[1] < 5) {
        return const ModelValidationResult.failure(
          ModelValidationError.unsupportedOutputShape,
        );
      }

      if (output.type != TensorType.int8 &&
          output.type != TensorType.float32) {
        return const ModelValidationResult.failure(
          ModelValidationError.unsupportedOutputType,
        );
      }

      final quantLabel =
          input.type == TensorType.int8 ? 'INT8' : 'FLOAT32';
      final classCount = outputShape[1] - 4;

      return ModelValidationResult.success(
        inputWidth: inputShape[2],
        inputHeight: inputShape[1],
        inputType: quantLabel,
        outputShape: List<int>.unmodifiable(outputShape),
        classCount: classCount,
      );
    } catch (_) {
      return const ModelValidationResult.failure(
        ModelValidationError.notValidTflite,
      );
    } finally {
      interpreter?.close();
    }
  }

  /// Validate that a labels `.txt` file has the expected [expectedCount] lines.
  static Future<LabelValidationResult> validateLabels(
    String path, {
    required int expectedCount,
  }) async {
    final file = File(path);
    if (!await file.exists()) {
      return const LabelValidationResult(
        isValid: false,
        labelCount: 0,
        errorCode: LabelValidationError.fileNotFound,
      );
    }

    try {
      final raw = await file.readAsString();
      final labels = raw
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      if (labels.length != expectedCount) {
        return LabelValidationResult(
          isValid: false,
          labelCount: labels.length,
          errorCode: LabelValidationError.countMismatch,
        );
      }

      return LabelValidationResult(
        isValid: true,
        labelCount: labels.length,
        labels: labels,
      );
    } catch (_) {
      return const LabelValidationResult(
        isValid: false,
        labelCount: 0,
        errorCode: LabelValidationError.readError,
      );
    }
  }
}

@immutable
class LabelValidationResult {
  const LabelValidationResult({
    required this.isValid,
    required this.labelCount,
    this.labels,
    this.errorCode,
  });

  final bool isValid;
  final int labelCount;
  final List<String>? labels;
  final LabelValidationError? errorCode;
}

enum LabelValidationError {
  fileNotFound,
  countMismatch,
  readError,
}
