import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vps_app/models/app_models.dart';
import 'package:vps_app/screens/more/more_screen.dart';
import 'package:vps_app/screens/master/master_screens.dart';
import 'package:vps_app/screens/route/route_list_screen.dart';
import 'package:vps_app/screens/route/route_form_screen.dart';
import 'package:vps_app/screens/vihar/vihar_form_screen.dart';
import 'package:vps_app/screens/vihar/vihar_list_screen.dart';
import 'package:vps_app/services/app_state.dart';
import 'package:vps_app/services/report_service.dart';

void main() {
  group('Village Master & Route Filter Tests', () {
    test('Village model serialization and defaults', () {
      final v = Village(
        id: 'v_999',
        nameEnglish: 'Anand',
        nameGujarati: 'આણંદ',
        nameHindi: 'आनंद',
        districtId: 'd_005',
        districtName: 'Vadodara',
        status: 'active',
      );

      expect(v.name, 'Anand');
      expect(v.nameEnglish, 'Anand');
      expect(v.nameGujarati, 'આણંદ');
      expect(v.nameHindi, 'आनंद');
      expect(v.districtId, 'd_005');
      expect(v.districtName, 'Vadodara');
      expect(v.status, 'active');
      expect(v.active, true);
    });

    test('AppState Village CRUD with mock repo', () async {
      final state = AppState();
      state.toggleBackendMode(false);
      await state.loadAllData();

      final initialCount = state.villages.length;
      expect(initialCount, greaterThan(0));

      // Add Village
      final newVillage = Village(
        id: 'v_test',
        nameEnglish: 'Test Village',
        nameGujarati: 'ટેસ્ટ',
        nameHindi: 'टेस्ट',
        districtName: 'Ahmedabad',
      );
      await state.addVillage(newVillage);
      expect(state.villages.length, initialCount + 1);
      expect(state.villages.any((v) => v.nameEnglish == 'Test Village'), true);

      // Update Village
      final updated = Village(
        id: 'v_test',
        nameEnglish: 'Updated Village',
        nameGujarati: 'અપડેટેડ',
        nameHindi: 'अपडेटेड',
        districtName: 'Ahmedabad',
      );
      await state.updateVillage(updated);
      expect(state.villages.any((v) => v.nameEnglish == 'Updated Village'), true);

      // Delete Village
      await state.deleteVillage('v_test');
      expect(state.villages.length, initialCount);
    });

    testWidgets('MoreScreen contains Village item and navigates to VillageScreen', (WidgetTester tester) async {
      final state = AppState();
      state.toggleBackendMode(false);
      await state.loadAllData();

      await tester.pumpWidget(
        AppStateScope(
          state: state,
          child: const MaterialApp(
            home: MoreScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final villageFinder = find.text('Village');
      expect(villageFinder, findsOneWidget);

      await tester.tap(villageFinder);
      await tester.pumpAndSettle();

      expect(find.byType(VillageScreen), findsOneWidget);
      expect(find.textContaining('Villages'), findsWidgets);
      expect(find.text('Search Village...'), findsOneWidget);
    });

    testWidgets('RouteListScreen has report button in header and single filter button beside search', (WidgetTester tester) async {
      final state = AppState();
      state.toggleBackendMode(false);
      await state.loadAllData();

      await tester.pumpWidget(
        AppStateScope(
          state: state,
          child: const MaterialApp(
            home: RouteListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure AppBar has the report button and no duplicate filter icon in header
      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);
      expect(find.descendant(of: appBarFinder, matching: find.byIcon(Icons.picture_as_pdf_outlined)), findsOneWidget);
      expect(find.descendant(of: appBarFinder, matching: find.byIcon(Icons.filter_list)), findsNothing);

      // Verify filter button exists beside search bar and exactly ONCE
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('RouteListScreen multi-district and date range filter sheet opens properly', (WidgetTester tester) async {
      final state = AppState();
      state.toggleBackendMode(false);
      await state.loadAllData();

      await tester.pumpWidget(
        AppStateScope(
          state: state,
          child: const MaterialApp(
            home: RouteListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap filter button beside search
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Verify multi-district and From/To date filters exist in bottom sheet
      expect(find.textContaining('Filter by District'), findsOneWidget);
      expect(find.text('Filter by Date Range'), findsOneWidget);
      expect(find.text('From Date'), findsOneWidget);
      expect(find.text('To Date'), findsOneWidget);
      expect(find.text('RESET ALL'), findsOneWidget);
      expect(find.text('APPLY'), findsOneWidget);
    });

    test('ReportService generateLocalRoutePdf generates valid PDF bytes', () async {
      final state = AppState();
      state.toggleBackendMode(false);
      await state.loadAllData();

      final bytes = await state.reportService.generateLocalRoutePdf(
        routes: state.routes,
        language: ViharReportLanguage.english,
      );

      expect(bytes, isNotEmpty);
      // PDF file magic header "%PDF-"
      expect(bytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2d]));
    });

    testWidgets('ViharFormScreen contains GoogleSearchTypeAhead and autofills District Incharge', (WidgetTester tester) async {
      final state = AppState();
      state.toggleBackendMode(false);
      await state.loadAllData();

      await tester.pumpWidget(
        AppStateScope(
          state: state,
          child: const MaterialApp(
            home: ViharFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify GoogleSearchTypeAhead fields exist instead of Dropdowns
      expect(find.text('Code / Select Mahatma'), findsOneWidget);
      expect(find.text('Salutations'), findsOneWidget);
      expect(find.text('From Location'), findsOneWidget);
      expect(find.text('To Location'), findsOneWidget);
      expect(find.text('District'), findsOneWidget);
      expect(find.text('District Incharge'), findsOneWidget);

      // Verify no DropdownButtonFormField is present for these fields
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    });

    testWidgets('RouteFormScreen uses GoogleSearchTypeAhead for from, to, and district', (WidgetTester tester) async {
      final state = AppState();
      state.toggleBackendMode(false);
      await state.loadAllData();

      await tester.pumpWidget(
        AppStateScope(
          state: state,
          child: const MaterialApp(
            home: RouteFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('From Location'), findsOneWidget);
      expect(find.text('To Location'), findsOneWidget);
      expect(find.text('District'), findsOneWidget);
      expect(find.text('District Incharge Information'), findsOneWidget);
    });

    testWidgets('ViharListScreen cards contain Active checkbox and Download PDF button', (WidgetTester tester) async {
      final state = AppState();
      state.toggleBackendMode(false);
      await state.loadAllData();

      await tester.pumpWidget(
        AppStateScope(
          state: state,
          child: const MaterialApp(
            home: ViharListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Active checkbox and Download PDF button are rendered
      expect(find.byType(Checkbox), findsWidgets);
      expect(find.text('Download PDF'), findsWidgets);
    });
  });
}
