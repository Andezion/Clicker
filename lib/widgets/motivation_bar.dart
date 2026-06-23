import 'package:flutter/material.dart';
import '../service/motivation_service.dart';

class MotivationBar extends StatelessWidget {
  final double motivation;
  final VoidCallback? onBoostTap;

  const MotivationBar({
    super.key,
    required this.motivation,
    this.onBoostTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = MotivationService.getMotivationStatus(motivation);
    final color = _getMotivationColor(motivation);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a4e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Motivation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (onBoostTap != null && motivation < 80)
                ElevatedButton.icon(
                  onPressed: onBoostTap,
                  label: const Text('Boost',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: motivation / 100,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.7), color],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Container(
                height: 20,
                alignment: Alignment.center,
                child: Text(
                  '${motivation.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (motivation < 50)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Low motivation = ${(motivation.toInt())}% income!',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getMotivationColor(double motivation) {
    if (motivation >= 80) return Colors.green;
    if (motivation >= 60) return Colors.lightGreen;
    if (motivation >= 40) return Colors.orange;
    if (motivation >= 20) return Colors.deepOrange;
    return Colors.red;
  }
}
