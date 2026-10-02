import 'package:flutter/material.dart';
import 'package:vega_ai/core/constants/app_colors.dart';
import 'package:vega_ai/core/constants/app_dimensions.dart';
import 'package:vega_ai/core/constants/app_strings.dart';
import 'package:vega_ai/core/models/assistant_state.dart';

/// Status badge displaying VEGA AI's current voice state (Idle, Listening, Processing, Speaking).
class StatusBadge extends StatelessWidget {
  final AssistantStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (status) {
      case AssistantStatus.idle:
        badgeColor = AppColors.idleGlow;
        badgeText = AppStrings.badgeIdle;
        badgeIcon = Icons.radio_button_checked_rounded;
        break;
      case AssistantStatus.listening:
        badgeColor = AppColors.primaryPink;
        badgeText = AppStrings.badgeListening;
        badgeIcon = Icons.mic_rounded;
        break;
      case AssistantStatus.processing:
        badgeColor = AppColors.processingGlow;
        badgeText = AppStrings.badgeProcessing;
        badgeIcon = Icons.hourglass_top_rounded;
        break;
      case AssistantStatus.speaking:
        badgeColor = AppColors.speakingWave;
        badgeText = AppStrings.badgeSpeaking;
        badgeIcon = Icons.volume_up_rounded;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.14),
        borderRadius: AppDimensions.roundedFull,
        border: Border.all(
          color: badgeColor.withOpacity(0.45),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: 13,
            color: badgeColor,
          ),
          const SizedBox(width: 6),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: badgeColor,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
