import 'package:flutter/material.dart';
import 'package:vega_ai/core/constants/app_colors.dart';
import 'package:vega_ai/core/constants/app_dimensions.dart';
import 'package:vega_ai/core/models/command_intent.dart';
import 'package:vega_ai/core/models/execution_result.dart';
import 'package:vega_ai/features/history/models/activity_item.dart';
import 'package:vega_ai/shared/widgets/vega_app_bar.dart';
import 'package:vega_ai/shared/widgets/vega_card.dart';
import 'package:vega_ai/shared/widgets/vega_chip.dart';

/// Activity History Screen displaying past voice commands and results.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'All';

  // Seed sample data for demonstration
  final List<ActivityItem> _activities = [
    ActivityItem(
      id: 'act_1',
      commandText: 'Turn on the flashlight',
      responseText: 'Flashlight enabled, sir.',
      category: IntentCategory.deviceControl,
      isOffline: true,
      status: ExecutionStatus.success,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    ActivityItem(
      id: 'act_2',
      commandText: 'What is the quantum telemetry status?',
      responseText: 'Telemetry data synced with Gemini core. All subsystem levels nominal.',
      category: IntentCategory.conversationalAI,
      isOffline: false,
      status: ExecutionStatus.success,
      timestamp: DateTime.now().subtract(const Duration(minutes: 24)),
    ),
    ActivityItem(
      id: 'act_3',
      commandText: 'Set media volume to 80%',
      responseText: 'Audio levels adjusted.',
      category: IntentCategory.deviceControl,
      isOffline: true,
      status: ExecutionStatus.success,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _activities.where((item) {
      if (_selectedFilter == 'Offline') return item.isOffline;
      if (_selectedFilter == 'Online') return !item.isOffline;
      return true;
    }).toList();

    return Scaffold(
      appBar: const VegaAppBar(title: 'Activity History'),
      body: SafeArea(
        child: Column(
          children: [
            // Filter bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: AppDimensions.sm,
              ),
              child: Row(
                children: [
                  VegaChip(
                    label: 'All',
                    isSelected: _selectedFilter == 'All',
                    onTap: () => setState(() => _selectedFilter = 'All'),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  VegaChip(
                    label: 'Offline (Local)',
                    isSelected: _selectedFilter == 'Offline',
                    onTap: () => setState(() => _selectedFilter = 'Offline'),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  VegaChip(
                    label: 'Online (Cloud)',
                    isSelected: _selectedFilter == 'Online',
                    onTap: () => setState(() => _selectedFilter = 'Online'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.xs),

            // Activity list
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 48,
                            color: isDark ? AppColors.lavender.withOpacity(0.4) : AppColors.primaryPink.withOpacity(0.4),
                          ),
                          const SizedBox(height: AppDimensions.md),
                          Text(
                            'No activities found',
                            style: TextStyle(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppDimensions.md),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.sm),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return VegaCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: item.isOffline
                                          ? AppColors.offlineOrange.withOpacity(0.15)
                                          : AppColors.primaryPink.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.isOffline ? 'OFFLINE' : 'ONLINE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: item.isOffline ? AppColors.offlineOrange : AppColors.primaryPink,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    item.timeFormatted,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.sm),
                              Text(
                                '"${item.commandText}"',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.xs),
                              Text(
                                item.responseText,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.lavenderLight : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
