import 'package:camera/camera.dart';

/// True when [error] is the camera plugin reporting that camera access was
/// denied or restricted (`CameraAccessDenied`, `CameraAccessDeniedWithoutPrompt`,
/// `CameraAccessRestricted`). Retrying cannot fix these; the user has to change
/// a system setting.
bool isCameraPermissionError(Object? error) {
  return error is CameraException && error.code.startsWith('CameraAccess');
}
