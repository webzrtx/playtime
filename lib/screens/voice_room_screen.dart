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

// WePlay-inspired voice room screen
class VoiceRoomScreen extends StatefulWidget {
  final String? roomId;
  final bool isHost;

  const VoiceRoomScreen({super.key, this.roomId, this.isHost = false});

  @override
  State<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends State<VoiceRoomScreen> {
  final TRTCService _trtc = TRTCService();
  bool _isJoined = false;
  bool _isHandRaised = false;
  String _lastUserId = '';

  static const int _totalSeats = 8;

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
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) setState(() => _isJoined = true);
      return;
    }
    try {
      final userId = _getUserId();
      final displayName = _getDisplayName();
      _lastUserId = userId;
      await _trtc.initialize();
      if (widget.isHost) {
        await _trtc.createRoom(roomId: _roomId, userId: userId, displayName: displayName);
      } else {
        await _trtc.joinRoom(roomId: _roomId, userId: userId, displayName: displayName);
      }
      _trtc.addListener(_onUpdate);
      if (mounted) setState(() => _isJoined = true);
    } catch (e) {
      debugPrint('TRTC init error: $e');
      _trtc.addListener(_onUpdate);
      if (mounted) setState(() => _isJoined = true);
    }
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  /// Enter PiP — audio continues in background, room stays alive.
  Future<void> _enterPip() async {
    final entered = await PipService.enterPip();
    if (!entered && mounted) {
      // PiP not supported → just go back but keep room alive
      Navigator.pop(context);
    }
  }

  /// Leave room completely — disconnect and destroy.
  Future<void> _leaveRoom() async {
    final roomModel = Provider.of<RoomModel>(context, listen: false);
    if (widget.isHost) {
      roomModel.removeRoom(_roomId);
    } else {
      roomModel.leaveRoom();
    }
    await _trtc.leaveRoom();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _trtc.removeListener(_onUpdate);
    _trtc.dispose();
    super.dispose();
  }

  // -- Color constants (WePlay palette) --
  static const _accent = Color(0xFF00CCF9);
  static const _pink = Color(0xFFFE6484);
  static const _gold = Color(0xFFF6AD1B);
  static const _bgDark = Color(0xFF1A1A2E);
  static const _bgCard = Color(0xFF16213E);
  static const _white70 = Color(0xB3FFFFFF);

  @override
  Widget build(BuildContext context) {
    final anchors = _trtc.anchors;
    final audience = _trtc.audience;
    final allParticipants = _trtc.participants;
    final totalCount = allParticipants.length;

    // Build seat map: anchors who are not the host occupy seat positions
    final seatMap = <int, Participant?>{};
    int seatIdx = 0;
    for (final a in anchors) {
      if (a.isHost) continue; // host stays in owner seat, not in grid
      if (seatIdx < _totalSeats) {
        seatMap[seatIdx] = a;
        seatIdx++;
      }
    }
    // Fill remaining seats as empty
    for (int i = seatIdx; i < _totalSeats; i++) {
      seatMap[i] = null;
    }

    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // -- Top bar --
            _buildTopBar(totalCount, anchors.isNotEmpty ? anchors.first : null),

            // -- Error banner --
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

            // -- Loading --
            if (!_isJoined)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: _accent),
                ),
              ),

            // -- Main content --
            if (_isJoined) ...[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      // Owner seat row
                      _buildOwnerSeat(anchors.isNotEmpty ? anchors.first : null),
                      const SizedBox(height: 24),

                      // Seat grid: 2 rows × 4 seats
                      _buildSeatGrid(seatMap),
                      const SizedBox(height: 24),

                      // Audience section
                      if (audience.isNotEmpty) ...[
                        _buildSectionHeader('Listeners', audience.length),
                        const SizedBox(height: 8),
                        ...audience.map((p) => _AudienceRow(participant: p)),
                      ],

                      // Empty state
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

                      const SizedBox(height: 80), // space for bottom bar
                    ],
                  ),
                ),
              ),
            ],

            // -- Bottom controls --
            if (_isJoined) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────

  Widget _buildTopBar(int totalCount, Participant? host) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _enterPip,
            child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          // Host avatar
          UserAvatar(
            userId: host?.userId ?? '',
            displayName: host?.label ?? 'H',
            size: 38,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        host?.label ?? 'Host',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
          _TopAction(icon: Icons.more_horiz, onTap: () {}),
        ],
      ),
    );
  }

  // ── Owner Seat ─────────────────────────────────────────────────────

  Widget _buildOwnerSeat(Participant? owner) {
    final hasOwner = owner != null;
    return Column(
      children: [
        _buildSectionHeader('Host', 1),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: hasOwner ? null : () => _onSeatTap(null),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasOwner
                  ? const LinearGradient(colors: [_gold, Color(0xFFE89500)])
                  : null,
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
                        isSpeaking: owner.isSpeaking,
                        volume: owner.volume,
                        size: 44,
                        glowColor: _gold,
                        child: UserAvatar(
                          userId: owner.userId,
                          displayName: owner.label,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        owner.label,
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  // ── Seat Grid ──────────────────────────────────────────────────────

  Widget _buildSeatGrid(Map<int, Participant?> seatMap) {
    return Column(
      children: [
        _buildSectionHeader('Mic Seats', _totalSeats),
        const SizedBox(height: 12),
        // Row 1: seats 0-3
        _buildSeatRow(0, 4, seatMap),
        const SizedBox(height: 16),
        // Row 2: seats 4-7
        _buildSeatRow(4, 4, seatMap),
      ],
    );
  }

  Widget _buildSeatRow(int start, int count, Map<int, Participant?> seatMap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(count, (i) {
        final seatNum = start + i;
        final occupant = seatMap[seatNum];
        return _SeatCircle(
          seatNum: seatNum + 1, // display 1-8
          occupied: occupant != null,
          participant: occupant,
          onTap: () => _onSeatTap(seatNum),
        );
      }),
    );
  }

  void _onSeatTap(int? seatNum) {
    if (_trtc.hasSeat) return; // already on a seat
    if (seatNum == null && !widget.isHost) return; // only host can take owner seat
    _trtc.requestSeat();
  }

  // ── Section Header ─────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Container(
          width: 3, height: 14,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('$count',
            style: TextStyle(color: _white70, fontSize: 12)),
      ],
    );
  }

  // ── Bottom Bar ─────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final isAudience = !_trtc.hasSeat;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: isAudience
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _trtc.requestSeat(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.mic, color: Colors.white),
                label: const Text('Take a Seat',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _BottomBtn(
                  icon: _trtc.isMuted ? Icons.mic_off : Icons.mic,
                  label: 'Mic',
                  active: _trtc.isMuted,
                  activeColor: Colors.red,
                  onTap: () => _trtc.toggleMute(),
                ),
                _BottomBtn(
                  icon: Icons.volume_up,
                  label: 'Speaker',
                  active: _trtc.isSpeakerOn,
                  activeColor: _accent,
                  onTap: () => _trtc.toggleSpeaker(),
                ),
                _BottomBtn(
                  icon: Icons.card_giftcard,
                  label: 'Gift',
                  active: false,
                  activeColor: _pink,
                  onTap: () {},
                ),
                _BottomBtn(
                  icon: _isHandRaised ? Icons.pan_tool : Icons.front_hand,
                  label: 'Hand',
                  active: _isHandRaised,
                  activeColor: Colors.orange,
                  onTap: () => setState(() => _isHandRaised = !_isHandRaised),
                ),
                if (!_trtc.isHost)
                  _BottomBtn(
                    icon: Icons.event_seat,
                    label: 'Seat',
                    active: false,
                    activeColor: _accent,
                    onTap: () => _trtc.leaveSeat(),
                  ),
                _BottomBtn(
                  icon: Icons.call_end,
                  label: 'Leave',
                  active: false,
                  activeColor: _pink,
                  isEnd: true,
                  onTap: _leaveRoom,
                ),
              ],
            ),
    );
  }
}

// ── Seat Circle Widget ──────────────────────────────────────────────

class _SeatCircle extends StatelessWidget {
  final int seatNum;
  final bool occupied;
  final Participant? participant;
  final VoidCallback onTap;

  const _SeatCircle({
    required this.seatNum,
    required this.occupied,
    this.participant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = participant;
    final speaking = p?.isSpeaking ?? false;
    final volume = p?.volume ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: occupied ? const Color(0xFF2A2A4A) : Colors.white.withOpacity(0.06),
          border: Border.all(
            color: occupied
                ? const Color(0xFF00CCF9)
                : Colors.white.withOpacity(0.15),
            width: occupied ? 2.5 : 1.5,
          ),
        ),
        child: occupied
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpeakingAvatar(
                    isSpeaking: speaking,
                    volume: volume,
                    size: 36,
                    glowColor: const Color(0xFF00CCF9),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        UserAvatar(
                          userId: p?.userId ?? '',
                          displayName: p?.label ?? '?',
                          size: 36,
                        ),
                        if (p?.isHost == true)
                          Positioned(
                            right: 0, bottom: 0,
                            child: Container(
                              width: 14, height: 14,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF6AD1B), shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.star, size: 8, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p?.label ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            : Icon(Icons.mic_none, color: Colors.white.withOpacity(0.2), size: 24),
      ),
    );
  }
}

// ── Audience Row Widget ─────────────────────────────────────────────

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
          UserAvatar(
            userId: participant.userId,
            displayName: participant.label,
            size: 32,
          ),
          const SizedBox(width: 10),
          Text(participant.label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Icon(Icons.headset_mic, size: 16, color: Colors.white.withOpacity(0.3)),
        ],
      ),
    );
  }
}

// ── Bottom Button Widget ────────────────────────────────────────────

class _BottomBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final bool isEnd;
  final VoidCallback onTap;

  const _BottomBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    this.isEnd = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isEnd
        ? const Color(0xFFFE6484)
        : (active ? activeColor.withOpacity(0.2) : Colors.white.withOpacity(0.08));
    final fgColor = isEnd ? Colors.white : (active ? activeColor : Colors.white54);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: fgColor, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: fgColor, fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Top Action Button ───────────────────────────────────────────────

class _TopAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }
}
