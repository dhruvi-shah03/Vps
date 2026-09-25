import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/app_state.dart';
import '../../services/report_service.dart';
import '../../widgets/app_widgets.dart';
import 'vihar_form_screen.dart';
import 'vihar_detail_screen.dart';

class ViharListScreen extends StatefulWidget {
  const ViharListScreen({super.key});

  @override
  State<ViharListScreen> createState() => _ViharListScreenState();
}

class _ViharListScreenState extends State<ViharListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final filteredVihars = appState.vihars.where((v) {
      final q = _searchQuery.toLowerCase();
      return v.mahatmaName.toLowerCase().contains(q) ||
          v.startLocation.toLowerCase().contains(q) ||
          v.endLocation.toLowerCase().contains(q) ||
          v.status.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vihars'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_vihar_list',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ViharFormScreen(appState: appState)),
          );
        },
        backgroundColor: AppTheme.secondaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Vihar'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchBarWidget(
              hint: 'Search Vihar by Mahatma, location, status...',
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => appState.refreshVihars(),
              child: filteredVihars.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 40),
                        EmptyStateWidget(
                          title: _searchQuery.isEmpty ? 'No Vihars Available' : 'No Records Found',
                          message: _searchQuery.isEmpty ? 'Pull down to refresh or tap below to add a new Vihar schedule.' : 'No Vihars matching "$_searchQuery".',
                          buttonText: _searchQuery.isEmpty ? '+ Add Vihar' : null,
                          onButtonPressed: _searchQuery.isEmpty
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => ViharFormScreen(appState: appState)),
                                  );
                                }
                              : null,
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                      itemCount: filteredVihars.length,
                      itemBuilder: (context, index) {
                        final item = filteredVihars[index];
                        return _ViharCard(item: item);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViharCard extends StatelessWidget {
  final Vihar item;

  const _ViharCard({required this.item});

  Future<void> _downloadViharReport(
    BuildContext context,
    AppState appState,
    String language,
  ) async {
    final intId = int.tryParse(item.id);
    if (intId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Vihar record ID for report generation.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    ViharReportLanguage langEnum = ViharReportLanguage.english;
    if (language.toLowerCase().contains('gujarati')) {
      langEnum = ViharReportLanguage.gujarati;
    } else if (language.toLowerCase().contains('hindi')) {
      langEnum = ViharReportLanguage.hindi;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Downloading $language report...',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 3),
      ),
    );

    try {
      final pdfBytes = await appState.downloadReport(intId, langEnum);
      final filename = 'Vihar_Report_${intId}_$language.pdf';

      bool savedDirectly = false;
      String savedPath = '';
      try {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (downloadDir.existsSync()) {
          final file = File('${downloadDir.path}/$filename');
          await file.writeAsBytes(pdfBytes);
          savedDirectly = true;
          savedPath = file.path;
        }
      } catch (_) {}

      await Printing.sharePdf(
        bytes: Uint8List.fromList(pdfBytes),
        filename: filename,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    savedDirectly
                        ? 'Downloaded to $savedPath'
                        : '$language report downloaded ($filename)',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download report: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    Color statusColor;
    if (item.status == 'In Progress' || item.status == 'Active') {
      statusColor = Colors.green;
    } else if (item.status == 'Completed') {
      statusColor = Colors.blue;
    } else {
      statusColor = Colors.orange;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tappable card body that navigates to ViharDetailScreen
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ViharDetailScreen(viharId: item.id),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.mahatmaName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: AppTheme.secondaryColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          (item.startLocation.isNotEmpty && item.endLocation.isNotEmpty)
                              ? '${item.startLocation}  →  ${item.endLocation}'
                              : (item.startLocation.isNotEmpty
                                  ? 'From: ${item.startLocation}'
                                  : (item.endLocation.isNotEmpty
                                      ? 'To: ${item.endLocation}'
                                      : (item.routes.isNotEmpty
                                          ? '${item.routes.first.fromLocation}  →  ${item.routes.last.toLocation}'
                                          : 'Route not specified'))),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (item.routes.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.routes.length} stop${item.routes.length == 1 ? "" : "s"}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.secondaryColor),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dates: ${DateFormat('dd MMM').format(item.startDate)} - ${DateFormat('dd MMM yyyy').format(item.endDate)}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: AppTheme.textSecondaryLight),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Independent Action Row: Active Checkbox & PDF Download Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Active Checkbox
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final newActive = !item.active;
                    final updated = item.copyWith(
                      active: newActive,
                      status: newActive ? 'Active' : 'Planned',
                    );
                    await appState.updateVihar(updated);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(newActive ? 'Vihar marked as Active' : 'Vihar marked as Inactive'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: newActive ? AppTheme.secondaryColor : Colors.grey[700],
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: item.active,
                            activeColor: AppTheme.secondaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) async {
                              final newActive = val ?? false;
                              final updated = item.copyWith(
                                active: newActive,
                                status: newActive ? 'Active' : 'Planned',
                              );
                              await appState.updateVihar(updated);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(newActive ? 'Vihar marked as Active' : 'Vihar marked as Inactive'),
                                    duration: const Duration(seconds: 1),
                                    backgroundColor: newActive ? AppTheme.secondaryColor : Colors.grey[700],
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.active ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: item.active ? AppTheme.secondaryColor : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Download PDF Menu
                PopupMenuButton<String>(
                  tooltip: 'Download PDF Report',
                  onSelected: (lang) => _downloadViharReport(context, appState, lang),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'English',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 18),
                          SizedBox(width: 8),
                          Text('English Report'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'Gujarati',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 18),
                          SizedBox(width: 8),
                          Text('Gujarati Report'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'Hindi',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 18),
                          SizedBox(width: 8),
                          Text('Hindi Report'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.picture_as_pdf, size: 16, color: Colors.redAccent),
                        SizedBox(width: 6),
                        Text(
                          'Download PDF',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, size: 16, color: Colors.redAccent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
