import 'package:flutter/services.dart';

/// Android Picture-in-Picture service.
class PipService {
  static const _channel = MethodChannel('com.myapp.weplay_clone/pip');

  /// Enter Picture-in-Picture mode. Returns true if successful.
  static Future<bool> enterPip() async {
    try {
      final result = await _channel.invokeMethod<bool>('enterPip');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Check if currently in PiP mode.
  static Future<bool> isInPip() async {
    try {
      final result = await _channel.invokeMethod<bool>('isInPip');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
