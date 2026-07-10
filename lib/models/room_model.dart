import 'package:flutter/material.dart';

/// Model representing a voice room
class RoomModel extends ChangeNotifier {
  List<Room> _rooms = [];
  Room? _currentRoom;

  List<Room> get rooms => _rooms;
  Room? get currentRoom => _currentRoom;

  void loadRooms() {
    // Sample rooms data
    _rooms = [
      Room(
        id: '1',
        name: 'Gaming Lounge',
        hostId: 'user1',
        hostName: 'ProGamer',
        currentPlayers: 8,
        maxPlayers: 10,
        isPrivate: false,
        gameType: 'Free Chat',
        language: 'EN',
        icon: Icons.headphones,
      ),
      Room(
        id: '2',
        name: 'Valorant Squad',
        hostId: 'user2',
        hostName: 'SniperQueen',
        currentPlayers: 5,
        maxPlayers: 5,
        isPrivate: false,
        gameType: 'Valorant',
        language: 'FR',
        icon: Icons.sports_esports,
      ),
      Room(
        id: '3',
        name: 'LoL Ranked Team',
        hostId: 'user3',
        hostName: 'MidLane',
        currentPlayers: 4,
        maxPlayers: 5,
        isPrivate: true,
        gameType: 'League of Legends',
        language: 'EN',
        icon: Icons.sports_esports,
      ),
      Room(
        id: '4',
        name: 'Chill Music Room',
        hostId: 'user4',
        hostName: 'MusicLover',
        currentPlayers: 12,
        maxPlayers: 20,
        isPrivate: false,
        gameType: 'Music',
        language: 'KO',
        icon: Icons.music_note,
      ),
    ];
    notifyListeners();
  }

  void joinRoom(String roomId) {
    _currentRoom = _rooms.firstWhere((r) => r.id == roomId);
    notifyListeners();
  }

  void leaveRoom() {
    _currentRoom = null;
    notifyListeners();
  }

  void createRoom(Room room) {
    _rooms.add(room);
    _currentRoom = room;
    notifyListeners();
  }
}

class Room {
  final String id;
  final String name;
  final String hostId;
  final String hostName;
  final int currentPlayers;
  final int maxPlayers;
  final bool isPrivate;
  final String gameType;
  final String language;
  final IconData icon;

  Room({
    required this.id,
    required this.name,
    required this.hostId,
    required this.hostName,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.isPrivate,
    required this.gameType,
    required this.language,
    required this.icon,
  });

  bool get isFull => currentPlayers >= maxPlayers;
  double get occupancy => currentPlayers / maxPlayers;
}