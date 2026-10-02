import 'package:flutter/material.dart';
import 'package:vega_ai/core/constants/app_colors.dart';
import 'package:vega_ai/core/constants/app_dimensions.dart';

/// Reusable glassmorphic styled card widget with soft pink and lavender borders.
class VegaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool hasGlow;

  const VegaCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.hasGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkSubtle : AppColors.surfaceLight,
        borderRadius: AppDimensions.roundedMd,
        border: Border.all(
          color: hasGlow
              ? AppColors.primaryPink.withOpacity(0.5)
              : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
          width: 1.2,
        ),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: AppColors.primaryPink.withOpacity(0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppDimensions.roundedMd,
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}
