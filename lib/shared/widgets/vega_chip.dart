import 'package:flutter/material.dart';
import 'package:vega_ai/core/constants/app_colors.dart';
import 'package:vega_ai/core/constants/app_dimensions.dart';

/// Reusable intent and filter chip with lavender & pink accents.
class VegaChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? activeColor;

  const VegaChip({
    super.key,
    required this.label,
    this.icon,
    this.isSelected = false,
    this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = activeColor ?? AppColors.primaryPink;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimensions.roundedFull,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryAccent.withOpacity(0.18)
                : (isDark ? AppColors.surfaceDarkSubtle : AppColors.surfaceLightSubtle),
            borderRadius: AppDimensions.roundedFull,
            border: Border.all(
              color: isSelected
                  ? primaryAccent
                  : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: isSelected
                      ? primaryAccent
                      : (isDark ? AppColors.lavender : AppColors.primaryPink),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? primaryAccent
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
