import 'package:flutter/material.dart';
import '../utils/app_styles.dart';

/// 🏷️ CATEGORY CHIP
class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppStyles.durationNormal,
        curve: AppStyles.curveDefault,
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.space16,
          vertical: AppStyles.space8,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [chipColor, chipColor.withOpacity(0.7)],
                )
              : null,
          color: isSelected ? null : theme.cardColor,
          borderRadius: BorderRadius.circular(AppStyles.radiusCircle),
          border: Border.all(
            color: isSelected ? chipColor : theme.dividerColor,
            width: isSelected ? 0 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: chipColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
