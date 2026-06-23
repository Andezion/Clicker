import 'package:flutter/material.dart';
import '../model/random_event.dart';

class EventPopup extends StatelessWidget {
  final RandomEvent event;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool canAfford;

  const EventPopup({
    super.key,
    required this.event,
    required this.onAccept,
    required this.onDecline,
    required this.canAfford,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getGradientColors(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getBorderColor(),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: _getBorderColor().withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              event.emoji,
              style: const TextStyle(fontSize: 60),
            ),
            const SizedBox(height: 15),
            Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              event.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildEventDetails(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onDecline,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Decline',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canAfford ? onAccept : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          canAfford ? _getButtonColor() : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(_getAcceptText(),
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            if (!canAfford)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'You can\'t afford this!',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetails() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          if (event.ectsCost != 0)
            _detailRow(
              event.ectsCost > 0 ? 'Cost' : 'Reward',
              '${event.ectsCost > 0 ? '-' : '+'}${event.ectsCost.abs().toStringAsFixed(0)} ECTS',
              event.ectsCost > 0 ? Colors.red : Colors.green,
            ),
          if (event.motivationChange != 0)
            _detailRow(
              event.motivationChange > 0 ? 'Motivation' : 'Motivation',
              '${event.motivationChange > 0 ? '+' : ''}${event.motivationChange.toStringAsFixed(0)}%',
              event.motivationChange > 0 ? Colors.green : Colors.orange,
            ),
          if (event.duration != null)
            _detailRow(
              'Duration',
              '${event.duration!.inMinutes} min',
              Colors.blue,
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getGradientColors() {
    switch (event.type) {
      case EventType.positive:
        return [Colors.green.shade700, Colors.green.shade900];
      case EventType.negative:
        return [Colors.red.shade700, Colors.red.shade900];
      case EventType.neutral:
        return [Colors.blue.shade700, Colors.blue.shade900];
    }
  }

  Color _getBorderColor() {
    switch (event.type) {
      case EventType.positive:
        return Colors.greenAccent;
      case EventType.negative:
        return Colors.redAccent;
      case EventType.neutral:
        return Colors.blueAccent;
    }
  }

  Color _getButtonColor() {
    switch (event.type) {
      case EventType.positive:
        return Colors.green;
      case EventType.negative:
        return Colors.red.shade700;
      case EventType.neutral:
        return Colors.blue;
    }
  }

  String _getAcceptText() {
    switch (event.type) {
      case EventType.positive:
        return 'Accept';
      case EventType.negative:
        return 'Pay';
      case EventType.neutral:
        return 'Go!';
    }
  }
}
