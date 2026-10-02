import 'package:flutter/material.dart';
import 'package:vega_ai/core/constants/app_colors.dart';
import 'package:vega_ai/core/constants/app_dimensions.dart';
import 'package:vega_ai/features/automation/action_registry.dart';
import 'package:vega_ai/features/automation/models/app_action.dart';
import 'package:vega_ai/shared/widgets/vega_app_bar.dart';
import 'package:vega_ai/shared/widgets/vega_card.dart';

/// Screen displaying and managing safe approved Android apps and hardware actions.
class AppActionsScreen extends StatefulWidget {
  const AppActionsScreen({super.key});

  @override
  State<AppActionsScreen> createState() => _AppActionsScreenState();
}

class _AppActionsScreenState extends State<AppActionsScreen> {
  late final ActionRegistry _registry;
  late List<AppAction> _actions;

  @override
  void initState() {
    super.initState();
    _registry = ActionRegistry();
    _actions = _registry.getAllActions();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const VegaAppBar(title: 'Approved Integrations'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.md),
          children: [
            // Notice banner explaining safety sandbox
            VegaCard(
              hasGlow: true,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPink.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.primaryPink,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Zero-Trust Automation Sandbox',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Only registered safe actions are allowed. Arbitrary shell execution and destructive actions are blocked.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),

            // Section title
            Text(
              'Registered Device & App Actions',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.lavender : AppColors.primaryPink,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),

            // Action list
            ..._actions.map((action) {
              final isRestricted = action.safetyLevel.isRestricted;
              final requiresConfirm = action.safetyLevel.requiresConfirmation;

              Color badgeColor;
              String badgeText;

              if (isRestricted) {
                badgeColor = Colors.redAccent;
                badgeText = 'RESTRICTED';
              } else if (requiresConfirm) {
                badgeColor = AppColors.offlineOrange;
                badgeText = 'CONFIRM REQ';
              } else {
                badgeColor = AppColors.onlineGreen;
                badgeText = 'SAFE';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                child: VegaCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLightSubtle,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIconForCategory(action.category),
                          size: 20,
                          color: isRestricted ? Colors.grey : AppColors.primaryPink,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  action.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isRestricted ? Colors.grey : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    badgeText,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: badgeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              action.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: action.isEnabled && !isRestricted,
                        activeColor: AppColors.primaryPink,
                        onChanged: isRestricted
                            ? null
                            : (val) {
                                setState(() {
                                  final index = _actions.indexOf(action);
                                  _actions[index] = action.copyWith(isEnabled: val);
                                });
                              },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(ActionCategory category) {
    switch (category) {
      case ActionCategory.deviceHardware:
        return Icons.flashlight_on_rounded;
      case ActionCategory.mediaAudio:
        return Icons.volume_up_rounded;
      case ActionCategory.appShortcuts:
        return Icons.camera_alt_rounded;
      case ActionCategory.systemInfo:
        return Icons.battery_charging_full_rounded;
      case ActionCategory.communication:
        return Icons.chat_bubble_outline_rounded;
    }
  }
}
