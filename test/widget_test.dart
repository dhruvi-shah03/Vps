import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vps_app/services/app_state.dart';
import 'package:vps_app/screens/dashboard/dashboard_screen.dart';

void main() {
  testWidgets('DashboardScreen to ViharFormScreen navigation', (WidgetTester tester) async {
    final state = AppState();
    state.toggleBackendMode(false);

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Look for + Vihar button on dashboard
    final addViharFinder = find.text('+ Vihar');
    expect(addViharFinder, findsOneWidget);

    // Tap + Vihar
    await tester.tap(addViharFinder);
    await tester.pumpAndSettle();

    // Verify Add Vihar screen loaded
    expect(find.text('Add Vihar'), findsOneWidget);
    expect(find.text("MAHATMA'S INFORMATION"), findsOneWidget);
    expect(find.text("VIHAR'S INFORMATION"), findsOneWidget);
  });
}
