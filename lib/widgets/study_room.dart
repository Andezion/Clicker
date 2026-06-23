import 'package:flutter/material.dart';
import '../model/game_state.dart';

class StudyRoom extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onTap;

  const StudyRoom({
    super.key,
    required this.gameState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1a1a2e),
              const Color(0xFF16213e),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.indigo.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: CustomPaint(
                  painter: RoomBackgroundPainter(),
                ),
              ),
            ),
            ..._buildPurchasedItems(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.95, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeInOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: const Text(
                      '🧑‍🎓',
                      style: TextStyle(fontSize: 80),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text(
                      'TAP TO STUDY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 15,
              left: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade700,
                      Colors.purple.shade900,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Text(
                  '${_getEducationEmoji()} ${gameState.educationLevel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPurchasedItems() {
    List<Widget> items = [];

    if ((gameState.upgrades['laptop'] ?? 0) > 0) {
      items.add(
        Positioned(
          top: 60,
          left: 30,
          child: _AnimatedItem(
            emoji: '💻',
            level: gameState.upgrades['laptop']!,
          ),
        ),
      );
    }

    if ((gameState.upgrades['coffee'] ?? 0) > 0) {
      items.add(
        Positioned(
          top: 60,
          right: 30,
          child: _AnimatedItem(
            emoji: '☕',
            level: gameState.upgrades['coffee']!,
            animated: true,
          ),
        ),
      );
    }

    if ((gameState.upgrades['friend'] ?? 0) > 0) {
      items.add(
        Positioned(
          bottom: 40,
          left: 30,
          child: _AnimatedItem(
            emoji: '👥',
            level: gameState.upgrades['friend']!,
          ),
        ),
      );
    }

    if ((gameState.upgrades['tutor'] ?? 0) > 0) {
      items.add(
        Positioned(
          bottom: 40,
          right: 30,
          child: _AnimatedItem(
            emoji: '🧑‍🏫',
            level: gameState.upgrades['tutor']!,
          ),
        ),
      );
    }

    if ((gameState.upgrades['dissertation'] ?? 0) > 0) {
      items.add(
        Positioned(
          top: 120,
          left: 50,
          child: _AnimatedItem(
            emoji: '📄',
            level: gameState.upgrades['dissertation']!,
          ),
        ),
      );
    }

    if ((gameState.upgrades['scientificArticle'] ?? 0) > 0) {
      items.add(
        Positioned(
          top: 120,
          right: 50,
          child: _AnimatedItem(
            emoji: '📰',
            level: gameState.upgrades['scientificArticle']!,
          ),
        ),
      );
    }

    if ((gameState.upgrades['laboratory'] ?? 0) > 0) {
      items.add(
        Positioned(
          bottom: 100,
          left: 50,
          child: _AnimatedItem(
            emoji: '🔬',
            level: gameState.upgrades['laboratory']!,
          ),
        ),
      );
    }

    return items;
  }

  String _getEducationEmoji() {
    switch (gameState.educationLevel) {
      case 'Bachelor':
        return '🎓';
      case 'Master':
        return '📚';
      case 'PhD':
        return '🔬';
      case 'Professor':
        return '👨‍🏫';
      default:
        return '🎓';
    }
  }
}

class _AnimatedItem extends StatefulWidget {
  final String emoji;
  final int level;
  final bool animated;

  const _AnimatedItem({
    required this.emoji,
    required this.level,
    this.animated = false,
  });

  @override
  State<_AnimatedItem> createState() => _AnimatedItemState();
}

class _AnimatedItemState extends State<_AnimatedItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.animated) {
      _controller = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      )..repeat(reverse: true);
    } else {
      _controller = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widget.animated
            ? AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -5 * _controller.value),
                    child: child,
                  );
                },
                child: Text(
                  widget.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
              )
            : Text(
                widget.emoji,
                style: const TextStyle(fontSize: 40),
              ),
        if (widget.level > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Lv.${widget.level}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

class RoomBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
