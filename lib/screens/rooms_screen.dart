import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room_model.dart';

/// Screen showing list of voice rooms
class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RoomModel>(context, listen: false).loadRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rooms = Provider.of<RoomModel>(context).rooms;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Rooms', style: TextStyle(color: Colors.white)),
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
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search rooms...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),

            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['All', 'Public', 'Private', 'Gaming', 'Music'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) => setState(() => _selectedFilter = filter),
                      backgroundColor: Colors.white.withOpacity(0.1),
                      selectedColor: Colors.deepPurple,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Room list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  return _RoomListItem(room: room);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () {
          _showCreateRoomDialog(context);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showCreateRoomDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Create Room', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Room name',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              // Create room logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Room created!')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _RoomListItem extends StatelessWidget {
  final Room room;

  const _RoomListItem({required this.room});

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
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(room.icon, color: Colors.deepPurple),
        ),
        title: Text(
          room.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${room.hostName} • ${room.gameType}',
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: room.isFull ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${room.currentPlayers}/${room.maxPlayers}',
                style: TextStyle(
                  color: room.isFull ? Colors.red : Colors.green,
                  fontSize: 12,
                ),
              ),
            ),
            if (room.isPrivate)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(Icons.lock, size: 14, color: Colors.white.withOpacity(0.5)),
              ),
          ],
        ),
        onTap: () {
          if (!room.isFull) {
            Navigator.pushNamed(context, '/voice-room');
          }
        },
      ),
    );
  }
}