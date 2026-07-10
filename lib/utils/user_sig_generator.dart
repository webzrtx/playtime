import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Generate Tencent TRTC UserSig locally
/// NOTE: For production, generate this on your server!
class UserSigGenerator {
  static String generate({
    required int sdkAppId,
    required String secretKey,
    required String userId,
    int expireSeconds = 3600,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expire = now + expireSeconds;

    final payload = {
      'sdk_app_id': sdkAppId,
      'room_id': 0, // Not used in basic sig
      'identifier': userId,
      'time': now,
      'expire_time': expire,
      'base_string': 'identifier=$userId&sdk_app_id=$sdkAppId&time=$now&expire_time=$expire',
    };

    // Generate signature using HMAC-SHA256
    final key = utf8.encode(secretKey);
    final message = utf8.encode(payload['base_string'] as String);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(message);
    final signature = base64.encode(digest.bytes);

    // Create final UserSig
    final sigJson = {
      'sig': signature,
      'expire_time': expire,
      'sdk_app_id': sdkAppId,
    };

    return base64.encode(utf8.encode(jsonEncode(sigJson)));
  }
}