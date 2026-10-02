import 'package:flutter/material.dart';
import 'package:vega_ai/app/app_router.dart';
import 'package:vega_ai/core/constants/app_strings.dart';
import 'package:vega_ai/features/assistant/assistant_controller.dart';
import 'package:vega_ai/shared/theme/app_theme.dart';

/// Root application widget for VEGA AI.
class VegaApp extends StatefulWidget {
  const VegaApp({super.key});

  @override
  State<VegaApp> createState() => _VegaAppState();
}

class _VegaAppState extends State<VegaApp> {
  late final AssistantController _assistantController;

  @override
  void initState() {
    super.initState();
    _assistantController = AssistantController();
  }

  @override
  void dispose() {
    _assistantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to futuristic sci-fi dark mode
      initialRoute: AppRouter.home,
      onGenerateRoute: (settings) =>
          AppRouter.onGenerateRoute(settings, _assistantController),
    );
  }
}
