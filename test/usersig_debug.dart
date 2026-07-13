import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

String _base64UrlEncode(List<int> bytes) {
  return base64Url.encode(bytes).replaceAll('=', '');
}

void main() {
  final sdkAppId = 20044652;
  final secretKey = '582fcb6574d81dc547c5f583e06765a93b7db00fd32c15e709ea9e42f05c4b1c';
  final userId = 'test_user';
  final expireSeconds = 86400 * 7; // 7 days
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  final payload = <String, dynamic>{
    'TLS.ver': '2.0',
    'TLS.identifier': userId,
    'TLS.sdkappid': sdkAppId,
    'TLS.expire': expireSeconds,
    'TLS.time': now,
  };

  final jsonStr = jsonEncode(payload);
  print('JSON: $jsonStr');
  
  final jsonBytes = utf8.encode(jsonStr);
  print('JSON bytes length: ${jsonBytes.length}');
  
  final compressed = zlib.encode(jsonBytes);
  print('Compressed length: ${compressed.length}');
  print('Compressed (hex first 20): ${compressed.take(20).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
  
  final encoded = _base64UrlEncode(compressed);
  print('Base64URL: ${encoded.substring(0, 50)}...');
  
  final hmacSig = Hmac(sha256, utf8.encode(secretKey)).convert(utf8.encode(encoded));
  print('HMAC (hex): ${hmacSig.bytes.take(16).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}...');
  
  final sig = _base64UrlEncode(hmacSig.bytes);
  final userSig = '$encoded.$sig';
  
  print('UserSig length: ${userSig.length}');
  print('UserSig (first 80): ${userSig.substring(0, 80)}...');
  
  // Also try with minimal duration
  print('\n--- With 86400s ---');
  final payload2 = <String, dynamic>{
    'TLS.ver': '2.0',
    'TLS.identifier': userId,
    'TLS.sdkappid': sdkAppId,
    'TLS.expire': 86400,
    'TLS.time': now,
  };
  final encoded2 = _base64UrlEncode(zlib.encode(utf8.encode(jsonEncode(payload2))));
  final sig2 = _base64UrlEncode(Hmac(sha256, utf8.encode(secretKey)).convert(utf8.encode(encoded2)).bytes);
  print('86400s UserSig (first 80): ${encoded2.substring(0, 40)}...${sig2.substring(0, 20)}...');
}
