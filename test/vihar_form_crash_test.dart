import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vps_app/services/app_state.dart';
import 'package:vps_app/screens/vihar/vihar_form_screen.dart';

void main() {
  testWidgets('Test ViharFormScreen with Stitch Add Another Route / Stop concept', (WidgetTester tester) async {
    final state = AppState();
    state.toggleBackendMode(false);

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          home: ViharFormScreen(appState: state),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Check main title
    expect(find.text('Add Vihar'), findsOneWidget);

    // Check zero prefill
    expect(find.text('Code / Select Mahatma'), findsOneWidget);
    expect(find.text("VIHAR'S INFORMATION"), findsOneWidget);
    expect(find.text('From Location'), findsOneWidget);
    expect(find.text('To Location'), findsOneWidget);
    expect(find.text('District'), findsOneWidget);
    expect(find.text('District Incharge'), findsOneWidget);

    // Look for Stitch dashed button
    final addStopFinder = find.text('Add Another Route / Stop');
    expect(addStopFinder, findsOneWidget);

    // Tap Add Another Route / Stop
    await tester.ensureVisible(addStopFinder);
    await tester.pumpAndSettle();
    await tester.tap(addStopFinder);
    await tester.pumpAndSettle();

    // Verify Route / Stop #2 card appeared
    expect(find.text('Route / Stop #2'), findsOneWidget);
    expect(find.text('Stop Date & Time'), findsOneWidget);
    expect(find.text('Stop / Transit Location'), findsOneWidget);
    expect(find.text('Next Destination'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);

    // Tap Remove
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    // Verify Route / Stop #2 is removed
    expect(find.text('Route / Stop #2'), findsNothing);
  });
}
