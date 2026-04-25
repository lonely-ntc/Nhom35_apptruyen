import 'package:flutter/material.dart';
import '../utils/app_styles.dart';

/// 🏷️ ANIMATED BADGE
class AnimatedBadge extends StatefulWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const AnimatedBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  @override
  State<AnimatedBadge> createState() => _AnimatedBadgeState();
}

class _AnimatedBadgeState extends State<AnimatedBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.space12,
          vertical: AppStyles.space4,
        ),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          border: Border.all(
            color: widget.color,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon,
                size: 14,
                color: widget.color,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              widget.text,
              style: TextStyle(
                color: widget.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
