import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_model.dart';

/// Screen showing available party games
class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GameModel>(context, listen: false).loadGames();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameModel = Provider.of<GameModel>(context);
    final allGames = gameModel.games;
    
    final filteredGames = _selectedCategory == 'All'
        ? allGames
        : allGames.where((g) => g.category.name == _selectedCategory.toLowerCase()).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Party Games', style: TextStyle(color: Colors.white)),
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
            // Category filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: ['All', 'Social Deduction', 'Drawing', 'Music', 'Word'].map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) => setState(() => _selectedCategory = category),
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

            // Games count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${filteredGames.length} games available',
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Games grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: filteredGames.length,
                itemBuilder: (context, index) {
                  final game = filteredGames[index];
                  return _GameCard(game: game);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final Game game;

  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showGameDetails(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: game.color.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: game.color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Game icon
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: game.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(game.icon, color: game.color, size: 35),
            ),
            const SizedBox(height: 16),
            
            // Game name
            Text(
              game.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            
            // Description
            Text(
              game.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            
            // Player count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: game.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                game.playerRange,
                style: TextStyle(color: game.color, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGameDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: game.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(game.icon, color: game.color, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              game.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              game.description,
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _InfoChip(icon: Icons.people, label: game.playerRange),
                const SizedBox(width: 12),
                _InfoChip(icon: Icons.category, label: game.category.name),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: game.color,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Starting ${game.name}...')),
                  );
                },
                child: const Text('Start Game'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}