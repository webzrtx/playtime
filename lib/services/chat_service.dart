import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';
import 'package:tencent_cloud_chat_sdk/manager/v2_tim_manager.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimSDKListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/log_level_enum.dart';
import 'package:tencent_cloud_chat_sdk/enum/message_elem_type.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimAdvancedMsgListener.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_user_full_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_text_elem.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import '../config/trtc_config.dart';
import '../services/user_sig_service.dart';
import '../widgets/chat_panel.dart';

/// Manages Tencent Cloud IM for real-time chat in voice rooms.
///
/// Each TRTC voice room gets an IM [AVChatRoom] group (same roomId).
class ChatService extends ChangeNotifier {
  final V2TIMManager _im = TencentImSDKPlugin.v2TIMManager;
  bool _isLoggedIn = false;
  String _userId = '';
  String _displayName = '';
  String _currentRoomId = '';

  final List<ChatMessage> messages = [];
  String? _lastError;

  String? get lastError => _lastError;
  bool get isLoggedIn => _isLoggedIn;

  late final V2TimAdvancedMsgListener _msgListener;

  ChatService() {
    _msgListener = V2TimAdvancedMsgListener(
      onRecvNewMessage: _onNewMessage,
      onRecvMessageRevoked: _onMessageRevoked,
    );
  }

  /// Initialize IM SDK (call once at app start or before first use).
  Future<void> init() async {
    if (_isLoggedIn) return;
    final res = await _im.initSDK(
      sdkAppID: TRTCConfig.sdkAppId,
      loglevel: LogLevelEnum.V2TIM_LOG_INFO,
      listener: V2TimSDKListener(
        onConnecting: () => debugPrint('IM connecting...'),
        onConnectSuccess: () => debugPrint('IM connected'),
        onConnectFailed: (code, msg) {
          _lastError = 'IM connect failed: $code $msg';
          debugPrint(_lastError);
        },
        onKickedOffline: () {
          _lastError = 'IM kicked offline';
          _isLoggedIn = false;
          notifyListeners();
        },
        onUserSigExpired: () {
          _lastError = 'IM UserSig expired';
          notifyListeners();
        },
      ),
    );
    if (res.code != 0) {
      _lastError = 'IM init failed: ${res.code} ${res.desc}';
      debugPrint(_lastError);
      return;
    }
    debugPrint('IM SDK initialized');
  }

  /// Login to IM and join the chat group for the given room.
  Future<bool> enterRoom({
    required String userId,
    required String displayName,
    required String roomId,
  }) async {
    await init();
    _userId = userId;
    _displayName = displayName;
    _currentRoomId = roomId;

    // Login
    if (!_isLoggedIn) {
      final userSig = UserSigService.generate(
        sdkAppId: TRTCConfig.sdkAppId,
        secretKey: TRTCConfig.secretKey,
        userId: userId,
        expireSeconds: TRTCConfig.userSigExpireSeconds,
      );
      final loginRes = await _im.login(userID: userId, userSig: userSig);
      if (loginRes.code != 0) {
        _lastError = 'IM login failed: ${loginRes.code} ${loginRes.desc}';
        debugPrint(_lastError);
        return false;
      }
      await _im.setSelfInfo(userFullInfo: V2TimUserFullInfo(nickName: displayName));
      _isLoggedIn = true;
      debugPrint('IM logged in as $displayName ($userId)');
    }

    // Setup message listener
    await _im.getMessageManager().addAdvancedMsgListener(listener: _msgListener);

    // Join group (create if not exists via AVChatRoom auto-create)
    await _joinGroup(roomId);

    notifyListeners();
    return true;
  }

  Future<void> _joinGroup(String groupId) async {
    final res = await _im.joinGroup(groupID: groupId, message: '');
    if (res.code == 0 || res.code == 10013) {
      debugPrint('IM joined group $groupId');
    } else {
      debugPrint('IM join group failed (${res.code}), trying create...');
      final createRes = await _im.getGroupManager().createGroup(
        groupType: 'AVChatRoom',
        groupID: groupId,
        groupName: 'Voice Chat',
      );
      if (createRes.code != 0) {
        _lastError = 'IM group error: ${createRes.code} ${createRes.desc}';
        debugPrint(_lastError);
      }
    }
  }

  /// Send a text message to the current room group.
  Future<void> sendMessage(String text) async {
    if (!_isLoggedIn || _currentRoomId.isEmpty) return;

    // Add locally for instant feedback before server round-trip
    messages.add(ChatMessage(
      senderId: _userId,
      senderName: _displayName,
      text: text,
      isSelf: true,
    ));
    notifyListeners();

    // Create and send via IM
    final createRes = await _im.getMessageManager().createTextMessage(text: text);
    if (createRes.code != 0 || createRes.data?.messageInfo == null) {
      _lastError = 'Create msg failed: ${createRes.code}';
      debugPrint(_lastError);
      return;
    }

    final res = await _im.getMessageManager().sendMessage(
      message: createRes.data!.messageInfo!,
      receiver: '',
      groupID: _currentRoomId,
    );
    if (res.code != 0) {
      _lastError = 'Send failed: ${res.code} ${res.desc}';
      debugPrint(_lastError);
    }
  }

  /// Leave the current room group and clear messages.
  Future<void> leaveRoom() async {
    if (_currentRoomId.isNotEmpty) {
      await _im.quitGroup(groupID: _currentRoomId);
    }
    await _im.getMessageManager().removeAdvancedMsgListener(listener: _msgListener);
    messages.clear();
    _currentRoomId = '';
    notifyListeners();
  }

  /// Full cleanup — logout and reset.
  @override
  void dispose() {
    _im.logout();
    _isLoggedIn = false;
    super.dispose();
  }

  // ── Message callbacks ──

  void _onNewMessage(V2TimMessage msg) {
    if (msg.elemType != MessageElemType.V2TIM_ELEM_TYPE_TEXT) return;
    if (msg.textElem == null) return;

    final text = msg.textElem!.text ?? '';
    if (text.isEmpty) return;

    // Skip own messages (they come back from server in AVChatRoom)
    if (msg.sender == _userId) return;

    messages.add(ChatMessage(
      senderId: msg.sender ?? '',
      senderName: msg.nickName ?? msg.sender ?? 'Unknown',
      text: text,
    ));
    notifyListeners();
  }

  void _onMessageRevoked(String msgId) {
    messages.removeWhere((m) => m.senderId == msgId);
    notifyListeners();
  }
}
