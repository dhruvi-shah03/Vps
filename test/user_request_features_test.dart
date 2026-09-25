import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vps_app/models/app_models.dart';
import 'package:vps_app/screens/vihar/vihar_form_screen.dart';
import 'package:vps_app/screens/mahatma/mahatma_form_screen.dart';
import 'package:vps_app/services/app_state.dart';
import 'package:vps_app/widgets/app_widgets.dart';

void main() {
  group('New Feature Requirements Tests', () {
    test('AppState enforces Mahatma code uniqueness as primary key', () async {
      final state = AppState();
      state.toggleBackendMode(false);
      await state.loadAllData();

      // Add a mahatma with unique code
      final m1 = Mahatma(
        id: 'm_unique_1',
        code: 'UNIQUE99',
        nameEnglish: 'Swami Test 1',
        samuday: 'General',
        contactNumber: '9999999999',
      );
      await state.addMahatma(m1);
      expect(state.mahatmas.any((m) => m.code == 'UNIQUE99'), true);

      // Attempting to add another mahatma with identical code (case-insensitive) should throw
      final m2 = Mahatma(
        id: 'm_unique_2',
        code: 'unique99',
        nameEnglish: 'Swami Test 2',
        samuday: 'General',
        contactNumber: '8888888888',
      );

      expect(() => state.addMahatma(m2), throwsA(isA<Exception>()));
    });

    testWidgets('ViharFormScreen prefills Letter No with "L-" and has "+ Add" buttons', (tester) async {
      final state = AppState();
      state.toggleBackendMode(false);
      await state.loadAllData();

      await tester.pumpWidget(
        MaterialApp(
          home: ViharFormScreen(appState: state),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Letter No field has "L-" prefilled
      final letterNoField = find.widgetWithText(AppTextField, 'L-');
      expect(letterNoField, findsOneWidget);

      // Verify "+ Add" buttons exist on GoogleSearchTypeAhead widgets
      final addMahatmaBtn = find.text('+ Add Mahatma');
      expect(addMahatmaBtn, findsOneWidget);

      final addSalutationBtn = find.text('+ Add Salutation');
      expect(addSalutationBtn, findsOneWidget);

      final addVillageBtns = find.text('+ Add Village');
      expect(addVillageBtns, findsAtLeastNWidgets(1));

      final addDistrictBtn = find.text('+ Add District');
      expect(addDistrictBtn, findsOneWidget);

      final addInchargeBtn = find.text('+ Add Incharge');
      expect(addInchargeBtn, findsOneWidget);
    });

    testWidgets('MahatmaFormScreen validates code uniqueness', (tester) async {
      final state = AppState();
      state.toggleBackendMode(false);
      await state.loadAllData();

      await tester.pumpWidget(
        MaterialApp(
          home: AppStateScope(
            state: state,
            child: const Scaffold(
              body: MahatmaFormScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Existing code from loaded mock data (e.g. M001)
      final existingCode = state.mahatmas.first.code;
      final textFields = find.byType(TextFormField);
      // First TextFormField is code
      await tester.enterText(textFields.first, existingCode);
      await tester.pump();

      // Find form and validate
      final form = tester.widget<Form>(find.byType(Form));
      final formKey = form.key as GlobalKey<FormState>;
      final isValid = formKey.currentState!.validate();
      expect(isValid, false);
    });

    testWidgets('MahatmaFormScreen uses GoogleSearchTypeAhead for Samuday and has + Add Samuday', (tester) async {
      final state = AppState();
      state.toggleBackendMode(false);
      await state.loadAllData();

      await tester.pumpWidget(
        MaterialApp(
          home: AppStateScope(
            state: state,
            child: const Scaffold(
              body: MahatmaFormScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify GoogleSearchTypeAhead for Samuday exists
      final samudaySearch = find.widgetWithText(GoogleSearchTypeAhead<String>, 'Samuday');
      expect(samudaySearch, findsOneWidget);

      // Verify "+ Add Samuday" button exists
      final addSamudayBtn = find.text('+ Add Samuday');
      expect(addSamudayBtn, findsOneWidget);
    });

    test('AppState.deleteVihar removes vihar from list', () async {
      final state = AppState();
      state.toggleBackendMode(false);
      await state.loadAllData();

      expect(state.vihars.isNotEmpty, true);
      final viharToDelete = state.vihars.first;
      await state.deleteVihar(viharToDelete.id);

      expect(state.vihars.any((v) => v.id == viharToDelete.id), false);
    });
  });
}

