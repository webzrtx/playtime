import 'package:flutter/material.dart';

class Room {
  final String id;
  final String name;
  final String hostId;
  final String hostName;
  final int maxSeats;
  final bool isPrivate;
  final String gameType;
  final String language;
  final IconData icon;
  int _participantCount;

  Room({
    required this.id,
    required this.name,
    required this.hostId,
    required this.hostName,
    this.maxSeats = 10,
    this.isPrivate = false,
    this.gameType = 'Voice Chat',
    this.language = 'EN',
    this.icon = Icons.headphones,
    int participantCount = 1,
  }) : _participantCount = participantCount;

  int get participantCount => _participantCount;
  bool get isFull => _participantCount >= maxSeats;

  void incrementParticipants() => _participantCount++;
  void decrementParticipants() {
    if (_participantCount > 0) _participantCount--;
  }
}

class RoomModel extends ChangeNotifier {
  final List<Room> _rooms = [];
  Room? _currentRoom;

  List<Room> get rooms => List.unmodifiable(_rooms);
  Room? get currentRoom => _currentRoom;

  /// No-op: rooms are created/joined dynamically, not preloaded.
  void loadRooms() {}

  /// Create a new room and add it to the list.
  Room createRoom({
    required String id,
    required String name,
    required String hostId,
    required String hostName,
  }) {
    final room = Room(
      id: id,
      name: name,
      hostId: hostId,
      hostName: hostName,
    );
    _rooms.insert(0, room);
    _currentRoom = room;
    notifyListeners();
    return room;
  }

  /// Join an existing room by ID.
  Room? joinRoom(String roomId) {
    _currentRoom = _rooms.firstWhere(
      (r) => r.id == roomId,
      orElse: () => _rooms.first, // fallback
    );
    _currentRoom?.incrementParticipants();
    notifyListeners();
    return _currentRoom;
  }

  /// Leave the current room.
  void leaveRoom() {
    _currentRoom?.decrementParticipants();
    _currentRoom = null;
    notifyListeners();
  }

  /// Remove room from list (host left or room ended).
  void removeRoom(String roomId) {
    _rooms.removeWhere((r) => r.id == roomId);
    if (_currentRoom?.id == roomId) _currentRoom = null;
    notifyListeners();
  }
}
