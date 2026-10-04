import 'package:flutter/material.dart';
import 'package:vega_ai/features/assistant/assistant_controller.dart';
import 'package:vega_ai/features/automation/screens/app_actions_screen.dart';
import 'package:vega_ai/features/history/screens/history_screen.dart';
import 'package:vega_ai/features/home/screens/home_screen.dart';
import 'package:vega_ai/features/settings/screens/settings_screen.dart';

/// Centralized route generator and route paths for VEGA AI.
abstract class AppRouter {
  static const String home = '/';
  static const String history = '/history';
  static const String approvedApps = '/approved-apps';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(
    RouteSettings routeSettings,
    AssistantController assistantController,
  ) {
    switch (routeSettings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => HomeScreen(controller: assistantController),
          settings: routeSettings,
        );

      case history:
        return MaterialPageRoute(
          builder: (_) => const HistoryScreen(),
          settings: routeSettings,
        );

      case approvedApps:
        return MaterialPageRoute(
          builder: (_) => const AppActionsScreen(),
          settings: routeSettings,
        );

      case settings:
        return MaterialPageRoute(
          builder: (_) => SettingsScreen(controller: assistantController),
          settings: routeSettings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${routeSettings.name}'),
            ),
          ),
          settings: routeSettings,
        );
    }
  }
}
