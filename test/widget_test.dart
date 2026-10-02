import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vega_ai/app/app.dart';
import 'package:vega_ai/core/constants/app_strings.dart';
import 'package:vega_ai/features/assistant/widgets/voice_orb_button.dart';

void main() {
  testWidgets('VEGA AI Home Screen renders branding and orb button', (WidgetTester tester) async {
    // Build the VegaApp
    await tester.pumpWidget(const VegaApp());
    await tester.pump();

    // Verify VEGA branding
    expect(find.text(AppStrings.appName), findsOneWidget);

    // Verify Voice Orb Button is present
    expect(find.byType(VoiceOrbButton), findsOneWidget);

    // Verify status indicator and shortcuts
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Approved Apps'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
