// Tencent TRTC Voice Room Service.
//
// Thin wrapper around [TRTCCloud] with:
//  - SDK initialization / disposal
//  - Room lifecycle (create as host/anchor, join as audience, leave, destroy)
//  - Seat management (audience → anchor switch, anchor → audience)
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

enum ParticipantRole { host, anchor, audience }

/// Participant data surfaced to the UI.
class Participant {
  final String userId;
  final ParticipantRole role;
  final bool isSpeaking;
  final int volume;
  const Participant({
    required this.userId,
    this.role = ParticipantRole.audience,
    this.isSpeaking = false,
    this.volume = 0,
  });

  bool get hasSeat => role != ParticipantRole.audience;
  bool get isHost => role == ParticipantRole.host;

  Participant copyWith({
    String? userId,
    ParticipantRole? role,
    bool? isSpeaking,
    int? volume,
  }) {
    return Participant(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      volume: volume ?? this.volume,
    );
  }
}

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
  bool _isHost = false;
  ParticipantRole _myRole = ParticipantRole.audience;

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
  bool get isHost => _isHost;
  ParticipantRole get myRole => _myRole;
  bool get hasSeat => _myRole != ParticipantRole.audience;
  List<Participant> get participants => List.unmodifiable(_participants);
  List<Participant> get anchors =>
      _participants.where((p) => p.hasSeat).toList();
  List<Participant> get audience =>
      _participants.where((p) => !p.hasSeat).toList();

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
        _myRole = ParticipantRole.audience;
        notifyListeners();
      },
      onRemoteUserEnterRoom: (uid) {
        debugPrint('TRTC remote user entered: $uid');
        _participants.add(Participant(userId: uid, role: ParticipantRole.audience));
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
        // Update role — if user published audio, they took a seat
        if (available) {
          _updateParticipantRole(uid, ParticipantRole.anchor);
        }
      },
      onSwitchRole: (errCode, errMsg) {
        debugPrint('TRTC switchRole: $errCode — $errMsg');
        notifyListeners();
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
          if (p.volume != vol || p.isSpeaking != (vol > 5)) {
            _participants[i] = p.copyWith(volume: vol, isSpeaking: vol > 5);
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

  void _updateParticipantRole(String uid, ParticipantRole role) {
    for (var i = 0; i < _participants.length; i++) {
      if (_participants[i].userId == uid) {
        _participants[i] = _participants[i].copyWith(role: role);
        break;
      }
    }
  }

  // -- Room lifecycle -------------------------------------------------

  /// Create room as host (anchor). For room creators.
  Future<void> createRoom({
    required String roomId,
    required String userId,
  }) async {
    _userId = userId;
    _roomId = roomId;
    _isHost = true;
    _myRole = ParticipantRole.host;

    final userSig = UserSigService.generate(
      sdkAppId: TRTCConfig.sdkAppId,
      secretKey: TRTCConfig.secretKey,
      userId: userId,
      expireSeconds: TRTCConfig.userSigExpireSeconds,
    );

    _participants.clear();
    _participants.add(Participant(userId: userId, role: ParticipantRole.host));

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

  /// Join an existing room as audience (listen only).
  Future<void> joinRoom({
    required String roomId,
    required String userId,
  }) async {
    _userId = userId;
    _roomId = roomId;
    _isHost = false;
    _myRole = ParticipantRole.audience;

    final userSig = UserSigService.generate(
      sdkAppId: TRTCConfig.sdkAppId,
      secretKey: TRTCConfig.secretKey,
      userId: userId,
      expireSeconds: TRTCConfig.userSigExpireSeconds,
    );

    _participants.clear();
    _participants.add(Participant(userId: userId, role: ParticipantRole.audience));

    final params = TRTCParams(
      sdkAppId: TRTCConfig.sdkAppId,
      userId: userId,
      userSig: userSig,
      strRoomId: roomId,
      role: TRTCRoleType.audience,
    );

    _cloud!.enterRoom(params, TRTCAppScene.voiceChatRoom);

    // Audience doesn't publish audio — just listen + volume callbacks
    _cloud!.enableAudioVolumeEvaluation(
      true,
      TRTCAudioVolumeEvaluateParams(interval: 300),
    );
  }

  /// Leave the current room.
  Future<void> leaveRoom() async {
    if (_cloud != null) {
      _cloud!.exitRoom();
    }
    _roomId = '';
    _isHost = false;
    _myRole = ParticipantRole.audience;
    _participants.clear();
    _volumes.clear();
    notifyListeners();
  }

  /// Destroy room and release SDK resources.
  Future<void> destroyRoom() async {
    await leaveRoom();
    _dispose();
  }

  // -- Seat management -------------------------------------------------

  /// Audience requests to speak → switch to anchor.
  Future<void> requestSeat() async {
    if (_myRole != ParticipantRole.audience) return;
    _cloud?.switchRole(TRTCRoleType.anchor);
    _myRole = ParticipantRole.anchor;
    _updateParticipantRole(_userId, ParticipantRole.anchor);
    _cloud?.startLocalAudio(TRTCAudioQuality.speech);
    notifyListeners();
  }

  /// Anchor gives up seat → switch to audience.
  Future<void> leaveSeat() async {
    if (_myRole == ParticipantRole.audience) return;
    _cloud?.switchRole(TRTCRoleType.audience);
    _cloud?.stopLocalAudio();
    _myRole = ParticipantRole.audience;
    _updateParticipantRole(_userId, ParticipantRole.audience);
    notifyListeners();
  }

  // -- Voice engine controls ------------------------------------------

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    _cloud?.muteLocalAudio(_isMuted);
    notifyListeners();
  }

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
