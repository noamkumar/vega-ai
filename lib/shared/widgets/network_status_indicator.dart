import 'package:flutter/material.dart';
import 'package:vega_ai/core/constants/app_colors.dart';
import 'package:vega_ai/core/constants/app_dimensions.dart';
import 'package:vega_ai/core/constants/app_strings.dart';

/// Interactive Online/Offline status pill indicator.
class NetworkStatusIndicator extends StatelessWidget {
  final bool isOnline;
  final VoidCallback? onTap;

  const NetworkStatusIndicator({
    super.key,
    required this.isOnline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = isOnline ? AppColors.onlineGreen : AppColors.offlineOrange;
    final label = isOnline ? AppStrings.onlineBadge : AppStrings.offlineBadge;
    final detail = isOnline ? AppStrings.modeOnline : AppStrings.modeOffline;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimensions.roundedFull,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDarkSubtle.withOpacity(0.9)
                : AppColors.surfaceLight.withOpacity(0.9),
            borderRadius: AppDimensions.roundedFull,
            border: Border.all(
              color: statusColor.withOpacity(0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppDimensions.indicatorDot,
                height: AppDimensions.indicatorDot,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.6),
                      blurRadius: 6,
                      spreadRadius: 1.5,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '• $detail',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
