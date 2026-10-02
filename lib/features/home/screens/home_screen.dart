import 'package:flutter/material.dart';
import 'package:vega_ai/app/app_router.dart';
import 'package:vega_ai/core/constants/app_colors.dart';
import 'package:vega_ai/core/constants/app_dimensions.dart';
import 'package:vega_ai/core/constants/app_strings.dart';
import 'package:vega_ai/features/assistant/assistant_controller.dart';
import 'package:vega_ai/features/assistant/widgets/status_badge.dart';
import 'package:vega_ai/features/assistant/widgets/transcript_card.dart';
import 'package:vega_ai/features/assistant/widgets/voice_orb_button.dart';
import 'package:vega_ai/shared/widgets/network_status_indicator.dart';
import 'package:vega_ai/shared/widgets/vega_card.dart';

/// The central home screen for VEGA AI.
///
/// Features the JARVIS-inspired animated orb, live state indicators,
/// real-time transcripts, and quick navigation shortcuts.
class HomeScreen extends StatefulWidget {
  final AssistantController controller;

  const HomeScreen({
    super.key,
    required this.controller,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: AppDimensions.sm,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AppDimensions.md,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // TOP BAR: Branding & Network Indicator
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // VEGA Branding with Gradient
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.brandGradient,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryPink.withOpacity(0.35),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.sm),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (bounds) =>
                                          AppColors.brandGradient.createShader(bounds),
                                      child: const Text(
                                        AppStrings.appName,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'A.I. SYSTEM CORE',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.5,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Online/Offline Pill Indicator
                            NetworkStatusIndicator(
                              isOnline: controller.isOnline,
                              onTap: () => controller.toggleOnlineMode(),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.md),

                        // Status Badge (Idle, Listening, Processing, Speaking)
                        StatusBadge(status: controller.status),
                      ],
                    ),

                    // CENTER: Large Animated Circular Voice Orb & Guidance
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VoiceOrbButton(
                            status: controller.status,
                            onTap: () => controller.activateAssistant(),
                            size: screenHeight < 680 ? 140.0 : AppDimensions.orbSizePhone,
                          ),
                          const SizedBox(height: AppDimensions.md),
                          Text(
                            controller.status.isIdle
                                ? AppStrings.defaultPrompt
                                : (controller.status.isListening
                                    ? AppStrings.promptListening
                                    : AppStrings.promptProcessing),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // BOTTOM AREA: Transcript Card & System Shortcuts
                    Column(
                      children: [
                        // Live Transcript & Assistant Feedback Card
                        TranscriptCard(
                          status: controller.status,
                          transcript: controller.activeTranscript,
                          responseText: controller.assistantResponse,
                        ),
                        const SizedBox(height: AppDimensions.md),

                        // System Navigation Shortcuts
                        Row(
                          children: [
                            Expanded(
                              child: _buildShortcutButton(
                                context: context,
                                icon: Icons.history_rounded,
                                label: 'History',
                                onTap: () =>
                                    Navigator.pushNamed(context, AppRouter.history),
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.sm),
                            Expanded(
                              child: _buildShortcutButton(
                                context: context,
                                icon: Icons.verified_user_outlined,
                                label: 'Approved Apps',
                                onTap: () =>
                                    Navigator.pushNamed(context, AppRouter.approvedApps),
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.sm),
                            Expanded(
                              child: _buildShortcutButton(
                                context: context,
                                icon: Icons.settings_suggest_outlined,
                                label: 'Settings',
                                onTap: () =>
                                    Navigator.pushNamed(context, AppRouter.settings),
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.xs),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShortcutButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return VegaCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isDark ? AppColors.lavender : AppColors.primaryPink,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
