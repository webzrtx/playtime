import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/room_model.dart';
import '../services/trtc_service.dart';
import '../config/trtc_config.dart';

/// Voice room screen — real TRTC voice chat with host/audience roles.
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

  String get _roomId => widget.roomId ?? TRTCConfig.defaultRoomId.toString();

  String _getUserId() {
    final user = Provider.of<UserModel>(context, listen: false);
    if (_lastUserId.isNotEmpty) return _lastUserId;
    if (user.id.isNotEmpty) return user.id;
    return 'guest_${DateTime.now().millisecondsSinceEpoch.remainder(100000)}';
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
      _lastUserId = userId;
      await _trtc.initialize();

      if (widget.isHost) {
        await _trtc.createRoom(roomId: _roomId, userId: userId);
      } else {
        await _trtc.joinRoom(roomId: _roomId, userId: userId);
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

  @override
  Widget build(BuildContext context) {
    final participants = _trtc.participants;
    final anchors = _trtc.anchors;
    final audience = _trtc.audience;

    return Scaffold(
      appBar: AppBar(
        title: Text('Room $_roomId', style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _leaveRoom,
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Status header
            _buildStatusHeader(participants.length),

            // Error banner
            if (_trtc.lastError != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('⚠ ${_trtc.lastError}',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
              ),

            // Loading
            if (!_isJoined)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),

            // Anchors (seats)
            if (_isJoined && anchors.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    const Icon(Icons.mic, size: 14, color: Colors.deepPurple),
                    const SizedBox(width: 6),
                    Text('Speakers (${anchors.length}/50)',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                            fontSize: 13)),
                  ],
                ),
              ),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: anchors.length,
                  itemBuilder: (_, i) =>
                      _AnchorSeat(participant: anchors[i]),
                ),
              ),
            ],

            // Audience
            if (_isJoined && audience.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    const Icon(Icons.headset_mic, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('Listening (${audience.length})',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                            fontSize: 13)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: audience.length,
                  itemBuilder: (_, i) =>
                      _AudienceTile(participant: audience[i]),
                ),
              ),
            ],

            // Empty state
            if (_isJoined && participants.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('Waiting for others to join...',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),

            // Bottom controls
            if (_isJoined) _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _StatusBadge(
                  icon: Icons.people,
                  label: '$count',
                  color: Colors.green),
              const SizedBox(width: 8),
              _StatusBadge(
                  icon: _isJoined ? Icons.wifi : Icons.wifi_off,
                  label: _isJoined ? 'Live' : '...',
                  color: _isJoined ? Colors.deepPurple : Colors.orange),
              const Spacer(),
              if (_trtc.hasSeat) ...[
                Icon(_trtc.isMuted ? Icons.mic_off : Icons.mic,
                    size: 14, color: _trtc.isMuted ? Colors.red : Colors.green),
                const SizedBox(width: 4),
                SizedBox(
                  width: 80,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                        begin: 0,
                        end: _trtc.isMuted ? 0 : _trtc.localVolume / 100.0),
                    duration: const Duration(milliseconds: 150),
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          v > 0.3 ? Colors.green : Colors.grey),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_trtc.hasSeat && !_trtc.isHost)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('🎤 You have a seat — mic is live',
                  style: TextStyle(fontSize: 11, color: Colors.deepPurple)),
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final isAudience = !_trtc.hasSeat;

    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.grey.shade100,
      child: SafeArea(
        child: isAudience
            ? SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _trtc.requestSeat(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.mic, color: Colors.white),
                  label: const Text('Request Seat (Speak)',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CtrlBtn(
                    icon: _trtc.isMuted ? Icons.mic_off : Icons.mic,
                    label: _trtc.isMuted ? 'Unmute' : 'Mute',
                    color: _trtc.isMuted ? Colors.red : Colors.black,
                    active: _trtc.isMuted,
                    onTap: () => _trtc.toggleMute(),
                  ),
                  _CtrlBtn(
                    icon: Icons.volume_up,
                    label: 'Speaker',
                    color: Colors.black,
                    active: _trtc.isSpeakerOn,
                    onTap: () => _trtc.toggleSpeaker(),
                  ),
                  if (!_trtc.isHost)
                    _CtrlBtn(
                      icon: Icons.event_seat,
                      label: 'Leave Seat',
                      color: Colors.orange,
                      active: false,
                      onTap: () => _trtc.leaveSeat(),
                    ),
                  _CtrlBtn(
                    icon: _isHandRaised ? Icons.pan_tool : Icons.front_hand,
                    label: 'Hand',
                    color: _isHandRaised ? Colors.orange : Colors.black,
                    active: _isHandRaised,
                    onTap: () =>
                        setState(() => _isHandRaised = !_isHandRaised),
                  ),
                  _CtrlBtn(
                    icon: Icons.call_end,
                    label: 'Leave',
                    color: Colors.red,
                    active: false,
                    onTap: _leaveRoom,
                  ),
                ],
              ),
      ),
    );
  }
}

// -- Widgets ---------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatusBadge(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      ]),
    );
  }
}

class _AnchorSeat extends StatelessWidget {
  final Participant participant;
  const _AnchorSeat({required this.participant});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 55, height: 55,
                decoration: BoxDecoration(
                  color: participant.isHost ? Colors.amber.shade700 : Colors.deepPurple,
                  shape: BoxShape.circle,
                  border: participant.isSpeaking
                      ? Border.all(color: Colors.green, width: 3)
                      : null,
                ),
                child: Icon(participant.isHost ? Icons.star : Icons.person,
                    color: Colors.white, size: 24),
              ),
              if (participant.isSpeaking)
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 14, height: 14,
                    decoration: const BoxDecoration(
                        color: Colors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.mic, size: 8, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(participant.userId.length > 8
                  ? '${participant.userId.substring(0, 6)}..'
                  : participant.userId,
              style: const TextStyle(fontSize: 10, color: Colors.black87),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('${participant.volume}',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _AudienceTile extends StatelessWidget {
  final Participant participant;
  const _AudienceTile({required this.participant});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey.shade300,
        child: const Icon(Icons.person, size: 16, color: Colors.white),
      ),
      title: Text(participant.userId,
          style: const TextStyle(fontSize: 13)),
      trailing: Icon(Icons.headset_mic, size: 16, color: Colors.grey.shade400),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _CtrlBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.15) : Colors.grey.shade200,
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
      ]),
    );
  }
}
