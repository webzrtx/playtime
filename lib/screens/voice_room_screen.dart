import 'package:flutter/material.dart';
import '../services/trtc_service.dart';
import '../config/trtc_config.dart';

/// Voice room screen with real TRTC voice chat
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
  bool _isInitialized = false;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isHandRaised = false;
  String _roomId = '';
  String _userId = '';
  String? _error;

  final List<_Participant> _participants = [];

  @override
  void initState() {
    super.initState();
    _roomId = widget.roomId ?? TRTCConfig.defaultRoomId.toString();
    _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    
    // Add self to participants (mock for now)
    _participants.add(_Participant(
      name: _userId,
      isHost: widget.isHost,
      isSpeaking: true,
      avatarColor: Colors.deepPurple,
    ));
    
    // Mark as initialized (TRTC will be inited when user taps join)
    setState(() => _isInitialized = true);
  }

  Future<void> _initTRTC() async {
    try {
      await _trtc.initialize(
        sdkAppId: TRTCConfig.sdkAppId,
        secretKey: TRTCConfig.secretKey,
      );

      if (widget.isHost) {
        await _trtc.createRoom(roomId: _roomId, userId: _userId);
      } else {
        await _trtc.joinRoom(roomId: _roomId, userId: _userId);
      }
    } catch (e) {
      debugPrint('TRTC error: $e');
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _trtc.leaveRoom();
    super.dispose();
  }

  void _toggleMute() async {
    await _trtc.toggleMute();
    setState(() => _isMuted = _trtc.isMuted);
  }

  void _toggleSpeaker() async {
    await _trtc.toggleSpeaker();
    setState(() => _isSpeakerOn = _trtc.isSpeakerOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Room $_roomId'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            _trtc.leaveRoom();
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Room info
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text('${_participants.length}/10', style: TextStyle(color: Colors.green.shade700)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Voice Chat Ready', style: TextStyle(color: Colors.deepPurple.shade700)),
                  ),
                ],
              ),
            ),

            // Error message
            if (_error != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              ),

            // Participants grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: _participants.length,
                itemBuilder: (context, index) {
                  final participant = _participants[index];
                  return _ParticipantCard(participant: participant);
                },
              ),
            ),

            // Controls
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      label: _isMuted ? 'Unmute' : 'Mute',
                      color: _isMuted ? Colors.red : Colors.black,
                      isActive: _isMuted,
                      onTap: _toggleMute,
                    ),
                    _ControlButton(
                      icon: Icons.pan_tool,
                      label: 'Hand',
                      color: _isHandRaised ? Colors.orange : Colors.black,
                      isActive: _isHandRaised,
                      onTap: () => setState(() => _isHandRaised = !_isHandRaised),
                    ),
                    _ControlButton(
                      icon: Icons.call_end,
                      label: 'Leave',
                      color: Colors.red,
                      isActive: false,
                      onTap: () {
                        _trtc.leaveRoom();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Participant {
  final String name;
  final bool isHost;
  final bool isSpeaking;
  final Color avatarColor;

  _Participant({required this.name, required this.isHost, required this.isSpeaking, required this.avatarColor});
}

class _ParticipantCard extends StatelessWidget {
  final _Participant participant;

  const _ParticipantCard({required this.participant});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: participant.avatarColor,
                shape: BoxShape.circle,
                border: participant.isSpeaking ? Border.all(color: Colors.green, width: 3) : null,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 30),
            ),
            if (participant.isHost)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                  child: const Icon(Icons.star, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(participant.name, style: const TextStyle(color: Colors.black, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _ControlButton({required this.icon, required this.label, required this.color, required this.isActive, required this.onTap});

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
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 10)),
        ],
      ),
    );
  }
}