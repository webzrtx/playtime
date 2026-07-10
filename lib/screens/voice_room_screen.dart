import 'package:flutter/material.dart';

/// Voice room screen with participant list and controls
class VoiceRoomScreen extends StatefulWidget {
  const VoiceRoomScreen({super.key});

  @override
  State<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends State<VoiceRoomScreen> {
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isHandRaised = false;

  // Sample participants
  final List<_Participant> _participants = [
    _Participant(name: 'ProGamer', isHost: true, isSpeaking: true, avatarColor: Colors.deepPurple),
    _Participant(name: 'SniperQueen', isHost: false, isSpeaking: false, avatarColor: Colors.pink),
    _Participant(name: 'MidLane', isHost: false, isSpeaking: true, avatarColor: Colors.orange),
    _Participant(name: 'MusicLover', isHost: false, isSpeaking: false, avatarColor: Colors.teal),
    _Participant(name: 'Gamer123', isHost: false, isSpeaking: false, avatarColor: Colors.green),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gaming Lounge', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1A2E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
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
                      color: Colors.green.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.green),
                        SizedBox(width: 4),
                        Text('5/10', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Free Chat', style: TextStyle(color: Colors.deepPurple)),
                  ),
                ],
              ),
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
                color: const Color(0xFF16213E),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute button
                    _ControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      label: _isMuted ? 'Unmute' : 'Mute',
                      color: _isMuted ? Colors.red : Colors.white,
                      isActive: _isMuted,
                      onTap: () => setState(() => _isMuted = !_isMuted),
                    ),
                    // Speaker button
                    _ControlButton(
                      icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                      label: 'Speaker',
                      color: _isSpeakerOn ? Colors.green : Colors.white,
                      isActive: _isSpeakerOn,
                      onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                    ),
                    // Raise hand
                    _ControlButton(
                      icon: Icons.pan_tool,
                      label: 'Hand',
                      color: _isHandRaised ? Colors.orange : Colors.white,
                      isActive: _isHandRaised,
                      onTap: () => setState(() => _isHandRaised = !_isHandRaised),
                    ),
                    // Leave room
                    _ControlButton(
                      icon: Icons.call_end,
                      label: 'Leave',
                      color: Colors.red,
                      isActive: false,
                      onTap: () => Navigator.pop(context),
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

  _Participant({
    required this.name,
    required this.isHost,
    required this.isSpeaking,
    required this.avatarColor,
  });
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
                border: participant.isSpeaking
                    ? Border.all(color: Colors.green, width: 3)
                    : null,
                boxShadow: participant.isSpeaking
                    ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 30),
            ),
            if (participant.isHost)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          participant.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
              color: isActive ? color.withOpacity(0.2) : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10),
          ),
        ],
      ),
    );
  }
}