// Tencent TRTC Voice Room Service.
//
// Thin wrapper around [TRTCCloud] with:
//  - SDK initialization / disposal
//  - Room lifecycle (create = enterRoom as anchor, join, leave, destroy)
//  - Voice engine (mute, unmute, speaker routing)
//  - User audio volume callbacks for speaking indicators
//
// See: https://trtc.io/document/63255

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tencent_rtc_sdk/trtc_cloud.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_def.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_listener.dart';
import 'package:tencent_rtc_sdk/tx_device_manager.dart';
import '../config/trtc_config.dart';
import 'user_sig_service.dart';

/// Participant data surfaced to the UI.
class Participant {
  final String userId;
  final bool isSpeaking;
  final int volume;
  const Participant({required this.userId, this.isSpeaking = false, this.volume = 0});
}

/// Room join result.
enum TRTCJoinResult { success, error }

/// TRTC Service — singleton wrapping TRTCCloud.
class TRTCService extends ChangeNotifier {
  TRTCCloud? _cloud;
  TXDeviceManager? _deviceManager;

  TRTCCloudListener? _listener;

  String _userId = '';
  String _roomId = '';
  String? _lastError;

  bool _isMuted = false;
  bool _isSpeakerOn = true;
  int _localVolume = 0;

  final List<Participant> _participants = [];
  final Map<String, int> _volumes = {};

  // -- Getters --------------------------------------------------------
  bool get isInRoom => _cloud != null && _roomId.isNotEmpty;
  String get userId => _userId;
  String get roomId => _roomId;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  String? get lastError => _lastError;
  int get localVolume => _localVolume;
  List<Participant> get participants => List.unmodifiable(_participants);
  Map<String, int> get volumes => Map.unmodifiable(_volumes);

  // -- Initialization -------------------------------------------------

  /// Must be called once before entering any room.
  Future<void> initialize() async {
    _cloud = await TRTCCloud.sharedInstance();
    _deviceManager = _cloud!.getDeviceManager();

    _listener = TRTCCloudListener(
      onError: (errCode, errMsg) {
        debugPrint('TRTC onError: $errCode — $errMsg');
        _lastError = '[$errCode] $errMsg';
        notifyListeners();
      },
      onWarning: (code, msg) {
        debugPrint('TRTC onWarning: $code — $msg');
      },
      onEnterRoom: (result) {
        if (result > 0) {
          debugPrint('TRTC entered room in ${result}ms');
          _lastError = null;
        } else {
          debugPrint('TRTC enterRoom failed: $result');
          _lastError = 'Enter room failed: $result';
        }
        notifyListeners();
      },
      onExitRoom: (reason) {
        debugPrint('TRTC exitRoom reason=$reason');
        _participants.clear();
        _volumes.clear();
        notifyListeners();
      },
      onRemoteUserEnterRoom: (uid) {
        debugPrint('TRTC remote user entered: $uid');
        _participants.add(Participant(userId: uid));
        notifyListeners();
      },
      onRemoteUserLeaveRoom: (uid, reason) {
        debugPrint('TRTC remote user left: $uid reason=$reason');
        _participants.removeWhere((p) => p.userId == uid);
        _volumes.remove(uid);
        notifyListeners();
      },
      onUserAudioAvailable: (uid, available) {
        debugPrint('TRTC user audio: $uid available=$available');
      },
      onUserVoiceVolume: (userVolumes, totalVolume) {
        for (final v in userVolumes) {
          if (v.userId.isEmpty) {
            _localVolume = v.volume;
          } else {
            _volumes[v.userId] = v.volume;
          }
        }
        // Update speaking flag on participants
        for (var i = 0; i < _participants.length; i++) {
          final p = _participants[i];
          final vol = _volumes[p.userId] ?? 0;
          if (p.volume != vol) {
            _participants[i] = Participant(
              userId: p.userId,
              volume: vol,
              isSpeaking: vol > 5,
            );
          }
        }
        notifyListeners();
      },
      onMicDidReady: () => debugPrint('TRTC mic ready'),
      onAudioRouteChanged: (newRoute, oldRoute) {
        debugPrint('TRTC audio route: ${oldRoute.name} → ${newRoute.name}');
      },
      onConnectionLost: () {
        _lastError = 'Connection lost';
        notifyListeners();
      },
      onTryToReconnect: () => debugPrint('TRTC reconnecting...'),
      onConnectionRecovery: () {
        _lastError = null;
        debugPrint('TRTC reconnected');
        notifyListeners();
      },
    );

    _cloud!.registerListener(_listener!);
  }

  // -- Room lifecycle -------------------------------------------------

  /// Create/enter room as anchor. For host users.
  Future<void> createRoom({
    required String roomId,
    required String userId,
  }) async {
    _userId = userId;
    _roomId = roomId;

    final userSig = UserSigService.generate(
      sdkAppId: TRTCConfig.sdkAppId,
      secretKey: TRTCConfig.secretKey,
      userId: userId,
      expireSeconds: TRTCConfig.userSigExpireSeconds,
    );

    // Add self as host participant
    _participants.clear();
    _participants.add(Participant(userId: userId));

    final params = TRTCParams(
      sdkAppId: TRTCConfig.sdkAppId,
      userId: userId,
      userSig: userSig,
      strRoomId: roomId,
      role: TRTCRoleType.anchor,
    );

    _cloud!.enterRoom(params, TRTCAppScene.voiceChatRoom);

    // Enable audio volume callbacks for speaking indicators
    _cloud!.enableAudioVolumeEvaluation(
      true,
      TRTCAudioVolumeEvaluateParams(interval: 300),
    );
    _cloud!.startLocalAudio(TRTCAudioQuality.speech);
  }

  /// Join an existing room.
  Future<void> joinRoom({
    required String roomId,
    required String userId,
  }) async {
    _userId = userId;
    _roomId = roomId;

    final userSig = UserSigService.generate(
      sdkAppId: TRTCConfig.sdkAppId,
      secretKey: TRTCConfig.secretKey,
      userId: userId,
      expireSeconds: TRTCConfig.userSigExpireSeconds,
    );

    _participants.clear();
    _participants.add(Participant(userId: userId));

    final params = TRTCParams(
      sdkAppId: TRTCConfig.sdkAppId,
      userId: userId,
      userSig: userSig,
      strRoomId: roomId,
      role: TRTCRoleType.anchor,
    );

    _cloud!.enterRoom(params, TRTCAppScene.voiceChatRoom);

    _cloud!.enableAudioVolumeEvaluation(
      true,
      TRTCAudioVolumeEvaluateParams(interval: 300),
    );
    _cloud!.startLocalAudio(TRTCAudioQuality.speech);
  }

  /// Leave the current room.
  Future<void> leaveRoom() async {
    if (_cloud != null) {
      _cloud!.exitRoom();
    }
    _roomId = '';
    _participants.clear();
    _volumes.clear();
    notifyListeners();
  }

  /// Destroy the room and release SDK resources (host only).
  Future<void> destroyRoom() async {
    await leaveRoom();
    _dispose();
  }

  // -- Voice engine controls ------------------------------------------

  /// Toggle local microphone mute.
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    _cloud?.muteLocalAudio(_isMuted);
    notifyListeners();
  }

  /// Toggle between speakerphone and earpiece.
  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    _deviceManager?.setAudioRoute(
      _isSpeakerOn ? TXAudioRoute.speakerPhone : TXAudioRoute.earpiece,
    );
    notifyListeners();
  }

  // -- Lifecycle ------------------------------------------------------

  void _dispose() {
    if (_listener != null && _cloud != null) {
      _cloud!.unRegisterListener(_listener!);
    }
    TRTCCloud.destroySharedInstance();
    _cloud = null;
    _deviceManager = null;
    _listener = null;
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }
}
