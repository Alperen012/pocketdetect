import 'dart:io';

import 'package:flutter/services.dart';

class DeviceCapabilities {
  const DeviceCapabilities();

  static const MethodChannel _channel = MethodChannel('mobile_yolo/device');

  Future<bool> isLowRamDevice() async {
    if (!Platform.isAndroid) {
      return false;
    }
    try {
      final result = await _channel.invokeMethod<bool>('isLowRamDevice');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
