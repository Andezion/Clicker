import 'package:flutter/material.dart';
import '../model/upgrade.dart';
import '../utils/formatters.dart';

class UpgradeCard extends StatelessWidget {
  final Upgrade upgrade;
  final int currentLevel;
  final double currentCurrency;
  final VoidCallback onBuy;

  const UpgradeCard({
    super.key,
    required this.upgrade,
    required this.currentLevel,
    required this.currentCurrency,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final price = upgrade.getPrice(currentLevel);
    final canAfford = currentCurrency >= price;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a4e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: canAfford
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Text(upgrade.emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  upgrade.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  upgrade.description,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 5),
                Text(
                  'Level: $currentLevel | ${upgrade.effect}',
                  style: const TextStyle(color: Colors.amber, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: canAfford ? onBuy : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canAfford ? Colors.blue : Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              '${Formatters.formatPrice(price)} tokens',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
