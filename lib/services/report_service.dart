import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/app_models.dart';
import 'odoo_client.dart';

enum ViharReportLanguage {
  english,
  gujarati,
  hindi,
}

class ReportService {
  final OdooClient client;

  ReportService(this.client);

  // Vihar report actions
  static const String englishReportAction = 'ai_vihar.report_add_vihar_english';
  static const String gujaratiReportAction = 'ai_vihar.report_add_vihar_gujarati';
  static const String hindiReportAction = 'ai_vihar.report_add_vihar_hindi';

  // Route report templates & actions in Odoo backend
  static const String routeEnglishReport = 'ai_vihar.pdf_template_report_english';
  static const String routeGujaratiReport = 'ai_vihar.pdf_template_report_gujarati';
  static const String routeHindiReport = 'ai_vihar.pdf_template_report_hindi';

  static const String routeEnglishAction = 'ai_vihar.action_report_vihar_en';
  static const String routeGujaratiAction = 'ai_vihar.action_report_vihar_gu';
  static const String routeHindiAction = 'ai_vihar.action_report_vihar_hi';

  String getReportActionName(ViharReportLanguage lang) {
    switch (lang) {
      case ViharReportLanguage.english:
        return englishReportAction;
      case ViharReportLanguage.gujarati:
        return gujaratiReportAction;
      case ViharReportLanguage.hindi:
        return hindiReportAction;
    }
  }

  String getRouteReportName(ViharReportLanguage lang) {
    switch (lang) {
      case ViharReportLanguage.gujarati:
        return routeGujaratiReport;
      case ViharReportLanguage.hindi:
        return routeHindiReport;
      case ViharReportLanguage.english:
        return routeEnglishReport;
    }
  }

  String getRouteActionName(ViharReportLanguage lang) {
    switch (lang) {
      case ViharReportLanguage.gujarati:
        return routeGujaratiAction;
      case ViharReportLanguage.hindi:
        return routeHindiAction;
      case ViharReportLanguage.english:
        return routeEnglishAction;
    }
  }

  /// Download PDF report bytes from Odoo for a given Vihar ID and language
  Future<List<int>> fetchViharReport({
    required int viharId,
    required ViharReportLanguage language,
  }) async {
    final actionName = getReportActionName(language);
    return await client.downloadReportPdf(
      reportName: actionName,
      recordId: viharId,
    );
  }

  /// Download PDF report for routes with exact official template and data integrity
  Future<List<int>> fetchRouteReport({
    required List<int> routeIds,
    required ViharReportLanguage language,
    List<ViharRoute>? routesForFallback,
    List<Vihar>? vihars,
    List<Mahatma>? mahatmas,
  }) async {
    // Generate accurate high-fidelity PDF report with all routes properly populated
    if (routesForFallback != null && routesForFallback.isNotEmpty) {
      debugPrint('[ReportService] Generating official route PDF for ${routesForFallback.length} routes');
      return await generateLocalRoutePdf(
        routes: routesForFallback,
        language: language,
        vihars: vihars,
        mahatmas: mahatmas,
      );
    }

    final reportName = getRouteReportName(language);
    if (routeIds.isNotEmpty && client.isAuthenticated) {
      try {
        return await client.downloadReportPdf(
          reportName: reportName,
          recordId: routeIds,
        );
      } catch (e) {
        debugPrint('[ReportService] Download failed: $e');
      }
    }

    throw Exception('Failed to generate route report.');
  }

  /// Generate high-fidelity official "VIHAR POLICE SURAKSHA - DAILY SUMMARY" PDF
  /// Exact layout matching the official VPS format:
  /// - Logo on top left
  /// - Blue title: "VIHAR POLICE SURAKSHA - DAILY SUMMARY"
  /// - Date on top right
  /// - Double divider line
  /// - Centered gold shield watermark
  /// - Exact 9 columns: SR. NO., CODE NO., LETTER NO., SAINT NAME, FROM, TO, TIME, DISTRICT INCHARGE, SEVAK DETAILS
  /// - "Regards,\nTeam VPS" at bottom right
  /// - Grouped per date without empty or duplicate pages
  Future<List<int>> generateLocalRoutePdf({
    required List<ViharRoute> routes,
    required ViharReportLanguage language,
    List<Vihar>? vihars,
    List<Mahatma>? mahatmas,
  }) async {
    final pdf = pw.Document();

    // Load VPS shield logo from assets
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/vps_logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('[ReportService] Could not load logo asset: $e');
    }

    // Group routes by date (dd/MM/yyyy)
    final routesByDate = <String, List<ViharRoute>>{};
    for (final r in routes) {
      final dateKey = DateFormat('dd/MM/yyyy').format(r.viharDate);
      routesByDate.putIfAbsent(dateKey, () => []).add(r);
    }

    // If empty, generate single page for today
    if (routesByDate.isEmpty) {
      routesByDate[DateFormat('dd/MM/yyyy').format(DateTime.now())] = [];
    }

    final vpsBlue = PdfColor.fromHex('#1a73e8');
    final saintBlue = PdfColor.fromHex('#03a9f4');
    final headerGrey = PdfColor.fromHex('#f1f1f1');

    for (final entry in routesByDate.entries) {
      final dateStr = entry.key;
      final dateRoutes = entry.value;

      // Sort routes on this date by time
      dateRoutes.sort((a, b) => a.viharDate.compareTo(b.viharDate));

      final tableRows = <List<pw.Widget>>[];

      for (int i = 0; i < dateRoutes.length; i++) {
        final r = dateRoutes[i];

        // Find parent Vihar
        Vihar? v;
        if (vihars != null) {
          v = vihars.where((item) => item.id == r.viharId || (r.viharName.isNotEmpty && item.mahatmaName == r.viharName)).firstOrNull;
        }

        // Find Mahatma
        Mahatma? m;
        if (mahatmas != null) {
          if (v != null) {
            m = mahatmas.where((item) => item.id == v!.mahatmaId || item.nameEnglish == v.mahatmaName).firstOrNull;
          }
          m ??= mahatmas.where((item) => item.nameEnglish == r.viharName).firstOrNull;
        }

        final srNo = (i + 1).toString();
        final codeNo = m?.code.isNotEmpty == true ? m!.code : '-';
        final letterNo = v?.letterNo.isNotEmpty == true ? v!.letterNo : '-';
        final saintName = m?.nameEnglish.isNotEmpty == true ? m!.nameEnglish : (r.viharName.isNotEmpty ? r.viharName : '-');
        final fromLoc = r.fromLocation.isNotEmpty ? r.fromLocation : '-';
        final toLoc = r.toLocation.isNotEmpty ? r.toLocation : '-';
        final timeStr = DateFormat('HH:mm').format(r.viharDate);
        final incharge = r.districtInchargeInfo.isNotEmpty ? r.districtInchargeInfo : (r.district.isNotEmpty ? r.district : '-');

        String sevakDetails = '-';
        if (v != null && v.sevakName.isNotEmpty) {
          sevakDetails = v.sevakName;
          if (v.contactNumber.isNotEmpty) {
            sevakDetails += '\n(${v.contactNumber})';
          }
        }

        tableRows.add([
          pw.Center(child: pw.Text(srNo, style: const pw.TextStyle(fontSize: 9))),
          pw.Center(child: pw.Text(codeNo, style: const pw.TextStyle(fontSize: 8.5))),
          pw.Center(child: pw.Text(letterNo, style: const pw.TextStyle(fontSize: 8.5))),
          pw.Text(
            saintName,
            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: saintBlue),
          ),
          pw.Text(fromLoc, style: const pw.TextStyle(fontSize: 8.5)),
          pw.Text(toLoc, style: const pw.TextStyle(fontSize: 8.5)),
          pw.Center(child: pw.Text(timeStr, style: const pw.TextStyle(fontSize: 8.5))),
          pw.Text(incharge, style: const pw.TextStyle(fontSize: 8)),
          pw.Text(sevakDetails, style: const pw.TextStyle(fontSize: 8)),
        ]);
      }

      // Chunk rows so that no single page exceeds 10 rows
      final rowChunks = <List<List<pw.Widget>>>[];
      if (tableRows.isEmpty) {
        rowChunks.add([]);
      } else {
        for (int c = 0; c < tableRows.length; c += 10) {
          final end = (c + 10 < tableRows.length) ? c + 10 : tableRows.length;
          rowChunks.add(tableRows.sublist(c, end));
        }
      }

      for (int pageIdx = 0; pageIdx < rowChunks.length; pageIdx++) {
        final currentRows = rowChunks[pageIdx];
        final isLastPage = pageIdx == rowChunks.length - 1;

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(28),
            build: (pw.Context context) {
              return pw.Stack(
                children: [
                  // Watermark in background
                  if (logoImage != null)
                    pw.Center(
                      child: pw.Opacity(
                        opacity: 0.14,
                        child: pw.Image(logoImage, width: 280, height: 280),
                      ),
                    ),

                  // Main Page Content
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Header section
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          if (logoImage != null)
                            pw.Container(
                              width: 65,
                              height: 65,
                              margin: const pw.EdgeInsets.only(right: 14),
                              child: pw.Image(logoImage),
                            ),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'VIHAR POLICE',
                                  style: pw.TextStyle(
                                    fontSize: 18,
                                    fontWeight: pw.FontWeight.bold,
                                    color: vpsBlue,
                                    lineSpacing: 1.1,
                                  ),
                                ),
                                pw.Text(
                                  'SURAKSHA - DAILY',
                                  style: pw.TextStyle(
                                    fontSize: 18,
                                    fontWeight: pw.FontWeight.bold,
                                    color: vpsBlue,
                                    lineSpacing: 1.1,
                                  ),
                                ),
                                pw.Text(
                                  'SUMMARY',
                                  style: pw.TextStyle(
                                    fontSize: 18,
                                    fontWeight: pw.FontWeight.bold,
                                    color: vpsBlue,
                                    lineSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 6),

                      // Date row aligned to right
                      pw.Container(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          rowChunks.length > 1 ? 'Date: $dateStr (Page ${pageIdx + 1}/${rowChunks.length})' : 'Date: $dateStr',
                          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                        ),
                      ),

                      pw.SizedBox(height: 6),

                      // Double Divider lines underneath header
                      pw.Container(height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 2),
                      pw.Container(height: 2, color: PdfColors.black),

                      pw.SizedBox(height: 12),

                      // Summary Table
                      pw.Table(
                        border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
                        columnWidths: {
                          0: const pw.FlexColumnWidth(5), // SR. NO.
                          1: const pw.FlexColumnWidth(8), // CODE NO.
                          2: const pw.FlexColumnWidth(8), // LETTER NO.
                          3: const pw.FlexColumnWidth(23), // SAINT NAME
                          4: const pw.FlexColumnWidth(11), // FROM
                          5: const pw.FlexColumnWidth(11), // TO
                          6: const pw.FlexColumnWidth(8), // TIME
                          7: const pw.FlexColumnWidth(14), // DISTRICT INCHARGE
                          8: const pw.FlexColumnWidth(12), // SEVAK DETAILS
                        },
                        children: [
                          // Table Header
                          pw.TableRow(
                            decoration: pw.BoxDecoration(color: headerGrey),
                            children: [
                              _buildHeaderCell('SR.\nNO.'),
                              _buildHeaderCell('CODE\nNO.'),
                              _buildHeaderCell('LETTER\nNO.'),
                              _buildHeaderCell('SAINT NAME'),
                              _buildHeaderCell('FROM'),
                              _buildHeaderCell('TO'),
                              _buildHeaderCell('TIME'),
                              _buildHeaderCell('DISTRICT\nINCHARGE'),
                              _buildHeaderCell('SEVAK\nDETAILS'),
                            ],
                          ),

                          // Table Data Rows
                          if (currentRows.isEmpty)
                            pw.TableRow(
                              children: List.generate(
                                9,
                                (idx) => pw.Container(
                                  padding: const pw.EdgeInsets.all(6),
                                  alignment: pw.Alignment.center,
                                  child: pw.Text('-', style: const pw.TextStyle(fontSize: 8)),
                                ),
                              ),
                            )
                          else
                            ...currentRows.map(
                              (cells) => pw.TableRow(
                                children: cells
                                    .map(
                                      (widget) => pw.Container(
                                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                                        alignment: pw.Alignment.centerLeft,
                                        child: widget,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                        ],
                      ),

                      pw.SizedBox(height: 16),

                      // Signature Block on the last page of date
                      if (isLastPage)
                        pw.Container(
                          alignment: pw.Alignment.bottomRight,
                          margin: const pw.EdgeInsets.only(top: 8, bottom: 8),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                'Regards,',
                                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'Team VPS',
                                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }
    }

    return await pdf.save();
  }

  static pw.Widget _buildHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
      ),
    );
  }
}
