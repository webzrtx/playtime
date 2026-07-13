import 'package:flutter/foundation.dart';

/// Mock TRTC Service - no native libs, works on all devices
class TRTCService {
  static final TRTCService _instance = TRTCService._internal();
  factory TRTCService() => _instance;
  TRTCService._internal();

  bool _isInitialized = false;
  String? _currentRoomId;
  bool _isMuted = false;

  Future<void> initialize({required int sdkAppId, required String secretKey}) async {
    _isInitialized = true;
    debugPrint('TRTC Service (mock) initialized');
  }

  Future<void> createRoom({required String roomId, required String userId}) async {
    _currentRoomId = roomId;
    debugPrint('Created mock room: $roomId');
  }

  Future<void> joinRoom({required String roomId, required String userId}) async {
    _currentRoomId = roomId;
    debugPrint('Joined mock room: $roomId');
  }

  Future<void> leaveRoom() async {
    _currentRoomId = null;
    debugPrint('Left room');
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
  }

  Future<void> toggleSpeaker() async {}

  String? get currentRoomId => _currentRoomId;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => true;

  Future<void> dispose() async {
    await leaveRoom();
  }
}