// Tencent TRTC UserSig generator — OFFICIAL algorithm.
//
// Based on the official GenerateTestUserSig from tencent_rtc_sdk example:
// https://trtc.io/document/35166
//
// ⚠️ UserSig MUST be generated server-side in production.
// This local implementation is acceptable for dev/testing only.

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

class UserSigService {
  static String generate({
    required int sdkAppId,
    required String secretKey,
    required String userId,
    required int expireSeconds,
  }) {
    final currTime = (DateTime.now().millisecondsSinceEpoch / 1000).floor();

    // 1. Compute HMAC-SHA256 signature from text-formatted content
    final contentToBeSigned =
        'TLS.identifier:$userId\n'
        'TLS.sdkappid:$sdkAppId\n'
        'TLS.time:$currTime\n'
        'TLS.expire:$expireSeconds\n';

    final hmac = Hmac(sha256, utf8.encode(secretKey));
    final sig = base64.encode(hmac.convert(utf8.encode(contentToBeSigned)).bytes);

    // 2. Build JSON with signature embedded
    final sigDoc = <String, dynamic>{
      'TLS.ver': '2.0',
      'TLS.identifier': userId,
      'TLS.sdkappid': sdkAppId,
      'TLS.expire': expireSeconds,
      'TLS.time': currTime,
      'TLS.sig': sig,
    };

    // 3. Compress JSON → base64 → escape
    final jsonBytes = utf8.encode(jsonEncode(sigDoc));
    final compressed = zlib.encode(jsonBytes);
    final base64Str = base64.encode(compressed);

    return base64Str
        .replaceAll('+', '*')
        .replaceAll('/', '-')
        .replaceAll('=', '_');
  }
}
