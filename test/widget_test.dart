import 'package:flutter_test/flutter_test.dart';
import 'package:vega_ai/app/app.dart';
import 'package:vega_ai/core/constants/app_strings.dart';
import 'package:vega_ai/features/assistant/widgets/voice_orb_button.dart';
import 'package:vega_ai/shared/widgets/network_status_indicator.dart';

void main() {
  testWidgets('VEGA AI Home Screen renders branding and settles in idle state', (WidgetTester tester) async {
    // Build the VegaApp
    await tester.pumpWidget(const VegaApp());

    // Because idle animations are paused, pumpAndSettle must complete cleanly without timing out
    await tester.pumpAndSettle();

    // Verify VEGA branding
    expect(find.text(AppStrings.appName), findsOneWidget);

    // Verify Voice Orb Button is present
    expect(find.byType(VoiceOrbButton), findsOneWidget);

    // Verify status indicator and shortcuts
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Approved Apps'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Tapping network status pill toggles online and offline display mode', (WidgetTester tester) async {
    await tester.pumpWidget(const VegaApp());
    await tester.pumpAndSettle();

    // Default mode is online
    expect(find.text(AppStrings.onlineBadge), findsOneWidget);

    // Tap indicator to toggle offline
    await tester.tap(find.byType(NetworkStatusIndicator));
    await tester.pumpAndSettle();

    // Mode is now offline
    expect(find.text(AppStrings.offlineBadge), findsOneWidget);
  });
}
