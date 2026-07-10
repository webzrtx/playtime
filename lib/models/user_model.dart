import 'package:flutter/material.dart';

/// Model representing a user/player in the app
class UserModel extends ChangeNotifier {
  String _id = '';
  String _username = '';
  String _avatarUrl = '';
  bool _isOnline = false;
  int _level = 1;
  int _coins = 100;
  List<String> _friends = [];
  String _status = 'offline';

  String get id => _id;
  String get username => _username;
  String get avatarUrl => _avatarUrl;
  bool get isOnline => _isOnline;
  int get level => _level;
  int get coins => _coins;
  List<String> get friends => _friends;
  String get status => _status;

  void setUser({
    required String id,
    required String username,
    String avatarUrl = '',
    bool isOnline = true,
    int level = 1,
    int coins = 100,
  }) {
    _id = id;
    _username = username;
    _avatarUrl = avatarUrl;
    _isOnline = isOnline;
    _level = level;
    _coins = coins;
    _status = isOnline ? 'online' : 'offline';
    notifyListeners();
  }

  void updateUsername(String username) {
    _username = username;
    notifyListeners();
  }

  void updateAvatar(String avatarUrl) {
    _avatarUrl = avatarUrl;
    notifyListeners();
  }

  void addCoins(int amount) {
    _coins += amount;
    notifyListeners();
  }

  void spendCoins(int amount) {
    if (_coins >= amount) {
      _coins -= amount;
      notifyListeners();
    }
  }

  void levelUp() {
    _level++;
    notifyListeners();
  }

  void setOnlineStatus(bool isOnline) {
    _isOnline = isOnline;
    _status = isOnline ? 'online' : 'offline';
    notifyListeners();
  }

  void addFriend(String userId) {
    if (!_friends.contains(userId)) {
      _friends.add(userId);
      notifyListeners();
    }
  }

  void removeFriend(String userId) {
    _friends.remove(userId);
    notifyListeners();
  }

  void logout() {
    _id = '';
    _username = '';
    _avatarUrl = '';
    _isOnline = false;
    _status = 'offline';
    _friends = [];
    notifyListeners();
  }
}