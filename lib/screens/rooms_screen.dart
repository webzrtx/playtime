import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/room_model.dart';
import 'voice_room_screen.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  String _selectedFilter = 'All';

  void _createAndEnterRoom(String name) {
    final roomModel = Provider.of<RoomModel>(context, listen: false);
    final room = roomModel.createRoom(
      id: const Uuid().v4().substring(0, 8),
      name: name,
      hostId: 'self',
      hostName: 'You',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceRoomScreen(roomId: room.id, isHost: true),
      ),
    );
  }

  void _joinRoom(Room room) {
    if (room.isFull) return;
    Provider.of<RoomModel>(context, listen: false).joinRoom(room.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceRoomScreen(roomId: room.id, isHost: false),
      ),
    );
  }

  void _showCreateDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Create Room', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Room name',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                _createAndEnterRoom(name);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rooms = Provider.of<RoomModel>(context).rooms;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Voice Rooms', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1A2E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: const Color(0xFF1A1A2E),
        child: Column(
          children: [
            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: ['All', 'Public', 'Gaming', 'Music'].map((f) {
                  final sel = _selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f),
                      selected: sel,
                      onSelected: (_) => setState(() => _selectedFilter = f),
                      backgroundColor: Colors.white.withOpacity(0.1),
                      selectedColor: Colors.deepPurple,
                      labelStyle: TextStyle(
                          color: sel ? Colors.white : Colors.white70),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Room list
            Expanded(
              child: rooms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic_none,
                              size: 48, color: Colors.white.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          Text('No rooms yet',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Tap + to create one',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: rooms.length,
                      itemBuilder: (_, i) => _RoomCard(
                        room: rooms[i],
                        onTap: () => _joinRoom(rooms[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback onTap;

  const _RoomCard({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(room.icon, color: Colors.deepPurple),
        ),
        title: Text(room.name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text('${room.hostName} • ${room.gameType}',
            style: TextStyle(color: Colors.white.withOpacity(0.6))),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: room.isFull
                ? Colors.red.withOpacity(0.3)
                : Colors.green.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('${room.participantCount}/${room.maxSeats}',
              style: TextStyle(
                  color: room.isFull ? Colors.red : Colors.green,
                  fontSize: 12)),
        ),
        onTap: room.isFull ? null : onTap,
      ),
    );
  }
}
