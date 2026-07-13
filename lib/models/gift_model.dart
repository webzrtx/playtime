import 'package:flutter/material.dart';

/// A gift that can be sent in a voice room.
class GiftItem {
  final String id;
  final String label;
  final String emoji;
  final Color color;

  const GiftItem({
    required this.id,
    required this.label,
    required this.emoji,
    required this.color,
  });
}

/// Available gifts (WePlay-style).
const kGiftList = [
  GiftItem(id: 'heart', label: 'Heart', emoji: '❤️', color: Color(0xFFFE6484)),
  GiftItem(id: 'rose', label: 'Rose', emoji: '🌹', color: Color(0xFFE74C3C)),
  GiftItem(id: 'rocket', label: 'Rocket', emoji: '🚀', color: Color(0xFFF6AD1B)),
  GiftItem(id: 'crown', label: 'Crown', emoji: '👑', color: Color(0xFFFFD700)),
  GiftItem(id: 'fire', label: 'Fire', emoji: '🔥', color: Color(0xFFFF6B35)),
  GiftItem(id: 'clap', label: 'Clap', emoji: '👏', color: Color(0xFF00CCF9)),
  GiftItem(id: 'laugh', label: 'LOL', emoji: '😂', color: Color(0xFF2ECC71)),
  GiftItem(id: 'star', label: 'Star', emoji: '⭐', color: Color(0xFFF1C40F)),
];
