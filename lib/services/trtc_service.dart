import 'package:flutter/foundation.dart';
import 'package:tencent_rtc_sdk/trtc_cloud.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_def.dart';
import '../utils/user_sig_generator.dart';
import '../config/trtc_config.dart';

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
    try {
      _cloud = await TRTCCloud.sharedInstance();
    } catch (e) {
      debugPrint('TRTC init error: $e');
    }
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

    // Generate real UserSig
    final userSig = UserSigGenerator.generate(
      sdkAppId: TRTCConfig.sdkAppId,
      secretKey: TRTCConfig.secretKey,
      userId: userId,
    );

    final params = TRTCParams(
      sdkAppId: TRTCConfig.sdkAppId,
      roomId: int.parse(roomId),
      userId: userId,
      userSig: userSig,
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

    // Generate real UserSig
    final userSig = UserSigGenerator.generate(
      sdkAppId: TRTCConfig.sdkAppId,
      secretKey: TRTCConfig.secretKey,
      userId: userId,
    );

    final params = TRTCParams(
      sdkAppId: TRTCConfig.sdkAppId,
      roomId: int.parse(roomId),
      userId: userId,
      userSig: userSig,
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

  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
  }

  String? get currentRoomId => _currentRoomId;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;

  Future<void> dispose() async {
    await leaveRoom();
    TRTCCloud.destroySharedInstance();
  }
}