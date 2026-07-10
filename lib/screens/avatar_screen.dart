import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';

/// Avatar customization screen
class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key});

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> {
  int _selectedFace = 0;
  int _selectedHair = 0;
  int _selectedColor = 0;
  
  final List<Color> _hairColors = [
    Colors.black,
    Colors.brown,
    Colors.yellow.shade700,
    Colors.red,
    Colors.blue,
    Colors.pink,
    Colors.purple,
    Colors.green,
  ];

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Avatar', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1A2E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Avatar saved!')),
              );
            },
            child: const Text('Save', style: TextStyle(color: Colors.deepPurple)),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFF1A1A2E),
        child: Column(
          children: [
            // Avatar preview
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  // Avatar circle
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _hairColors[_selectedColor],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.deepPurple, width: 3),
                    ),
                    child: const Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.username,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white24),

            // Customization options
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Face style
                    const Text(
                      'Face Style',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        final isSelected = _selectedFace == index;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFace = index),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.deepPurple : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected ? Border.all(color: Colors.pink, width: 2) : null,
                            ),
                            child: Icon(
                              Icons.face,
                              color: isSelected ? Colors.white : Colors.white54,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    // Hair style
                    const Text(
                      'Hair Style',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        final isSelected = _selectedHair == index;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedHair = index),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.deepPurple : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected ? Border.all(color: Colors.pink, width: 2) : null,
                            ),
                            child: Icon(
                              Icons.face_outlined,
                              color: isSelected ? Colors.white : Colors.white54,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    // Hair color
                    const Text(
                      'Hair Color',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(_hairColors.length, (index) {
                        final isSelected = _selectedColor == index;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = index),
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: _hairColors[index],
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                              boxShadow: isSelected
                                  ? [BoxShadow(color: _hairColors[index], blurRadius: 10)]
                                  : null,
                            ),
                          ),
                        );
                      }),
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