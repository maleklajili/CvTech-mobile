import 'package:flutter/material.dart';

class CoinsMiniBarWidget extends StatelessWidget {
  final int balance;
  final int earnedToday;
  final VoidCallback? onEarnMore;

  const CoinsMiniBarWidget({
    super.key,
    required this.balance,
    this.earnedToday = 0,
    this.onEarnMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFAEEDA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Coin icon
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFBA7517),
              ),
              child: const Center(
                child: Text(
                  '⭐',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Balance text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$balance coins',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF412402),
                    ),
                  ),
                  if (earnedToday > 0)
                    Text(
                      '+$earnedToday aujourd\'hui',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF854F0B),
                      ),
                    ),
                ],
              ),
            ),
            // Earn button
            GestureDetector(
              onTap: onEarnMore,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAC775),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'Gagner +',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF633806),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
