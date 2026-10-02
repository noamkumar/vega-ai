import 'package:flutter/material.dart';
import 'package:vega_ai/core/constants/app_colors.dart';
import 'package:vega_ai/core/constants/app_dimensions.dart';
import 'package:vega_ai/core/models/assistant_state.dart';
import 'package:vega_ai/shared/widgets/vega_card.dart';

/// Interactive card that displays live voice transcript and assistant responses.
class TranscriptCard extends StatelessWidget {
  final AssistantStatus status;
  final String transcript;
  final String responseText;

  const TranscriptCard({
    super.key,
    required this.status,
    required this.transcript,
    required this.responseText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isCapturing = status.isListening || status.isProcessing;
    final displayText = isCapturing ? transcript : responseText;
    final headerLabel = isCapturing ? 'VOICE INPUT' : 'VEGA SYSTEM';

    return VegaCard(
      hasGlow: status.isListening,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                headerLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isCapturing ? AppColors.primaryPink : AppColors.lavenderDark,
                ),
              ),
              const Spacer(),
              if (isCapturing)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryPink,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              displayText,
              key: ValueKey(displayText),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
