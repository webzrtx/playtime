// Tencent TRTC UserSig generator (TLSSigAPIv2).
//
// Implements HMAC-SHA256 signing per:
// https://trtc.io/document/35166
//
// ⚠️ UserSig MUST be generated server-side in production.
// This local implementation is acceptable for dev/testing only.

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

class UserSigService {
  /// Generate a UserSig for the given userId.
  ///
  /// [sdkAppId] — TRTC application ID
  /// [secretKey] — application secret key
  /// [userId] — the user's unique identifier
  /// [expireSeconds] — how long the signature is valid
  static String generate({
    required int sdkAppId,
    required String secretKey,
    required String userId,
    required int expireSeconds,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final payload = <String, dynamic>{
      'TLS.ver': '2.0',
      'TLS.identifier': userId,
      'TLS.sdkappid': sdkAppId,
      'TLS.expire': expireSeconds,
      'TLS.time': now,
    };

    final jsonBytes = utf8.encode(jsonEncode(payload));
    final compressed = zlib.encode(jsonBytes);
    final encoded = _base64UrlEncode(compressed);

    final hmacSig = Hmac(sha256, utf8.encode(secretKey))
        .convert(utf8.encode(encoded));
    final sig = _base64UrlEncode(hmacSig.bytes);

    return '$encoded.$sig';
  }

  static String _base64UrlEncode(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
