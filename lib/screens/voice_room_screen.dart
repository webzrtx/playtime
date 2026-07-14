import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/room_model.dart';
import '../services/trtc_service.dart';
import '../services/pip_service.dart';
import '../config/trtc_config.dart';
import '../widgets/speaking_avatar.dart';
import '../widgets/user_avatar.dart';
import '../widgets/gift_panel.dart';
import '../widgets/gift_overlay.dart';
import '../widgets/chat_panel.dart';
import '../services/chat_service.dart';

class VoiceRoomScreen extends StatefulWidget {
  final String? roomId;
  final bool isHost;

  const VoiceRoomScreen({super.key, this.roomId, this.isHost = false});

  @override
  State<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends State<VoiceRoomScreen> {
  final TRTCService _trtc = TRTCService();
  final ChatService _chat = ChatService();
  final TextEditingController _chatCtrl = TextEditingController();
  final ScrollController _chatScroll = ScrollController();
  bool _isJoined = false;
  String _lastUserId = '';

  static const int _totalSeats = 8;

  // ── Palette ──
  static const _accent = Color(0xFF00CCF9);
  static const _pink = Color(0xFFFE6484);
  static const _gold = Color(0xFFF6AD1B);
  static const _bgDark = Color(0xFF1A1A2E);
  static const _bgCard = Color(0xFF16213E);

  String get _roomId => widget.roomId ?? TRTCConfig.defaultRoomId.toString();

  String _getUserId() {
    final user = Provider.of<UserModel>(context, listen: false);
    if (_lastUserId.isNotEmpty) return _lastUserId;
    if (user.id.isNotEmpty) return user.id;
    return 'guest_${DateTime.now().millisecondsSinceEpoch.remainder(100000)}';
  }

  String _getDisplayName() {
    final user = Provider.of<UserModel>(context, listen: false);
    if (user.username.isNotEmpty) return user.username;
    return 'Guest';
  }

  @override
  void initState() {
    super.initState();
    _initAndEnter();
  }

  Future<void> _initAndEnter() async {
    debugPrint('[VoiceRoom] _initAndEnter start');
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      debugPrint('[VoiceRoom] mic permission denied');
      if (mounted) setState(() => _isJoined = true);
      return;
    }
    final userId = _getUserId();
    final displayName = _getDisplayName();
    _lastUserId = userId;
    debugPrint('[VoiceRoom] userId=$userId displayName=$displayName roomId=$_roomId');

    // TRTC init/join (may throw — we still try IM regardless)
    try {
      await _trtc.initialize();
      if (widget.isHost) {
        await _trtc.createRoom(roomId: _roomId, userId: userId, displayName: displayName);
      } else {
        await _trtc.joinRoom(roomId: _roomId, userId: userId, displayName: displayName);
      }
      _trtc.addListener(_onUpdate);
      debugPrint('[VoiceRoom] TRTC joined OK');
    } catch (e, st) {
      debugPrint('[VoiceRoom] TRTC error: $e');
      debugPrint('[VoiceRoom] TRTC stack: $st');
      _trtc.addListener(_onUpdate);
    }

    // IM chat — always attempt, independent of TRTC success
    debugPrint('[VoiceRoom] calling _chat.enterRoom...');
    _chat.enterRoom(userId: userId, displayName: displayName, roomId: _roomId).then((ok) {
      debugPrint('[VoiceRoom] _chat.enterRoom returned $ok');
      _chat.addListener(_onUpdate);
      if (mounted) setState(() {});
    }).catchError((e, st) {
      debugPrint('[VoiceRoom] _chat.enterRoom ERROR: $e');
      debugPrint('[VoiceRoom] _chat.enterRoom stack: $st');
      if (mounted) setState(() {});
    });

    if (mounted) setState(() => _isJoined = true);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _sendChatMessage(String text) {
    _chat.sendMessage(text);
  }

  void _showGiftPanel() {
    GiftPanel.show(context, onSend: (gift) {
      final user = Provider.of<UserModel>(context, listen: false);
      final sender = user.username.isNotEmpty ? user.username : 'You';
      GiftOverlay.show(context, gift: gift, sender: sender);

      // Send gift notification as chat message via IM
      _chat.sendMessage('${gift.emoji} $sender sent a ${gift.label}');
    });
  }

  Future<void> _enterPip() async {
    final entered = await PipService.enterPip();
    if (!entered && mounted) Navigator.pop(context);
  }

  Future<void> _leaveRoom() async {
    final roomModel = Provider.of<RoomModel>(context, listen: false);
    if (widget.isHost) {
      roomModel.removeRoom(_roomId);
    } else {
      roomModel.leaveRoom();
    }
    await _trtc.leaveRoom();
    _chat.leaveRoom();
    if (mounted) Navigator.pop(context);
  }

  void _onSeatTap(int? seatNum) {
    if (_trtc.hasSeat) return;
    if (seatNum == null && !widget.isHost) return;
    _trtc.requestSeat();
  }

  void _submitChat() {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    _sendChatMessage(text);
    _chatCtrl.clear();
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _trtc.removeListener(_onUpdate);
    _trtc.dispose();
    _chat.removeListener(_onUpdate);
    _chat.dispose();
    _chatCtrl.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final anchors = _trtc.anchors;
    final audience = _trtc.audience;
    final allParticipants = _trtc.participants;
    final totalCount = allParticipants.length;

    final seatMap = <int, Participant?>{};
    int seatIdx = 0;
    for (final a in anchors) {
      if (a.isHost) continue;
      if (seatIdx < _totalSeats) {
        seatMap[seatIdx] = a;
        seatIdx++;
      }
    }
    for (int i = seatIdx; i < _totalSeats; i++) {
      seatMap[i] = null;
    }

    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            _buildTopBar(totalCount, anchors.isNotEmpty ? anchors.first : null),

            // Error
            if (_trtc.lastError != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('⚠ ${_trtc.lastError}',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),

            // Loading
            if (!_isJoined)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: _accent)),
              ),

            // ── Main content ──
            if (_isJoined) ...[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _buildOwnerSeat(anchors.isNotEmpty ? anchors.first : null),
                      const SizedBox(height: 24),
                      _buildSeatGrid(seatMap),
                      const SizedBox(height: 24),
                      if (audience.isNotEmpty) ...[
                        _buildSectionHeader('Listeners', audience.length),
                        const SizedBox(height: 8),
                        ...audience.map((p) => _AudienceRow(participant: p)),
                      ],
                      if (allParticipants.length <= 1)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.wifi_tethering, size: 40, color: Colors.white.withOpacity(0.2)),
                              const SizedBox(height: 12),
                              Text('Waiting for others to join...',
                                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Chat messages (always visible) ──
              if (_chat.messages.isNotEmpty)
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: _bgDark,
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.04))),
                  ),
                  child: ListView.builder(
                    controller: _chatScroll,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    itemCount: _chat.messages.length,
                    itemBuilder: (_, i) {
                      final m = _chat.messages[i];
                      // System message (gift notification, etc.)
                      if (m.isSystem) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: _pink.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(m.text,
                                  style: TextStyle(
                                    color: _pink,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  )),
                            ),
                          ),
                        );
                      }
                      // Regular message
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            UserAvatar(userId: m.senderId, displayName: m.senderName, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.senderName,
                                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(m.text,
                                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              // ── Bottom bar ──
              _buildBottomBar(),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TOP BAR
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildTopBar(int totalCount, Participant? host) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: _enterPip,
            child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          UserAvatar(userId: host?.userId ?? '', displayName: host?.label ?? 'H', size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(host?.label ?? 'Host',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _gold.withOpacity(0.5), width: 0.5),
                      ),
                      child: const Text('Host',
                          style: TextStyle(color: _gold, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.greenAccent),
                    const SizedBox(width: 4),
                    Text('$totalCount online',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _leaveRoom,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _pink.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call_end, color: _pink, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // OWNER SEAT
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildOwnerSeat(Participant? owner) {
    final hasOwner = owner != null;
    return Column(
      children: [
        _buildSectionHeader('Host', 1),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: hasOwner ? null : () => _onSeatTap(null),
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasOwner ? const LinearGradient(colors: [_gold, Color(0xFFE89500)]) : null,
              color: hasOwner ? null : Colors.white.withOpacity(0.08),
              border: Border.all(
                color: hasOwner ? _gold : Colors.white.withOpacity(0.2),
                width: hasOwner ? 2.5 : 1.5,
              ),
            ),
            child: hasOwner
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SpeakingAvatar(
                        isSpeaking: owner.isSpeaking, volume: owner.volume, size: 44, glowColor: _gold,
                        child: UserAvatar(userId: owner.userId, displayName: owner.label, size: 44),
                      ),
                      const SizedBox(height: 2),
                      Text(owner.label, style: const TextStyle(color: Colors.white, fontSize: 10),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add, color: Colors.white.withOpacity(0.3), size: 28),
                      const SizedBox(height: 2),
                      Text('Host', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SEAT GRID
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSeatGrid(Map<int, Participant?> seatMap) {
    return Column(
      children: [
        _buildSectionHeader('Mic Seats', _totalSeats),
        const SizedBox(height: 12),
        _buildSeatRow(0, 4, seatMap),
        const SizedBox(height: 16),
        _buildSeatRow(4, 4, seatMap),
      ],
    );
  }

  Widget _buildSeatRow(int start, int count, Map<int, Participant?> seatMap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(count, (i) {
        final seatNum = start + i;
        return _SeatCircle(
          seatNum: seatNum + 1,
          occupied: seatMap[seatNum] != null,
          participant: seatMap[seatNum],
          onTap: () => _onSeatTap(seatNum),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION HEADER
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Container(width: 3, height: 14,
            decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('$count', style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // BOTTOM BAR (WePlay-style: Audio | Mute | Chat | Gift)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildBottomBar() {
    final isAudience = !_trtc.hasSeat;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
      decoration: BoxDecoration(
        color: _bgCard,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: isAudience
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _trtc.requestSeat(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.mic, color: Colors.white, size: 18),
                label: const Text('Take a Seat',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            )
          : Row(
              children: [
                // 1. Audio (hear others)
                _BarBtn(
                  icon: _trtc.isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                  active: _trtc.isSpeakerOn,
                  activeColor: _accent,
                  onTap: () => _trtc.toggleSpeaker(),
                ),
                const SizedBox(width: 8),

                // 2. Mute / Speak (own mic)
                _BarBtn(
                  icon: _trtc.isMuted ? Icons.mic_off : Icons.mic,
                  active: !_trtc.isMuted,
                  activeColor: _accent,
                  onTap: () => _trtc.toggleMute(),
                ),
                const SizedBox(width: 8),

                // 3. Chat input (always visible)
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _chatCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Send a message...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        border: InputBorder.none,
                        suffixIcon: _chatCtrl.text.isNotEmpty
                            ? GestureDetector(
                                onTap: _submitChat,
                                child: const Icon(Icons.send_rounded, color: _accent, size: 20),
                              )
                            : null,
                      ),
                      textInputAction: TextInputAction.send,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _submitChat(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 4. Gift
                _BarBtn(
                  icon: Icons.card_giftcard,
                  active: false,
                  activeColor: _pink,
                  onTap: _showGiftPanel,
                ),
              ],
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _SeatCircle extends StatelessWidget {
  final int seatNum;
  final bool occupied;
  final Participant? participant;
  final VoidCallback onTap;

  const _SeatCircle({required this.seatNum, required this.occupied, this.participant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = participant;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 64, height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: occupied ? const Color(0xFF2A2A4A) : Colors.white.withOpacity(0.06),
          border: Border.all(
            color: occupied ? const Color(0xFF00CCF9) : Colors.white.withOpacity(0.15),
            width: occupied ? 2.5 : 1.5,
          ),
        ),
        child: occupied
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpeakingAvatar(
                    isSpeaking: p?.isSpeaking ?? false,
                    volume: p?.volume ?? 0,
                    size: 36,
                    glowColor: const Color(0xFF00CCF9),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        UserAvatar(userId: p?.userId ?? '', displayName: p?.label ?? '?', size: 36),
                        if (p?.isHost == true)
                          Positioned(
                            right: 0, bottom: 0,
                            child: Container(
                              width: 14, height: 14,
                              decoration: const BoxDecoration(color: Color(0xFFF6AD1B), shape: BoxShape.circle),
                              child: const Icon(Icons.star, size: 8, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(p?.label ?? '', style: const TextStyle(color: Colors.white70, fontSize: 9),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              )
            : Icon(Icons.mic_none, color: Colors.white.withOpacity(0.2), size: 24),
      ),
    );
  }
}

class _AudienceRow extends StatelessWidget {
  final Participant participant;
  const _AudienceRow({required this.participant});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          UserAvatar(userId: participant.userId, displayName: participant.label, size: 32),
          const SizedBox(width: 10),
          Text(participant.label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Icon(Icons.headset_mic, size: 16, color: Colors.white.withOpacity(0.3)),
        ],
      ),
    );
  }
}

class _BarBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _BarBtn({required this.icon, required this.active, required this.activeColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = active ? activeColor.withOpacity(0.2) : Colors.white.withOpacity(0.06);
    final fg = active ? activeColor : Colors.white54;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: fg, size: 20),
      ),
    );
  }
}
