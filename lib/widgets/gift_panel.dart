import 'package:flutter/material.dart';
import '../models/gift_model.dart';

/// Bottom sheet showing available gifts to send.
class GiftPanel extends StatelessWidget {
  final void Function(GiftItem gift) onGiftSelected;

  const GiftPanel({super.key, required this.onGiftSelected});

  static void show(BuildContext context, {required void Function(GiftItem) onSend}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => GiftPanel(onGiftSelected: (gift) {
        onSend(gift);
        Navigator.pop(context);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Send a Gift',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: kGiftList.map((gift) {
              return GestureDetector(
                onTap: () => onGiftSelected(gift),
                child: Container(
                  width: 72, height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: gift.color.withOpacity(0.3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(gift.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(gift.label,
                          style: TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
