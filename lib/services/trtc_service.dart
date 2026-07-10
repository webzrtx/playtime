import 'package:tencent_rtc_sdk/trtc_cloud.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_def.dart';

/// Tencent TRTC Service for real voice chat
class TRTCService {
  static final TRTCService _instance = TRTCService._internal();
  factory TRTCService() => _instance;
  TRTCService._internal();

  TRTCCloud? _cloud;
  String? _currentRoomId;
  bool _isMuted = false;
  bool _isSpeakerOn = true;

  /// Initialize TRTC
  Future<void> initialize({
    required int sdkAppId,
    required String secretKey,
  }) async {
    _cloud = await TRTCCloud.sharedInstance();
  }

  /// Create and host a voice room
  Future<void> createRoom({
    required String roomId,
    required String userId,
  }) async {
    if (_cloud == null) {
      throw Exception('TRTC not initialized');
    }

    _currentRoomId = roomId;

    final params = TRTCParams(
      sdkAppId: 20044652,
      roomId: int.parse(roomId),
      userId: userId,
      userSig: _generateUserSig(userId),
      role: TRTCRoleType.anchor,
    );

    _cloud!.enterRoom(params, TRTCAppScene.voiceChatRoom);
    _cloud!.startLocalAudio(TRTCAudioQuality.speech);
  }

  /// Join an existing voice room
  Future<void> joinRoom({
    required String roomId,
    required String userId,
  }) async {
    if (_cloud == null) {
      throw Exception('TRTC not initialized');
    }

    _currentRoomId = roomId;

    final params = TRTCParams(
      sdkAppId: 20044652,
      roomId: int.parse(roomId),
      userId: userId,
      userSig: _generateUserSig(userId),
      role: TRTCRoleType.audience,
    );

    _cloud!.enterRoom(params, TRTCAppScene.voiceChatRoom);
  }

  /// Leave current room
  Future<void> leaveRoom() async {
    if (_currentRoomId == null || _cloud == null) return;

    _cloud!.exitRoom();
    _currentRoomId = null;
  }

  /// Toggle microphone mute
  Future<void> toggleMute() async {
    if (_cloud == null) return;
    _isMuted = !_isMuted;
    _cloud!.muteLocalAudio(_isMuted);
  }

  /// Toggle speaker (placeholder - use device manager in production)
  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    // Note: Real implementation uses TXDeviceManager
  }

  String? get currentRoomId => _currentRoomId;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;

  String _generateUserSig(String userId) {
    return 'mock_sig_$userId';
  }

  Future<void> dispose() async {
    await leaveRoom();
    TRTCCloud.destroySharedInstance();
  }
}