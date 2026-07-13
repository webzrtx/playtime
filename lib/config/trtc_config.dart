// Tencent TRTC Configuration
// In production, move secretKey to a backend service for UserSig generation.

class TRTCConfig {
  /// SDK App ID from TRTC Console
  static const int sdkAppId = 20044652;

  /// Secret Key for UserSig generation
  /// TODO: use backend service instead of embedding in client
  static const String secretKey = '971dd4f906087a876b1f6e179022a7b4549bb9ccab4bc1b4e31e48aea6bf47c0';

  /// Default room ID for dev/testing
  static const int defaultRoomId = 12345;

  /// UserSig expiry: 7 days (max recommended for client-side generation)
  static const int userSigExpireSeconds = 86400 * 7;

  /// Returns configured or throws if placeholder
  static bool get isConfigured => secretKey != 'YOUR_SECRET_KEY';
}
