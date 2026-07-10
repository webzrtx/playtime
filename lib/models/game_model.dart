import 'package:flutter/material.dart';

/// Model representing available games in the app
class GameModel extends ChangeNotifier {
  List<Game> _games = [];
  Game? _currentGame;

  List<Game> get games => _games;
  Game? get currentGame => _currentGame;

  void loadGames() {
    _games = [
      Game(
        id: '1',
        name: 'Civilians vs Killers',
        description: 'Social deduction game. Find the killers among us!',
        minPlayers: 4,
        maxPlayers: 16,
        icon: Icons.groups,
        color: Colors.red,
        category: GameCategory.socialDeduction,
      ),
      Game(
        id: '2',
        name: 'Draw & Guess',
        description: 'Draw to guess! Team up and be creative.',
        minPlayers: 3,
        maxPlayers: 12,
        icon: Icons.brush,
        color: Colors.blue,
        category: GameCategory.drawing,
      ),
      Game(
        id: '3',
        name: 'Who\'s the Spy',
        description: 'Find the spy without being caught!',
        minPlayers: 4,
        maxPlayers: 12,
        icon: Icons.visibility_off,
        color: Colors.purple,
        category: GameCategory.socialDeduction,
      ),
      Game(
        id: '4',
        name: 'Mic Grab',
        description: 'Grab the mic and sing! Hot songs mode.',
        minPlayers: 2,
        maxPlayers: 8,
        icon: Icons.mic,
        color: Colors.orange,
        category: GameCategory.music,
      ),
      Game(
        id: '5',
        name: 'Word Chain',
        description: 'Chain words together. Don\'t slip up!',
        minPlayers: 2,
        maxPlayers: 10,
        icon: Icons.text_fields,
        color: Colors.green,
        category: GameCategory.word,
      ),
      Game(
        id: '6',
        name: 'Quick Draw',
        description: 'Speed drawing challenge. Draw fast, guess fast!',
        minPlayers: 3,
        maxPlayers: 10,
        icon: Icons.timer,
        color: Colors.teal,
        category: GameCategory.drawing,
      ),
    ];
    notifyListeners();
  }

  void selectGame(String gameId) {
    _currentGame = _games.firstWhere((g) => g.id == gameId);
    notifyListeners();
  }

  void clearSelection() {
    _currentGame = null;
    notifyListeners();
  }

  List<Game> getGamesByCategory(GameCategory category) {
    return _games.where((g) => g.category == category).toList();
  }
}

enum GameCategory {
  socialDeduction,
  drawing,
  music,
  word,
  other,
}

class Game {
  final String id;
  final String name;
  final String description;
  final int minPlayers;
  final int maxPlayers;
  final IconData icon;
  final Color color;
  final GameCategory category;

  Game({
    required this.id,
    required this.name,
    required this.description,
    required this.minPlayers,
    required this.maxPlayers,
    required this.icon,
    required this.color,
    required this.category,
  });

  String get playerRange => '$minPlayers-$maxPlayers players';
}