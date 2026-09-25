import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/app_state.dart';
import '../../widgets/app_widgets.dart';

class RouteFormScreen extends StatefulWidget {
  final ViharRoute? route;
  final bool isModal;

  const RouteFormScreen({super.key, this.route, this.isModal = false});

  @override
  State<RouteFormScreen> createState() => _RouteFormScreenState();
}

class _RouteFormScreenState extends State<RouteFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fromLocationController;
  late TextEditingController _toLocationController;
  late TextEditingController _districtController;
  late TextEditingController _inchargeInfoController;

  DateTime _viharDate = DateTime.now();
  String? _selectedDistrict;
  String? _selectedViharId;
  String _status = 'Upcoming';
  bool _isLoading = false;

  final List<String> _statusOptions = ['Upcoming', 'Active', 'Completed'];

  @override
  void initState() {
    super.initState();
    final r = widget.route;
    _fromLocationController = TextEditingController(text: r?.fromLocation ?? '');
    _toLocationController = TextEditingController(text: r?.toLocation ?? '');
    _districtController = TextEditingController(text: r?.district ?? '');
    _inchargeInfoController = TextEditingController(text: r?.districtInchargeInfo ?? '');

    _viharDate = r?.viharDate ?? DateTime.now();
    _selectedDistrict = r?.district;
    _selectedViharId = (r?.viharId.isNotEmpty == true) ? r!.viharId : null;
    _status = r?.status ?? 'Upcoming';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = AppStateScope.maybeOf(context);
      if (appState != null && appState.villages.isEmpty && !appState.isLoading) {
        appState.refreshVillages();
      }
    });
  }

  @override
  void dispose() {
    _fromLocationController.dispose();
    _toLocationController.dispose();
    _districtController.dispose();
    _inchargeInfoController.dispose();
    super.dispose();
  }

  void _onDistrictSelected(AppState appState, String districtName) {
    setState(() {
      _selectedDistrict = districtName;
      _districtController.text = districtName;

      // 1. Direct incharge relation on District model
      final matchedDistrict = appState.districts
          .where((d) => d.name.toLowerCase() == districtName.toLowerCase())
          .firstOrNull;

      String? autoIncharge;
      if (matchedDistrict != null && matchedDistrict.inchargeName.isNotEmpty) {
        autoIncharge = matchedDistrict.inchargeName;
      }

      // 2. DistrictIncharge model
      if (autoIncharge == null || autoIncharge.isEmpty) {
        final matchedIncharge = appState.incharges.where((di) {
          final diDist = di.district.toLowerCase();
          final target = districtName.toLowerCase();
          return diDist == target || target.contains(diDist) || diDist.contains(target);
        }).firstOrNull;

        if (matchedIncharge != null) {
          if (matchedIncharge.phone.isNotEmpty) {
            autoIncharge = '${matchedIncharge.name} - ${matchedIncharge.phone}';
          } else {
            autoIncharge = '${matchedIncharge.name} (${matchedIncharge.district})';
          }
        }
      }

      if (autoIncharge != null && autoIncharge.isNotEmpty) {
        _inchargeInfoController.text = autoIncharge;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _viharDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_viharDate),
      );
      setState(() {
        if (time != null) {
          _viharDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        } else {
          _viharDate = picked;
        }
      });
    }
  }

  void _openViharSearchDialog(BuildContext context, List<Vihar> vihars) {
    String filter = '';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
            final results = vihars.where((v) {
            final q = filter.toLowerCase();
            return v.mahatmaName.toLowerCase().contains(q) ||
                v.letterNo.toLowerCase().contains(q) ||
                v.notes.toLowerCase().contains(q) ||
                v.thanaNo.toLowerCase().contains(q);
          }).toList();

          return AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Search: Vihars', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 440,
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by Mahatma, Letter No...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) => setDialogState(() => filter = val),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: results.isEmpty
                        ? const Center(child: Text('No Vihars found'))
                        : ListView.separated(
                            itemCount: results.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (ctx, i) {
                              final v = results[i];
                              final isSelected = v.id == _selectedViharId;
                              return ListTile(
                                dense: true,
                                selected: isSelected,
                                selectedTileColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                title: Text(
                                  v.mahatmaName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(
                                      '${v.letterNo.isNotEmpty ? 'Letter No: ${v.letterNo} | ' : ''}Date: ${DateFormat('dd/MM/yyyy').format(v.startDate)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (v.startLocation.isNotEmpty || v.endLocation.isNotEmpty)
                                      Text(
                                        'Route: ${v.startLocation} → ${v.endLocation}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                                      ),
                                  ],
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedViharId = v.id;
                                  });
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() => _selectedViharId = null);
                  Navigator.pop(ctx);
                },
                child: const Text('CLEAR SELECTION'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CLOSE'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final appState = AppStateScope.of(context);

    final selectedVihar = appState.vihars.cast<Vihar?>().firstWhere(
      (v) => v?.id == _selectedViharId,
      orElse: () => null,
    );

    final isEdit = widget.route != null;
    final item = ViharRoute(
      id: isEdit ? widget.route!.id : 'vr_${DateTime.now().millisecondsSinceEpoch}',
      viharId: _selectedViharId ?? '',
      viharName: selectedVihar?.mahatmaName ?? '',
      viharDate: _viharDate,
      fromLocation: _fromLocationController.text.trim(),
      toLocation: _toLocationController.text.trim(),
      district: _districtController.text.trim().isNotEmpty
          ? _districtController.text.trim()
          : (_selectedDistrict ?? (appState.districts.isNotEmpty ? appState.districts.first.name : 'Ahmedabad')),
      districtInchargeInfo: _inchargeInfoController.text.trim().isEmpty
          ? 'District Incharge'
          : _inchargeInfoController.text.trim(),
      distanceKm: 0.0,
      status: _status,
    );

    if (isEdit) {
      await appState.updateViharRoute(item);
    } else {
      await appState.addViharRoute(item);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Route updated successfully' : 'Route added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isEdit = widget.route != null;

    final villageOptions = appState.villages.map((v) => v.name).toSet().toList();
    villageOptions.sort();

    final districtOptions = appState.districts.map((d) => d.name).toSet().toList();
    if (districtOptions.isEmpty) districtOptions.add('Ahmedabad');
    districtOptions.sort();

    final inchargeOptions = appState.incharges.map((di) {
      if (di.phone.isNotEmpty) {
        return '${di.name} - ${di.phone}';
      }
      return '${di.name} (${di.district})';
    }).toSet().toList();
    inchargeOptions.sort();

    final formContent = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isModal) ...[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Vihar Route' : 'Add Vihar Route',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 16),
              const SizedBox(height: 8),
            ],
            const SectionHeader(title: 'Route Details'),
            const SizedBox(height: 8),

              const Text('Vihar Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMMM yyyy').format(_viharDate),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      const Icon(Icons.calendar_month, size: 20, color: AppTheme.accentColor),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // From Location (Searchable like Google Chrome)
              GoogleSearchTypeAhead<String>(
                label: 'From Location',
                hint: 'Type from location / village...',
                isRequired: true,
                prefixIcon: Icons.location_on_outlined,
                controller: _fromLocationController,
                suggestions: villageOptions,
                filter: (v, q) => v.toLowerCase().contains(q.toLowerCase()),
                titleBuilder: (v) => v,
                onSelected: (v) {
                  setState(() => _fromLocationController.text = v);
                },
                validator: (val) => val == null || val.trim().isEmpty ? 'From Location is required' : null,
              ),

              // To Location (Searchable like Google Chrome)
              GoogleSearchTypeAhead<String>(
                label: 'To Location',
                hint: 'Type destination village...',
                isRequired: true,
                prefixIcon: Icons.flag_outlined,
                controller: _toLocationController,
                suggestions: villageOptions,
                filter: (v, q) => v.toLowerCase().contains(q.toLowerCase()),
                titleBuilder: (v) => v,
                onSelected: (v) {
                  setState(() => _toLocationController.text = v);
                },
                validator: (val) => val == null || val.trim().isEmpty ? 'To Location is required' : null,
              ),

              // District (Searchable like Google Chrome & Autofills Incharge)
              GoogleSearchTypeAhead<String>(
                label: 'District',
                hint: 'Type district name...',
                prefixIcon: Icons.map_outlined,
                controller: _districtController,
                suggestions: districtOptions,
                filter: (d, q) => d.toLowerCase().contains(q.toLowerCase()),
                titleBuilder: (d) => d,
                onSelected: (d) => _onDistrictSelected(appState, d),
                onChanged: (val) {
                  _selectedDistrict = val;
                  final match = districtOptions.where((d) => d.toLowerCase() == val.trim().toLowerCase()).firstOrNull;
                  if (match != null) {
                    _onDistrictSelected(appState, match);
                  }
                },
              ),

              // District Incharge Information (Searchable like Google Chrome)
              GoogleSearchTypeAhead<String>(
                label: 'District Incharge Information',
                hint: 'Type district incharge name or info...',
                prefixIcon: Icons.security_outlined,
                controller: _inchargeInfoController,
                suggestions: inchargeOptions,
                filter: (di, q) => di.toLowerCase().contains(q.toLowerCase()),
                titleBuilder: (di) => di,
                onSelected: (di) {
                  setState(() {
                    _inchargeInfoController.text = di;
                  });
                },
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vihars',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: (_selectedViharId != null && appState.vihars.any((v) => v.id == _selectedViharId))
                          ? _selectedViharId
                          : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: 'Select Vihar',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search, color: AppTheme.primaryColor),
                          tooltip: 'Search Vihars',
                          onPressed: () => _openViharSearchDialog(context, appState.vihars),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('-- Select Vihar --'),
                        ),
                        ...appState.vihars.map((v) {
                          final label = '${v.mahatmaName}${v.letterNo.isNotEmpty ? ' (Letter: ${v.letterNo})' : ''} - ${DateFormat('dd/MM/yyyy').format(v.startDate)}';
                          return DropdownMenuItem<String>(
                            value: v.id,
                            child: Text(label, overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedViharId = val;
                        });
                      },
                    ),
                  ],
                ),
              ),

              AppDropdown<String>(
                label: 'Route Status',
                value: _status,
                items: _statusOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      );

    final bottomSaveButton = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: AppButton(
          text: isEdit ? 'UPDATE ROUTE' : 'SAVE ROUTE',
          color: AppTheme.accentColor,
          isLoading: _isLoading,
          onPressed: _handleSave,
        ),
      ),
    );

    if (widget.isModal) {
      return Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(child: formContent),
              bottomSaveButton,
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Vihar Route' : 'Add Vihar Route'),
      ),
      body: formContent,
      bottomNavigationBar: bottomSaveButton,
    );
  }
}
