import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vps_app/services/app_state.dart';
import 'package:vps_app/screens/vihar/vihar_form_screen.dart';

void main() {
  testWidgets('Test ViharFormScreen with empty mahatmas and not loading', (WidgetTester tester) async {
    final state = AppState();
    state.toggleBackendMode(false);
    state.mahatmas = [];
    state.isLoading = false;

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          home: ViharFormScreen(appState: state),
        ),
      ),
    );

    await tester.pumpAndSettle();

    print('Checking widgets on screen...');
    final buttons = find.text('English');
    print('Found English button: ${buttons.evaluate().length}');
    final mahatmaHeader = find.text("MAHATMA'S INFORMATION");
    print('Found MAHATMA\'S INFORMATION: ${mahatmaHeader.evaluate().length}');
    final viharHeader = find.text("VIHAR'S INFORMATION");
    print('Found VIHAR\'S INFORMATION: ${viharHeader.evaluate().length}');
  });
}
