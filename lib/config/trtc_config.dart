// Tencent TRTC Configuration
// In production, move secretKey to a backend service for UserSig generation.

class TRTCConfig {
  /// SDK App ID from TRTC Console
  static const int sdkAppId = 20044652;

  /// Secret Key for UserSig generation
  /// TODO: use backend service instead of embedding in client
  static const String secretKey = 'YOUR_SECRET_KEY';

  /// Default room ID for dev/testing
  static const int defaultRoomId = 12345;

  /// UserSig expiry: 180 days (dev), 24h (prod)
  static const int userSigExpireSeconds = 86400 * 180;

  /// Returns configured or throws if placeholder
  static bool get isConfigured => secretKey != 'YOUR_SECRET_KEY';
}
