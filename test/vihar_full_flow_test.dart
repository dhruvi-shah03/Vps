import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vps_app/services/app_state.dart';
import 'package:vps_app/screens/auth/login_screen.dart';
import 'package:vps_app/screens/vihar/vihar_form_screen.dart';

void main() {
  testWidgets('Full flow from Login to Dashboard to + Vihar', (WidgetTester tester) async {
    final state = AppState();
    state.toggleBackendMode(false); // mock backend

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Fill in email and password
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'admin@example.com');
    await tester.enterText(textFields.at(1), 'admin123');

    // Tap LOGIN
    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();

    // Verify Dashboard is open
    expect(find.text('+ Vihar'), findsOneWidget);

    // Tap + Vihar
    await tester.tap(find.text('+ Vihar'));
    await tester.pumpAndSettle();

    print('Checking if ViharFormScreen is mounted...');
    expect(find.byType(ViharFormScreen), findsOneWidget);
    print('ViharFormScreen mounted successfully!');
  });
}
