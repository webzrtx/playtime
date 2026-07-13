import 'package:flutter/material.dart';

/// Simple avatar widget — shows first letter of name in a colored circle.
/// Consistent color per userId.
class UserAvatar extends StatelessWidget {
  final String userId;
  final String displayName;
  final double size;

  const UserAvatar({
    super.key,
    required this.userId,
    this.displayName = '',
    this.size = 36,
  });

  static Color colorForId(String id) {
    final colors = [
      const Color(0xFFFE6484), // pink
      const Color(0xFF00CCF9), // cyan
      const Color(0xFFF6AD1B), // gold
      const Color(0xFF9B59B6), // purple
      const Color(0xFF2ECC71), // green
      const Color(0xFFE74C3C), // red
      const Color(0xFF3498DB), // blue
      const Color(0xFF1ABC9C), // teal
    ];
    return colors[id.hashCode.abs() % colors.length];
  }

  String _initial(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorForId(userId),
      ),
      alignment: Alignment.center,
      child: Text(
        _initial(displayName),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
