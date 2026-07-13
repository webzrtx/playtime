import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/trtc_service.dart';
import '../config/trtc_config.dart';

/// Voice room screen — real TRTC voice chat.
/// Host uses [isHost]=true to create the room; guests join with [isHost]=false.
class VoiceRoomScreen extends StatefulWidget {
  final String? roomId;
  final bool isHost;

  const VoiceRoomScreen({
    super.key,
    this.roomId,
    this.isHost = false,
  });

  @override
  State<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends State<VoiceRoomScreen> {
  final TRTCService _trtc = TRTCService();
  bool _isJoined = false;
  bool _isHandRaised = false;

  String get _roomId => widget.roomId ?? TRTCConfig.defaultRoomId.toString();
  String get _userId =>
      'user_${DateTime.now().millisecondsSinceEpoch.remainder(100000)}';

  @override
  void initState() {
    super.initState();
    _initAndEnter();
  }

  Future<void> _initAndEnter() async {
    // Request microphone permission first
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        setState(() => _isJoined = true); // show UI with error
      }
      return;
    }

    try {
      await _trtc.initialize();

      if (widget.isHost) {
        await _trtc.createRoom(roomId: _roomId, userId: _userId);
      } else {
        await _trtc.joinRoom(roomId: _roomId, userId: _userId);
      }

      _trtc.addListener(_onServiceUpdate);
      if (mounted) setState(() => _isJoined = true);
    } catch (e) {
      debugPrint('TRTC init error: $e');
      _trtc.addListener(_onServiceUpdate);
      if (mounted) setState(() => _isJoined = true); // show UI anyway
    }
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _leaveRoom() async {
    await _trtc.leaveRoom();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _trtc.removeListener(_onServiceUpdate);
    _trtc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final participants = widget.isHost
        ? _trtc.participants
        : _trtc.participants;

    return Scaffold(
      appBar: AppBar(
        title:
            Text('Room $_roomId', style: const TextStyle(color: Colors.black)),
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
            // Status bar
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people,
                            size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text('${participants.length}/10',
                            style: TextStyle(color: Colors.green.shade700)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isJoined
                          ? Colors.deepPurple.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isJoined ? 'Live' : 'Connecting...',
                      style: TextStyle(
                        color: _isJoined
                            ? Colors.deepPurple.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ),
                  if (_trtc.lastError != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _trtc.lastError!,
                        style:
                            TextStyle(color: Colors.red.shade700, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Error banner
            if (_trtc.lastError != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('⚠ ${_trtc.lastError}',
                    style: TextStyle(color: Colors.red.shade700)),
              ),

            // Participant grid
            Expanded(
              child: participants.isEmpty
                  ? Center(
                      child: Text('Waiting for participants...',
                          style: TextStyle(color: Colors.grey.shade400)),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: participants.length,
                      itemBuilder: (context, index) {
                        final p = participants[index];
                        return _ParticipantCard(
                          userId: p.userId,
                          isHost: index == 0,
                          isSpeaking: p.isSpeaking,
                          volume: p.volume,
                        );
                      },
                    ),
            ),

            // Bottom controls
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.grey.shade100,
              child: SafeArea(
                child: _isJoined
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ControlButton(
                            icon: _trtc.isMuted ? Icons.mic_off : Icons.mic,
                            label: _trtc.isMuted ? 'Unmute' : 'Mute',
                            color:
                                _trtc.isMuted ? Colors.red : Colors.black,
                            isActive: _trtc.isMuted,
                            onTap: () => _trtc.toggleMute(),
                          ),
                          _ControlButton(
                            icon: Icons.volume_up,
                            label: _trtc.isSpeakerOn ? 'Speaker' : 'Earpiece',
                            color: Colors.black,
                            isActive: _trtc.isSpeakerOn,
                            onTap: () => _trtc.toggleSpeaker(),
                          ),
                          _ControlButton(
                            icon: Icons.pan_tool,
                            label: 'Hand',
                            color: _isHandRaised
                                ? Colors.orange
                                : Colors.black,
                            isActive: _isHandRaised,
                            onTap: () =>
                                setState(() => _isHandRaised = !_isHandRaised),
                          ),
                          _ControlButton(
                            icon: Icons.call_end,
                            label: 'Leave',
                            color: Colors.red,
                            isActive: false,
                            onTap: _leaveRoom,
                          ),
                        ],
                      )
                    : ElevatedButton(
                        onPressed: _initAndEnter,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Join Voice Room',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single participant card showing avatar + speaking indicator.
class _ParticipantCard extends StatelessWidget {
  final String userId;
  final bool isHost;
  final bool isSpeaking;
  final int volume;

  const _ParticipantCard({
    required this.userId,
    required this.isHost,
    required this.isSpeaking,
    required this.volume,
  });

  Color _avatarColor(String id) {
    final colors = [
      Colors.deepPurple,
      Colors.pink,
      Colors.blue,
      Colors.orange,
      Colors.teal,
      Colors.indigo,
    ];
    return colors[id.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(userId);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSpeaking
                    ? Border.all(color: Colors.green, width: 3)
                    : null,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 30),
            ),
            if (isHost)
              const Positioned(
                right: 0,
                bottom: 0,
                child: Icon(Icons.star, size: 14, color: Colors.amber),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          userId,
          style: const TextStyle(color: Colors.black, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '$volume',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
        ),
      ],
    );
  }
}

/// Circular control button used in bottom bar.
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isActive ? color.withOpacity(0.2) : Colors.grey.shade200,
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 10)),
        ],
      ),
    );
  }
}
