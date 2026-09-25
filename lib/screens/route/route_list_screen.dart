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
import 'route_form_screen.dart';
import 'route_detail_screen.dart';

class RouteListScreen extends StatefulWidget {
  const RouteListScreen({super.key});

  @override
  State<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedDistricts = <String>{};
  DateTime? _fromDate;
  DateTime? _toDate;
  String _sortOption = 'Newest'; // Newest, Oldest, Upcoming, Past

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet(AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final districtSearchController = TextEditingController();
        String districtFilterQuery = '';
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filter & Sort Routes',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 10),

                      // Multiple District Searchable Filter
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filter by District (${_selectedDistricts.isEmpty ? "All" : "${_selectedDistricts.length} selected"})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (_selectedDistricts.isNotEmpty)
                            TextButton(
                              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                              onPressed: () {
                                setModalState(() => _selectedDistricts.clear());
                                setState(() {});
                              },
                              child: const Text('Clear All', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Search Input Field
                      TextField(
                        controller: districtSearchController,
                        decoration: InputDecoration(
                          hintText: 'Type district name to search (e.g. Surat)...',
                          prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.primaryColor),
                          suffixIcon: districtFilterQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    districtSearchController.clear();
                                    setModalState(() => districtFilterQuery = '');
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (val) {
                          setModalState(() => districtFilterQuery = val);
                        },
                      ),

                      // Selected District Chips
                      if (_selectedDistricts.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _selectedDistricts.map((dName) {
                            return Chip(
                              label: Text(
                                dName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                              deleteIcon: const Icon(Icons.close, size: 16, color: AppTheme.primaryColor),
                              onDeleted: () {
                                setModalState(() => _selectedDistricts.remove(dName));
                                setState(() {});
                              },
                            );
                          }).toList(),
                        ),
                      ],

                      // Matching Searchable Results Dropdown/List
                      Builder(
                        builder: (_) {
                          final query = districtFilterQuery.trim().toLowerCase();
                          final matching = appState.districts.where((d) {
                            if (query.isEmpty) return true;
                            return d.name.toLowerCase().contains(query);
                          }).toList();

                          if (appState.districts.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('No districts available', style: TextStyle(color: Colors.grey)),
                            );
                          }

                          if (matching.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('No districts matching "$districtFilterQuery"', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            );
                          }

                          return Container(
                            constraints: const BoxConstraints(maxHeight: 140),
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Material(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              clipBehavior: Clip.antiAlias,
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: matching.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (ctx, i) {
                                  final d = matching[i];
                                  final isSelected = _selectedDistricts.contains(d.name);
                                  return ListTile(
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    title: Text(
                                      d.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? AppTheme.primaryColor : Colors.black87,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 18)
                                        : const Icon(Icons.add_circle_outline, color: Colors.grey, size: 18),
                                    onTap: () {
                                      setModalState(() {
                                        if (isSelected) {
                                          _selectedDistricts.remove(d.name);
                                        } else {
                                          _selectedDistricts.add(d.name);
                                        }
                                      });
                                      setState(() {});
                                    },
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Date Range Filter ("From" and "To")
                      const Text('Filter by Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _fromDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) {
                                  setModalState(() => _fromDate = picked);
                                  setState(() => _fromDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _fromDate != null ? AppTheme.primaryColor : Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: _fromDate != null ? AppTheme.primaryColor.withValues(alpha: 0.06) : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('From Date', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 14, color: AppTheme.primaryColor),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _fromDate != null
                                                ? DateFormat('dd/MM/yyyy').format(_fromDate!)
                                                : 'Start Date',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: _fromDate != null ? FontWeight.bold : FontWeight.normal,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (_fromDate != null)
                                          GestureDetector(
                                            onTap: () {
                                              setModalState(() => _fromDate = null);
                                              setState(() => _fromDate = null);
                                            },
                                            child: const Icon(Icons.clear, size: 16, color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _toDate ?? _fromDate ?? DateTime.now(),
                                  firstDate: _fromDate ?? DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) {
                                  setModalState(() => _toDate = picked);
                                  setState(() => _toDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _toDate != null ? AppTheme.primaryColor : Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: _toDate != null ? AppTheme.primaryColor.withValues(alpha: 0.06) : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('To Date', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.event, size: 14, color: AppTheme.primaryColor),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _toDate != null
                                                ? DateFormat('dd/MM/yyyy').format(_toDate!)
                                                : 'End Date',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: _toDate != null ? FontWeight.bold : FontWeight.normal,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (_toDate != null)
                                          GestureDetector(
                                            onTap: () {
                                              setModalState(() => _toDate = null);
                                              setState(() => _toDate = null);
                                            },
                                            child: const Icon(Icons.clear, size: 16, color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Quick date presets
                      Wrap(
                        spacing: 8,
                        children: [
                          ActionChip(
                            label: const Text('Today', style: TextStyle(fontSize: 11)),
                            avatar: const Icon(Icons.today, size: 13),
                            onPressed: () {
                              final now = DateTime.now();
                              setModalState(() {
                                _fromDate = DateTime(now.year, now.month, now.day);
                                _toDate = DateTime(now.year, now.month, now.day);
                              });
                              setState(() {
                                _fromDate = DateTime(now.year, now.month, now.day);
                                _toDate = DateTime(now.year, now.month, now.day);
                              });
                            },
                          ),
                          ActionChip(
                            label: const Text('Next 7 Days', style: TextStyle(fontSize: 11)),
                            avatar: const Icon(Icons.date_range, size: 13),
                            onPressed: () {
                              final now = DateTime.now();
                              setModalState(() {
                                _fromDate = DateTime(now.year, now.month, now.day);
                                _toDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 7));
                              });
                              setState(() {
                                _fromDate = DateTime(now.year, now.month, now.day);
                                _toDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 7));
                              });
                            },
                          ),
                          if (_fromDate != null || _toDate != null)
                            ActionChip(
                              label: const Text('Clear Dates', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                              avatar: const Icon(Icons.clear, size: 13, color: Colors.redAccent),
                              onPressed: () {
                                setModalState(() {
                                  _fromDate = null;
                                  _toDate = null;
                                });
                                setState(() {
                                  _fromDate = null;
                                  _toDate = null;
                                });
                              },
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Sort Options
                      const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['Newest', 'Oldest', 'Upcoming', 'Past'].map((opt) {
                          final isSelected = _sortOption == opt;
                          return ChoiceChip(
                            label: Text(opt),
                            selected: isSelected,
                            selectedColor: AppTheme.primaryColor,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : null),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() => _sortOption = opt);
                                setState(() => _sortOption = opt);
                              }
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  _selectedDistricts.clear();
                                  _fromDate = null;
                                  _toDate = null;
                                  _sortOption = 'Newest';
                                });
                                setState(() {
                                  _selectedDistricts.clear();
                                  _fromDate = null;
                                  _toDate = null;
                                  _sortOption = 'Newest';
                                });
                              },
                              child: const Text('RESET ALL'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('APPLY'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showPrintReportDialog(
    BuildContext context,
    AppState appState,
  ) {
    ViharReportLanguage selectedLanguage = ViharReportLanguage.english;
    bool isGenerating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final targetRoutes = appState.routes;

            Future<void> executePrintOrDownload({required bool isDirectPrint}) async {
              setSheetState(() => isGenerating = true);

              try {
                // Extract route IDs (as integers for Odoo)
                final routeIds = targetRoutes
                    .map((r) => int.tryParse(r.id))
                    .where((id) => id != null)
                    .map((id) => id!)
                    .toList();

                final pdfBytes = await appState.downloadRouteReport(
                  routeIds: routeIds,
                  lang: selectedLanguage,
                  routesForFallback: targetRoutes,
                );

                if (!mounted) return;
                Navigator.of(sheetCtx).pop();

                final langName = selectedLanguage == ViharReportLanguage.gujarati
                    ? 'Gujarati'
                    : selectedLanguage == ViharReportLanguage.hindi
                        ? 'Hindi'
                        : 'English';

                final filename = 'VPS_Route_Report_${DateFormat("yyyyMMdd_HHmm").format(DateTime.now())}_$langName.pdf';

                if (isDirectPrint) {
                  // Direct print preview
                  await Printing.layoutPdf(
                    onLayout: (_) async => Uint8List.fromList(pdfBytes),
                    name: filename,
                  );
                } else {
                  // Save directly to Download folder if possible on Android
                  bool savedToStorage = false;
                  String storagePath = '';
                  try {
                    final downloadDir = Directory('/storage/emulated/0/Download');
                    if (downloadDir.existsSync()) {
                      final file = File('${downloadDir.path}/$filename');
                      await file.writeAsBytes(pdfBytes);
                      savedToStorage = true;
                      storagePath = file.path;
                    }
                  } catch (_) {}

                  // Also invoke standard system share / save sheet
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
                                savedToStorage
                                    ? 'Saved to $storagePath'
                                    : 'Report generated successfully ($filename)',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to generate report: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setSheetState(() => isGenerating = false);
                }
              }
            };

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.picture_as_pdf, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Print Route Report',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: isGenerating ? null : () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(Icons.alt_route, size: 16, color: AppTheme.secondaryColor),
                      const SizedBox(width: 6),
                      Text(
                        'Total Routes: ${appState.routes.length}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondaryLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Language selector
                  const Text('Report Language', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('English'),
                        selected: selectedLanguage == ViharReportLanguage.english,
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: selectedLanguage == ViharReportLanguage.english ? Colors.white : null,
                        ),
                        onSelected: (val) {
                          if (val) setSheetState(() => selectedLanguage = ViharReportLanguage.english);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('ગુજરાતી (Gujarati)'),
                        selected: selectedLanguage == ViharReportLanguage.gujarati,
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: selectedLanguage == ViharReportLanguage.gujarati ? Colors.white : null,
                        ),
                        onSelected: (val) {
                          if (val) setSheetState(() => selectedLanguage = ViharReportLanguage.gujarati);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('हिन्दी (Hindi)'),
                        selected: selectedLanguage == ViharReportLanguage.hindi,
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: selectedLanguage == ViharReportLanguage.hindi ? Colors.white : null,
                        ),
                        onSelected: (val) {
                          if (val) setSheetState(() => selectedLanguage = ViharReportLanguage.hindi);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  if (isGenerating)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 10),
                            Text('Fetching report from backend...', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.print_outlined),
                            label: const Text('PRINT'),
                            onPressed: targetRoutes.isEmpty
                                ? null
                                : () => executePrintOrDownload(isDirectPrint: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.download_outlined),
                            label: const Text('DOWNLOAD'),
                            onPressed: targetRoutes.isEmpty
                                ? null
                                : () => executePrintOrDownload(isDirectPrint: false),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    // Filter logic
    var filteredRoutes = appState.routes.where((r) {
      // 1. Text Search
      final q = _searchQuery.toLowerCase();
      final matchesQuery = q.isEmpty ||
          r.fromLocation.toLowerCase().contains(q) ||
          r.toLocation.toLowerCase().contains(q) ||
          r.district.toLowerCase().contains(q) ||
          r.districtInchargeInfo.toLowerCase().contains(q) ||
          r.viharName.toLowerCase().contains(q);

      // 2. Multi-District Filter
      final matchesDistrict = _selectedDistricts.isEmpty || _selectedDistricts.contains(r.district);

      // 3. Date Range Filter ("From" and "To")
      bool matchesDate = true;
      if (_fromDate != null) {
        final startOfFrom = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day, 0, 0, 0);
        if (r.viharDate.isBefore(startOfFrom)) {
          matchesDate = false;
        }
      }
      if (matchesDate && _toDate != null) {
        final endOfTo = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
        if (r.viharDate.isAfter(endOfTo)) {
          matchesDate = false;
        }
      }

      return matchesQuery && matchesDistrict && matchesDate;
    }).toList();

    // Sort logic
    if (_sortOption == 'Newest') {
      filteredRoutes.sort((a, b) => b.viharDate.compareTo(a.viharDate));
    } else if (_sortOption == 'Oldest') {
      filteredRoutes.sort((a, b) => a.viharDate.compareTo(b.viharDate));
    } else if (_sortOption == 'Upcoming') {
      filteredRoutes = filteredRoutes.where((r) => r.viharDate.isAfter(DateTime.now().subtract(const Duration(days: 1)))).toList();
      filteredRoutes.sort((a, b) => a.viharDate.compareTo(b.viharDate));
    } else if (_sortOption == 'Past') {
      filteredRoutes = filteredRoutes.where((r) => r.viharDate.isBefore(DateTime.now())).toList();
      filteredRoutes.sort((a, b) => b.viharDate.compareTo(a.viharDate));
    }

    final hasActiveFilters = _selectedDistricts.isNotEmpty ||
        _fromDate != null ||
        _toDate != null ||
        _sortOption != 'Newest';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vihar Routes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Print Route Report',
            onPressed: () => _showPrintReportDialog(context, appState),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_route_list',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RouteFormScreen()),
          );
        },
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Route'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchBarWidget(
              hint: 'Search routes by location, district...',
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              onFilterTap: () => _showFilterBottomSheet(appState),
            ),
          ),
          if (hasActiveFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Active: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    if (_selectedDistricts.isNotEmpty) ...[
                      if (_selectedDistricts.length <= 2)
                        ..._selectedDistricts.map(
                          (d) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Chip(
                              visualDensity: VisualDensity.compact,
                              label: Text(d, style: const TextStyle(fontSize: 11)),
                              onDeleted: () => setState(() => _selectedDistricts.remove(d)),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text('${_selectedDistricts.length} Districts', style: const TextStyle(fontSize: 11)),
                            onDeleted: () => setState(() => _selectedDistricts.clear()),
                          ),
                        ),
                    ],
                    if (_fromDate != null || _toDate != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            '${_fromDate != null ? DateFormat('dd/MM').format(_fromDate!) : ''} - ${_toDate != null ? DateFormat('dd/MM').format(_toDate!) : ''}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onDeleted: () => setState(() {
                            _fromDate = null;
                            _toDate = null;
                          }),
                        ),
                      ),
                    if (_sortOption != 'Newest')
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text('Sort: $_sortOption', style: const TextStyle(fontSize: 11)),
                          onDeleted: () => setState(() => _sortOption = 'Newest'),
                        ),
                      ),
                    TextButton(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () {
                        setState(() {
                          _selectedDistricts.clear();
                          _fromDate = null;
                          _toDate = null;
                          _sortOption = 'Newest';
                        });
                      },
                      child: const Text('Clear All', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => appState.refreshRoutes(),
              child: filteredRoutes.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 40),
                        EmptyStateWidget(
                          title: _searchQuery.isEmpty && !hasActiveFilters
                              ? 'No Routes Found'
                              : 'No Matching Routes',
                          message: _searchQuery.isEmpty && !hasActiveFilters
                              ? 'Pull down to refresh or tap below to create a route.'
                              : 'No routes match your search or filter criteria.',
                          buttonText: _searchQuery.isEmpty && !hasActiveFilters ? '+ Add Route' : null,
                          onButtonPressed: _searchQuery.isEmpty && !hasActiveFilters
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const RouteFormScreen()),
                                  );
                                }
                              : null,
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                      itemCount: filteredRoutes.length,
                      itemBuilder: (context, index) {
                        final item = filteredRoutes[index];
                        return _RouteCard(item: item);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final ViharRoute item;

  const _RouteCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RouteDetailScreen(routeId: item.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: AppTheme.accentColor),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('dd MMM yyyy').format(item.viharDate),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.status.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${item.fromLocation}  →  ${item.toLocation}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (item.viharName.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 15, color: AppTheme.primaryColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Vihar: ${item.viharName}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('District:', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        Text(item.district, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('District Incharge:', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        Text(item.districtInchargeInfo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
