// Tencent TRTC Configuration
// In production, move secretKey to a backend service for UserSig generation.

class TRTCConfig {
  /// SDK App ID from TRTC Console
  static const int sdkAppId = 20044652;

  /// Secret Key for UserSig generation
  /// TODO: use backend service instead of embedding in client
  static const String secretKey = '582fcb6574d81dc547c5f583e06765a93b7db00fd32c15e709ea9e42f05c4b1c';

  /// Default room ID for dev/testing
  static const int defaultRoomId = 12345;

  /// UserSig expiry: 7 days (max recommended for client-side generation)
  static const int userSigExpireSeconds = 86400 * 7;

  /// Returns configured or throws if placeholder
  static bool get isConfigured => secretKey != 'YOUR_SECRET_KEY';
}
