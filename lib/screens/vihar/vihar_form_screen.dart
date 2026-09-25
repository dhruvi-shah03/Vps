import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/app_state.dart';
import '../../services/report_service.dart';
import '../../widgets/app_widgets.dart';

class ViharFormScreen extends StatefulWidget {
  final Vihar? vihar;
  final AppState? appState;

  const ViharFormScreen({super.key, this.vihar, this.appState});

  @override
  State<ViharFormScreen> createState() => _ViharFormScreenState();
}

class _ViharFormScreenState extends State<ViharFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedMahatmaId;
  Mahatma? _selectedMahatma;

  // Mahatma Section Fields - NOT prefilled for new Vihar
  late TextEditingController _mahatmaController;
  late TextEditingController _letterNoController;
  late TextEditingController _thanaNoController;
  late TextEditingController _salutationController;
  String? _selectedSalutation;
  bool _isActive = true;

  // Primary Vihar Information Fields - NOT prefilled for new Vihar
  DateTime _viharDate = DateTime.now();
  late TextEditingController _fromLocationController;
  late TextEditingController _toLocationController;
  late TextEditingController _districtController;
  late TextEditingController _inchargeController;
  String? _selectedDistrict;
  String? _selectedIncharge;

  // Dynamic Additional Routes / Stops
  final List<AdditionalRouteStop> _additionalStops = [];

  bool _isLoading = false;
  bool _hasCheckedData = false;

  AppState get _state {
    if (widget.appState != null) return widget.appState!;
    try {
      return AppStateScope.of(context);
    } catch (_) {
      return AppState.instance;
    }
  }

  @override
  void initState() {
    super.initState();
    final v = widget.vihar;

    if (v != null) {
      // Editing existing Vihar
      _selectedMahatmaId = v.mahatmaId;
      _mahatmaController = TextEditingController(text: v.mahatmaName);
      _letterNoController = TextEditingController(text: v.letterNo.isNotEmpty ? v.letterNo : (v.notes.isNotEmpty ? v.notes : 'L-'));
      _thanaNoController = TextEditingController(text: v.thanaNo);
      _salutationController = TextEditingController(text: v.salutation);
      _selectedSalutation = v.salutation.isNotEmpty ? v.salutation : null;
      _isActive = v.active;
      _viharDate = v.startDate;
      _fromLocationController = TextEditingController(text: v.startLocation);
      _toLocationController = TextEditingController(text: v.endLocation);
      _selectedDistrict = v.routes.isNotEmpty && v.routes.first.district.isNotEmpty ? v.routes.first.district : null;
      _selectedIncharge = v.routes.isNotEmpty && v.routes.first.districtInchargeInfo.isNotEmpty ? v.routes.first.districtInchargeInfo : null;
      _districtController = TextEditingController(text: _selectedDistrict ?? '');
      _inchargeController = TextEditingController(text: _selectedIncharge ?? '');

      // Populate existing additional routes if any
      if (v.routes.length > 1) {
        for (int i = 1; i < v.routes.length; i++) {
          final r = v.routes[i];
          _additionalStops.add(AdditionalRouteStop(
            id: r.id.isNotEmpty ? r.id : 'stop_${DateTime.now().microsecondsSinceEpoch}_$i',
            initialDate: r.viharDate,
            initialStop: r.fromLocation,
            initialNext: r.toLocation,
            selectedIncharge: r.districtInchargeInfo.isNotEmpty ? r.districtInchargeInfo : null,
          ));
        }
      }
    } else {
      // Creating NEW Vihar: Prefill Letter No with 'L-'
      _selectedMahatmaId = null;
      _selectedMahatma = null;
      _mahatmaController = TextEditingController(text: '');
      _letterNoController = TextEditingController(text: 'L-');
      _thanaNoController = TextEditingController(text: '');
      _salutationController = TextEditingController(text: '');
      _selectedSalutation = null;
      _isActive = false;
      _viharDate = DateTime.now();
      _fromLocationController = TextEditingController(text: '');
      _toLocationController = TextEditingController(text: '');
      _districtController = TextEditingController(text: '');
      _inchargeController = TextEditingController(text: '');
      _selectedDistrict = null;
      _selectedIncharge = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = _state;
    if (!_hasCheckedData) {
      _hasCheckedData = true;
      if (state.mahatmas.isEmpty && !state.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            state.loadAllData();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _mahatmaController.dispose();
    _letterNoController.dispose();
    _thanaNoController.dispose();
    _salutationController.dispose();
    _fromLocationController.dispose();
    _toLocationController.dispose();
    _districtController.dispose();
    _inchargeController.dispose();
    for (var stop in _additionalStops) {
      stop.dispose();
    }
    super.dispose();
  }

  void _onMahatmaSelected(Mahatma m) {
    setState(() {
      _selectedMahatma = m;
      _selectedMahatmaId = m.id;
      _mahatmaController.text = '${m.nameEnglish} (${m.code.isNotEmpty ? m.code : m.id})';
      if ((_letterNoController.text.trim().isEmpty || _letterNoController.text.trim() == 'L-') && m.letterNo.isNotEmpty) {
        _letterNoController.text = m.letterNo;
      }
      if (_thanaNoController.text.isEmpty && m.thanaNo.isNotEmpty) {
        _thanaNoController.text = m.thanaNo;
      }
      if (m.salutation.isNotEmpty) {
        _selectedSalutation = m.salutation;
        _salutationController.text = m.salutation;
      }
    });
  }

  void _onDistrictSelected(String districtName) {
    _districtController.text = districtName;
    _selectedDistrict = districtName;

    final state = _state;
    // 1. Direct incharge relation on District model
    final matchedDistrict = state.districts
        .where((d) => d.name.toLowerCase() == districtName.toLowerCase())
        .firstOrNull;

    String? autoIncharge;
    if (matchedDistrict != null && matchedDistrict.inchargeName.isNotEmpty) {
      autoIncharge = matchedDistrict.inchargeName;
    }

    // 2. DistrictIncharge model
    if (autoIncharge == null || autoIncharge.isEmpty) {
      final matchedIncharge = state.incharges.where((di) {
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
      _inchargeController.text = autoIncharge;
      _selectedIncharge = autoIncharge;
    }
    setState(() {});
  }

  // --- Quick Add Dialogs for Inline Creation ---
  Future<void> _quickAddMahatmaDialog() async {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController();
    final nameEnCtrl = TextEditingController();
    final nameGuCtrl = TextEditingController();
    final nameHiCtrl = TextEditingController();
    final contactPersonCtrl = TextEditingController();
    final contactNumberCtrl = TextEditingController();
    final letterNoCtrl = TextEditingController(text: 'L-');
    final thanaNoCtrl = TextEditingController();
    String selectedSamuday = '';
    final samudayCtrl = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.person_add_outlined, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Expanded(
                child: Text('Add New Mahatma', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Code / ID *',
                        hintText: 'e.g. S123 (Must be unique)',
                        prefixIcon: Icon(Icons.qr_code, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Code is required';
                        final clean = val.trim().toLowerCase();
                        if (_state.mahatmas.any((m) => m.code.trim().toLowerCase() == clean)) {
                          return 'Code "$val" is already in use';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameEnCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Name English *',
                        hintText: 'Enter name in English',
                        prefixIcon: Icon(Icons.person, size: 20),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'English name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameGuCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Name Gujarati',
                        hintText: 'ગુજરાતી નામ',
                        prefixIcon: Icon(Icons.translate, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameHiCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Name Hindi',
                        hintText: 'हिन्दी नाम',
                        prefixIcon: Icon(Icons.translate, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GoogleSearchTypeAhead<String>(
                      label: 'Samuday',
                      hint: 'Type samuday name...',
                      prefixIcon: Icons.groups_outlined,
                      controller: samudayCtrl,
                      suggestions: (_state.samudays.isNotEmpty
                          ? _state.samudays.map((s) => s.name).toSet().toList()
                          : ['General']),
                      onAddNew: () => _quickAddSamudayDialog(onCreated: (newName) {
                        setDlgState(() {
                          selectedSamuday = newName;
                          samudayCtrl.text = newName;
                        });
                      }),
                      onAddNewText: '+ Add Samuday',
                      filter: (s, q) => s.toLowerCase().contains(q.toLowerCase()),
                      titleBuilder: (s) => s,
                      onSelected: (s) {
                        setDlgState(() {
                          selectedSamuday = s;
                          samudayCtrl.text = s;
                        });
                      },
                      onChanged: (val) {
                        selectedSamuday = val;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: contactPersonCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Contact Person / Sevak',
                        prefixIcon: Icon(Icons.support_agent, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: contactNumberCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact Number',
                        prefixIcon: Icon(Icons.phone, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: letterNoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Letter No',
                        prefixIcon: Icon(Icons.article_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: thanaNoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Thana No',
                        prefixIcon: Icon(Icons.numbers, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDlgState(() => isSubmitting = true);
                      try {
                        final newM = Mahatma(
                          id: 'm_${DateTime.now().millisecondsSinceEpoch}',
                          code: codeCtrl.text.trim(),
                          nameEnglish: nameEnCtrl.text.trim(),
                          nameGujarati: nameGuCtrl.text.trim(),
                          nameHindi: nameHiCtrl.text.trim(),
                          samuday: selectedSamuday.trim().isNotEmpty ? selectedSamuday.trim() : samudayCtrl.text.trim(),
                          contactPerson: contactPersonCtrl.text.trim(),
                          sevakName: contactPersonCtrl.text.trim(),
                          contactNumber: contactNumberCtrl.text.trim(),
                          letterNo: letterNoCtrl.text.trim(),
                          thanaNo: thanaNoCtrl.text.trim(),
                        );
                        await _state.addMahatma(newM);
                        if (mounted) {
                          _onMahatmaSelected(newM);
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Mahatma "${newM.nameEnglish}" added successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDlgState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to add Mahatma: $e'), backgroundColor: Colors.redAccent),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('ADD MAHATMA'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _quickAddSamudayDialog({ValueChanged<String>? onCreated}) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.groups_outlined, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Expanded(
                child: Text('Add New Samuday', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Samuday Name *',
                        hintText: 'e.g. Achal Gachha, Tapagachha',
                        prefixIcon: Icon(Icons.groups, size: 20),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Samuday name is required' : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDlgState(() => isSubmitting = true);
                      final name = nameCtrl.text.trim();
                      try {
                        final newS = Samuday(
                          id: 'sam_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                        );
                        await _state.addSamuday(newS);
                        if (mounted) {
                          onCreated?.call(name);
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Samuday "$name" added successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDlgState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to add Samuday: $e'), backgroundColor: Colors.redAccent),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('ADD SAMUDAY'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _quickAddSalutationDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.badge_outlined, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Expanded(
                child: Text('Add Salutation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Salutation Title *',
                        hintText: 'e.g. Pujya, Shri, D.G.P., C.P.',
                        prefixIcon: Icon(Icons.title, size: 20),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Salutation title is required' : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDlgState(() => isSubmitting = true);
                      final title = titleCtrl.text.trim();
                      try {
                        final newS = Salutation(
                          id: 's_${DateTime.now().millisecondsSinceEpoch}',
                          title: title,
                          nameEnglish: title,
                        );
                        await _state.addSalutation(newS);
                        if (mounted) {
                          setState(() {
                            _selectedSalutation = title;
                            _salutationController.text = title;
                          });
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Salutation "$title" added successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDlgState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to add Salutation: $e'), backgroundColor: Colors.redAccent),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('ADD SALUTATION'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _quickAddVillageDialog({
    required bool isFrom,
    AdditionalRouteStop? stop,
    bool isStopNext = false,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameEnCtrl = TextEditingController();
    final nameGuCtrl = TextEditingController();
    String selectedDistrict = _selectedDistrict ??
        (_state.districts.isNotEmpty ? _state.districts.first.name : 'Ahmedabad');
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.location_city, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Expanded(
                child: Text('Add New Village / Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameEnCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Village Name (English) *',
                    hintText: 'e.g. Gandhinagar',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Village name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameGuCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Village Name (Gujarati)',
                    hintText: 'દા.ત. ગાંધીનગર',
                    prefixIcon: Icon(Icons.translate, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _state.districts.any((d) => d.name == selectedDistrict)
                      ? selectedDistrict
                      : (_state.districts.isNotEmpty ? _state.districts.first.name : null),
                  decoration: const InputDecoration(
                    labelText: 'District',
                    prefixIcon: Icon(Icons.map_outlined, size: 20),
                  ),
                  items: (_state.districts.isNotEmpty
                          ? _state.districts.map((d) => d.name).toSet().toList()
                          : ['Ahmedabad', 'Gandhinagar', 'Surat'])
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedDistrict = val);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDlgState(() => isSubmitting = true);
                      final nameEn = nameEnCtrl.text.trim();
                      final nameGu = nameGuCtrl.text.trim();
                      try {
                        final newV = Village(
                          id: 'v_${DateTime.now().millisecondsSinceEpoch}',
                          name: nameEn,
                          nameEnglish: nameEn,
                          nameGujarati: nameGu,
                          districtName: selectedDistrict,
                        );
                        await _state.addVillage(newV);
                        if (mounted) {
                          setState(() {
                            if (stop != null) {
                              if (isStopNext) {
                                stop.nextDestinationController.text = nameEn;
                              } else {
                                stop.stopLocationController.text = nameEn;
                              }
                            } else {
                              if (isFrom) {
                                _fromLocationController.text = nameEn;
                              } else {
                                _toLocationController.text = nameEn;
                              }
                            }
                          });
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Village "$nameEn" added successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDlgState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to add Village: $e'), backgroundColor: Colors.redAccent),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('ADD VILLAGE'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _quickAddDistrictDialog() async {
    final formKey = GlobalKey<FormState>();
    final distCtrl = TextEditingController();
    final inchargeCtrl = TextEditingController();
    final inchargePhoneCtrl = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.map_outlined, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Expanded(
                child: Text('Add New District', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: distCtrl,
                      decoration: const InputDecoration(
                        labelText: 'District Name *',
                        hintText: 'e.g. Anand, Bharuch',
                        prefixIcon: Icon(Icons.location_city, size: 20),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'District name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Assign / Add District Incharge (Optional)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: inchargeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Incharge Name',
                              hintText: 'e.g. Rajesh Shah',
                              prefixIcon: Icon(Icons.person_outline, size: 20),
                              fillColor: Colors.white,
                              filled: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: inchargePhoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Incharge Phone',
                              hintText: 'e.g. 9876543210',
                              prefixIcon: Icon(Icons.phone_outlined, size: 20),
                              fillColor: Colors.white,
                              filled: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDlgState(() => isSubmitting = true);
                      final distName = distCtrl.text.trim();
                      final inchargeName = inchargeCtrl.text.trim();
                      final inchargePhone = inchargePhoneCtrl.text.trim();
                      try {
                        if (inchargeName.isNotEmpty) {
                          final newIncharge = DistrictIncharge(
                            id: 'di_${DateTime.now().millisecondsSinceEpoch}',
                            name: inchargeName,
                            district: distName,
                            phone: inchargePhone,
                          );
                          await _state.addDistrictIncharge(newIncharge);
                        }
                        final newD = District(
                          id: 'd_${DateTime.now().millisecondsSinceEpoch}',
                          name: distName,
                          inchargeName: inchargeName,
                          state: 'Gujarat',
                        );
                        await _state.addDistrict(newD);
                        if (mounted) {
                          _onDistrictSelected(distName);
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('District "$distName" added successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDlgState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to add District: $e'), backgroundColor: Colors.redAccent),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('ADD DISTRICT'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _quickAddInchargeDialog({AdditionalRouteStop? stop}) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedDistrict = _selectedDistrict ??
        (_state.districts.isNotEmpty ? _state.districts.first.name : 'Gujarat');
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.security_outlined, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Expanded(
                child: Text('Add District Incharge', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Incharge Name *',
                    hintText: 'e.g. Ramesh Patel',
                    prefixIcon: Icon(Icons.person, size: 20),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Incharge name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g. 9876543210',
                    prefixIcon: Icon(Icons.phone, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _state.districts.any((d) => d.name == selectedDistrict)
                      ? selectedDistrict
                      : (_state.districts.isNotEmpty ? _state.districts.first.name : null),
                  decoration: const InputDecoration(
                    labelText: 'District',
                    prefixIcon: Icon(Icons.map_outlined, size: 20),
                  ),
                  items: (_state.districts.isNotEmpty
                          ? _state.districts.map((d) => d.name).toSet().toList()
                          : ['Gujarat', 'Ahmedabad', 'Gandhinagar'])
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedDistrict = val);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDlgState(() => isSubmitting = true);
                      final name = nameCtrl.text.trim();
                      final phone = phoneCtrl.text.trim();
                      try {
                        final newIncharge = DistrictIncharge(
                          id: 'di_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          district: selectedDistrict,
                          phone: phone,
                        );
                        await _state.addDistrictIncharge(newIncharge);
                        final formatted = phone.isNotEmpty ? '$name - $phone' : '$name ($selectedDistrict)';
                        if (mounted) {
                          setState(() {
                            if (stop != null) {
                              stop.inchargeController.text = formatted;
                              stop.selectedIncharge = formatted;
                            } else {
                              _inchargeController.text = formatted;
                              _selectedIncharge = formatted;
                            }
                          });
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Incharge "$name" added successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDlgState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to add Incharge: $e'), backgroundColor: Colors.redAccent),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('ADD INCHARGE'),
            ),
          ],
        ),
      ),
    );
  }

  void _addAnotherStop() {
    setState(() {
      String nextStopFrom = '';
      DateTime nextDate = _viharDate.add(const Duration(days: 1));
      if (_additionalStops.isNotEmpty) {
        nextStopFrom = _additionalStops.last.nextDestinationController.text.trim();
        nextDate = _additionalStops.last.dateTime.add(const Duration(days: 1));
      } else {
        nextStopFrom = _toLocationController.text.trim();
        nextDate = _viharDate.add(const Duration(days: 1));
      }

      _additionalStops.add(AdditionalRouteStop(
        id: 'stop_${DateTime.now().microsecondsSinceEpoch}',
        initialDate: nextDate,
        initialStop: nextStopFrom,
        initialNext: '',
        selectedIncharge: _selectedIncharge,
      ));
    });
  }

  void _removeStop(int index) {
    setState(() {
      final removed = _additionalStops.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _viharDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_viharDate),
      );
      if (mounted) {
        setState(() {
          _viharDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime?.hour ?? 8,
            pickedTime?.minute ?? 0,
          );
        });
      }
    }
  }

  Future<void> _pickDateTimeForStop(AdditionalRouteStop stop) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: stop.dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(stop.dateTime),
      );
      if (mounted) {
        setState(() {
          stop.dateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime?.hour ?? 8,
            pickedTime?.minute ?? 0,
          );
        });
      }
    }
  }

  Future<void> _triggerReportPrint(String language) async {
    if (widget.vihar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please save this Vihar first before downloading reports.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final intId = int.tryParse(widget.vihar!.id);
    if (intId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Vihar record ID.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final state = _state;
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
                'Downloading $language report from Odoo...',
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
      final pdfBytes = await state.downloadReport(intId, langEnum);
      if (mounted) {
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

        if (mounted) {
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
                          : '$language report downloaded successfully ($filename)',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download $language report: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMahatma == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Mahatma'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_fromLocationController.text.trim().isEmpty || _toLocationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('From and To locations are required'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    final state = _state;
    final isEdit = widget.vihar != null;

    final convertedRoutes = <ViharRoute>[];

    final fromLoc = _fromLocationController.text.trim();
    final toLoc = _toLocationController.text.trim();
    final districtVal = _districtController.text.trim().isNotEmpty
        ? _districtController.text.trim()
        : (_selectedDistrict ?? (state.districts.isNotEmpty ? state.districts.first.name : 'Ahmedabad'));
    final inchargeVal = _inchargeController.text.trim().isNotEmpty
        ? _inchargeController.text.trim()
        : (_selectedIncharge ?? (state.incharges.isNotEmpty ? state.incharges.first.name : ''));

    // 1. Primary Route
    convertedRoutes.add(ViharRoute(
      id: isEdit && widget.vihar!.routes.isNotEmpty
          ? widget.vihar!.routes.first.id
          : 'vr_${DateTime.now().millisecondsSinceEpoch}_0',
      viharDate: _viharDate,
      fromLocation: fromLoc,
      toLocation: toLoc,
      district: districtVal,
      districtInchargeInfo: inchargeVal,
      distanceKm: 25.0,
      status: 'Upcoming',
    ));

    // 2. Additional Stops / Routes
    for (int i = 0; i < _additionalStops.length; i++) {
      final stop = _additionalStops[i];
      final from = stop.stopLocationController.text.trim();
      final to = stop.nextDestinationController.text.trim();
      final stopIncharge = stop.inchargeController.text.trim().isNotEmpty
          ? stop.inchargeController.text.trim()
          : (stop.selectedIncharge ?? inchargeVal);
      if (from.isNotEmpty || to.isNotEmpty) {
        convertedRoutes.add(ViharRoute(
          id: 'vr_${DateTime.now().millisecondsSinceEpoch}_${i + 1}',
          viharDate: stop.dateTime,
          fromLocation: from.isNotEmpty ? from : toLoc,
          toLocation: to.isNotEmpty ? to : from,
          district: districtVal,
          districtInchargeInfo: stopIncharge,
          distanceKm: 25.0,
          status: 'Upcoming',
        ));
      }
    }

    final firstRoute = convertedRoutes.first;
    final lastRoute = convertedRoutes.last;

    final item = Vihar(
      id: isEdit ? widget.vihar!.id : 'v_${DateTime.now().millisecondsSinceEpoch}',
      mahatmaId: _selectedMahatma!.id,
      mahatmaName: _selectedMahatma!.nameEnglish,
      startLocation: firstRoute.fromLocation,
      endLocation: lastRoute.toLocation,
      startDate: firstRoute.viharDate,
      endDate: lastRoute.viharDate.add(const Duration(hours: 4)),
      status: widget.vihar?.status ?? 'Planned',
      notes: _letterNoController.text.trim(),
      letterNo: _letterNoController.text.trim(),
      salutation: _salutationController.text.trim().isNotEmpty
          ? _salutationController.text.trim()
          : (_selectedSalutation ?? 'Shri'),
      thanaNo: _thanaNoController.text.trim(),
      sevakName: _selectedMahatma!.sevakName.isNotEmpty ? _selectedMahatma!.sevakName : _selectedMahatma!.contactPerson,
      contactNumber: _selectedMahatma!.contactNumber,
      active: _isActive,
      routes: convertedRoutes,
    );

    try {
      if (isEdit) {
        await state.updateVihar(item);
      } else {
        await state.addVihar(item);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Vihar updated successfully' : 'Vihar added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save Vihar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final isEdit = widget.vihar != null;

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final mahatmaList = state.mahatmas;

        // Dropdown options
        final districtOptions = state.districts.map((d) => d.name).toSet().toList();
        if (districtOptions.isEmpty) districtOptions.addAll(['Ahmedabad Chity', 'Ahmedabad', 'Gandhinagar', 'Surat', 'Rajkot', 'Vadodara']);

        final inchargeOptions = state.incharges.map((di) => '${di.name} (${di.district})').toSet().toList();
        if (inchargeOptions.isEmpty) inchargeOptions.addAll(['Ayush Shah (Gujarat)', 'Rohan Mehta (Gujarat)', 'Bhavik Patel (Gujarat)']);

        final salutationOptions = state.salutations.map((s) => s.title).toSet().toList();
        if (salutationOptions.isEmpty) salutationOptions.addAll(['Shri', 'Pu.', 'Pujya', 'D.G.P.', 'C.P.', 'S.P.']);

        final villageNames = state.villages
            .map((v) => v.name)
            .where((n) => n.trim().isNotEmpty)
            .toSet()
            .toList();
        if (villageNames.isEmpty) {
          villageNames.addAll(['Koth', 'Dantali', 'Navrangpura', 'Sarandi', 'Katargam', 'Bilimora', 'Asuria', 'Pritam Nagar', 'Shrimali Pol']);
        }

        // Deduplicate mahatmas for dropdown
        final uniqueMahatmas = <Mahatma>[];
        final seenIds = <String>{};
        for (final m in mahatmaList) {
          if (m.id.isNotEmpty && seenIds.add(m.id)) {
            uniqueMahatmas.add(m);
          }
        }

        // Resolve selected mahatma only if ID is chosen
        if (_selectedMahatmaId != null) {
          try {
            _selectedMahatma = uniqueMahatmas.firstWhere((m) => m.id == _selectedMahatmaId);
          } catch (_) {
            _selectedMahatma = null;
          }
        } else {
          _selectedMahatma = null;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(isEdit ? 'Edit Vihar' : 'Add Vihar'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Data',
                onPressed: () => state.loadAllData(),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => state.loadAllData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Progress indicator when refreshing
                    if (state.isLoading) ...[
                      const LinearProgressIndicator(minHeight: 3),
                      const SizedBox(height: 12),
                    ],

                    // 1. TOP THREE PRINTING BUTTONS IN ONE LINE WITH GOOD MANNER
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.print_outlined, size: 16, color: AppTheme.primaryColor),
                              const SizedBox(width: 6),
                              const Text(
                                'Print Vihar Reports',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 38,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _triggerReportPrint('English'),
                                    icon: const Icon(Icons.print, size: 14),
                                    label: const Text(
                                      'English',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 38,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _triggerReportPrint('Gujarati'),
                                    icon: const Icon(Icons.print, size: 14),
                                    label: const Text(
                                      'ગુજરાતી',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.secondaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 38,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _triggerReportPrint('Hindi'),
                                    icon: const Icon(Icons.print, size: 14),
                                    label: const Text(
                                      'हिन्दी',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD97706),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SECTION 1 — MAHATMA'S INFORMATION
                    const SectionHeader(title: "MAHATMA'S INFORMATION"),
                    const SizedBox(height: 8),

                    if (uniqueMahatmas.isEmpty && !state.isLoading) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Loading Mahatmas from Odoo...',
                                style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                              ),
                            ),
                            TextButton(
                              onPressed: () => state.loadAllData(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('RELOAD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Select Mahatma Typeahead (Search like Google Chrome)
                    GoogleSearchTypeAhead<Mahatma>(
                      label: 'Code / Select Mahatma',
                      hint: 'Type mahatma name or code (e.g. S123)...',
                      isRequired: true,
                      prefixIcon: Icons.person_search,
                      controller: _mahatmaController,
                      suggestions: uniqueMahatmas,
                      onAddNew: _quickAddMahatmaDialog,
                      onAddNewText: '+ Add Mahatma',
                      filter: (m, q) =>
                          m.nameEnglish.toLowerCase().contains(q.toLowerCase()) ||
                          m.code.toLowerCase().contains(q.toLowerCase()) ||
                          m.nameGujarati.contains(q) ||
                          m.nameHindi.contains(q),
                      titleBuilder: (m) => '${m.nameEnglish} (${m.code.isNotEmpty ? m.code : m.id})',
                      subtitleBuilder: (m) =>
                          'Code: ${m.code.isNotEmpty ? m.code : m.id} • Samuday: ${m.samuday.isNotEmpty ? m.samuday : "-"}',
                      onSelected: (m) => _onMahatmaSelected(m),
                      onChanged: (val) {
                        if (val.trim().isEmpty) {
                          setState(() {
                            _selectedMahatma = null;
                            _selectedMahatmaId = null;
                          });
                        }
                      },
                    ),

                    // 2. MAHATMA DETAILS CARD EXACTLY AFTER SELECT MAHATMA (ONLY VISIBLE ONCE SELECTED)
                    if (_selectedMahatma != null) ...[
                      Container(
                        margin: const EdgeInsets.only(top: 4, bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 18, color: AppTheme.primaryColor),
                                const SizedBox(width: 6),
                                const Text(
                                  'Selected Mahatma Details',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16, color: Color(0xFFE2E8F0)),
                            _MahatmaFieldRow(
                              label: 'Code',
                              value: _selectedMahatma!.code.isNotEmpty ? _selectedMahatma!.code : _selectedMahatma!.id,
                              label2: 'Samuday',
                              value2: _selectedMahatma!.samuday.isNotEmpty ? _selectedMahatma!.samuday : '-',
                            ),
                            const SizedBox(height: 8),
                            _MahatmaFieldRow(
                              label: 'Name English',
                              value: _selectedMahatma!.nameEnglish,
                              label2: 'Contact Person',
                              value2: _selectedMahatma!.contactPerson.isNotEmpty
                                  ? _selectedMahatma!.contactPerson
                                  : (_selectedMahatma!.sevakName.isNotEmpty ? _selectedMahatma!.sevakName : '-'),
                            ),
                            const SizedBox(height: 8),
                            _MahatmaFieldRow(
                              label: 'Name Gujarati',
                              value: _selectedMahatma!.nameGujarati.isNotEmpty ? _selectedMahatma!.nameGujarati : '-',
                              label2: 'Contact Number',
                              value2: _selectedMahatma!.contactNumber.isNotEmpty ? _selectedMahatma!.contactNumber : '-',
                            ),
                            const SizedBox(height: 8),
                            _MahatmaFieldRow(
                              label: 'Name Hindi',
                              value: _selectedMahatma!.nameHindi.isNotEmpty ? _selectedMahatma!.nameHindi : '-',
                              label2: 'Thana No',
                              value2: _selectedMahatma!.thanaNo.isNotEmpty ? _selectedMahatma!.thanaNo : '-',
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Letter No
                    AppTextField(
                      label: 'Letter No',
                      hint: 'e.g. 2024/001',
                      controller: _letterNoController,
                    ),

                    // Salutations Typeahead (Search like Google Chrome)
                    GoogleSearchTypeAhead<String>(
                      label: 'Salutations',
                      hint: 'Type salutation (e.g. Shri, D.G.P., C.P.)...',
                      prefixIcon: Icons.badge_outlined,
                      controller: _salutationController,
                      suggestions: salutationOptions,
                      onAddNew: _quickAddSalutationDialog,
                      onAddNewText: '+ Add Salutation',
                      filter: (s, q) => s.toLowerCase().contains(q.toLowerCase()),
                      titleBuilder: (s) => s,
                      onSelected: (s) {
                        setState(() {
                          _selectedSalutation = s;
                          _salutationController.text = s;
                        });
                      },
                      onChanged: (val) {
                        _selectedSalutation = val;
                      },
                    ),

                    // Thana No
                    AppTextField(
                      label: 'Thana No',
                      hint: 'e.g. Thana-01',
                      controller: _thanaNoController,
                    ),

                    // Active Checkbox
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CheckboxListTile(
                        title: const Text('Active', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text(_isActive ? 'This Vihar is marked as Active' : 'This Vihar is marked as Inactive', style: const TextStyle(fontSize: 12)),
                        value: _isActive,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (val) => setState(() => _isActive = val ?? true),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(thickness: 1.5),

                    // SECTION 2 — VIHAR'S INFORMATION
                    const SectionHeader(title: "VIHAR'S INFORMATION"),
                    const SizedBox(height: 12),

                    // 1. Vihar Date & Time
                    const Text(
                      'Vihar Date & Time',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickDateTime,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 18, color: AppTheme.primaryColor),
                                const SizedBox(width: 10),
                                Text(
                                  DateFormat('dd/MM/yyyy hh:mm a').format(_viharDate),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondaryLight),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. From Location (Search like Google Chrome)
                    GoogleSearchTypeAhead<String>(
                      label: 'From Location',
                      hint: 'Type from location / village...',
                      isRequired: true,
                      prefixIcon: Icons.location_on_outlined,
                      controller: _fromLocationController,
                      suggestions: villageNames,
                      onAddNew: () => _quickAddVillageDialog(isFrom: true),
                      onAddNewText: '+ Add Village',
                      filter: (v, q) => v.toLowerCase().contains(q.toLowerCase()),
                      titleBuilder: (v) => v,
                      onSelected: (v) {
                        setState(() => _fromLocationController.text = v);
                      },
                    ),

                    // 3. To Location (Search like Google Chrome)
                    GoogleSearchTypeAhead<String>(
                      label: 'To Location',
                      hint: 'Type destination village...',
                      isRequired: true,
                      prefixIcon: Icons.flag_outlined,
                      controller: _toLocationController,
                      suggestions: villageNames,
                      onAddNew: () => _quickAddVillageDialog(isFrom: false),
                      onAddNewText: '+ Add Village',
                      filter: (v, q) => v.toLowerCase().contains(q.toLowerCase()),
                      titleBuilder: (v) => v,
                      onSelected: (v) {
                        setState(() => _toLocationController.text = v);
                      },
                    ),

                    // 4. District (Search like Google Chrome & Autofills Incharge)
                    GoogleSearchTypeAhead<String>(
                      label: 'District',
                      hint: 'Type district name...',
                      prefixIcon: Icons.map_outlined,
                      controller: _districtController,
                      suggestions: districtOptions,
                      onAddNew: _quickAddDistrictDialog,
                      onAddNewText: '+ Add District',
                      filter: (d, q) => d.toLowerCase().contains(q.toLowerCase()),
                      titleBuilder: (d) => d,
                      onSelected: (d) => _onDistrictSelected(d),
                      onChanged: (val) {
                        _selectedDistrict = val;
                        final match = districtOptions.where((d) => d.toLowerCase() == val.trim().toLowerCase()).firstOrNull;
                        if (match != null) {
                          _onDistrictSelected(match);
                        }
                      },
                    ),

                    // 5. District Incharge (Search like Google Chrome)
                    GoogleSearchTypeAhead<String>(
                      label: 'District Incharge',
                      hint: 'Type district incharge name...',
                      prefixIcon: Icons.security_outlined,
                      controller: _inchargeController,
                      suggestions: inchargeOptions,
                      onAddNew: () => _quickAddInchargeDialog(),
                      onAddNewText: '+ Add Incharge',
                      filter: (di, q) => di.toLowerCase().contains(q.toLowerCase()),
                      titleBuilder: (di) => di,
                      onSelected: (di) {
                        setState(() {
                          _selectedIncharge = di;
                          _inchargeController.text = di;
                        });
                      },
                      onChanged: (val) {
                        _selectedIncharge = val;
                      },
                    ),

                    // 6. Dynamic Additional Routes / Stops
                    if (_additionalStops.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ..._additionalStops.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final stop = entry.value;

                        return Container(
                          key: ValueKey(stop.id),
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF0D8A74),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Route / Stop #${idx + 2}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  InkWell(
                                    onTap: () => _removeStop(idx),
                                    borderRadius: BorderRadius.circular(6),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, size: 16, color: Color(0xFFE11D48)),
                                          SizedBox(width: 4),
                                          Text(
                                            'Remove',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFFE11D48),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(height: 1, color: Color(0xFFE2E8F0)),
                              const SizedBox(height: 12),

                              // Stop Date & Time Field
                              const Text(
                                'Stop Date & Time',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => _pickDateTimeForStop(stop),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_outlined, size: 18, color: AppTheme.primaryColor),
                                          const SizedBox(width: 10),
                                          Text(
                                            DateFormat('dd/MM/yyyy hh:mm a').format(stop.dateTime),
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                      const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondaryLight),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Stop Location Field (Search like Google Chrome)
                              GoogleSearchTypeAhead<String>(
                                label: 'Stop / Transit Location',
                                hint: 'Type stop location...',
                                prefixIcon: Icons.location_on_outlined,
                                controller: stop.stopLocationController,
                                suggestions: villageNames,
                                onAddNew: () => _quickAddVillageDialog(isFrom: true, stop: stop, isStopNext: false),
                                onAddNewText: '+ Add Village',
                                filter: (v, q) => v.toLowerCase().contains(q.toLowerCase()),
                                titleBuilder: (v) => v,
                                onSelected: (v) {
                                  setState(() => stop.stopLocationController.text = v);
                                },
                              ),

                              // Next Destination Field (Search like Google Chrome)
                              GoogleSearchTypeAhead<String>(
                                label: 'Next Destination',
                                hint: 'Type next destination...',
                                prefixIcon: Icons.flag_outlined,
                                controller: stop.nextDestinationController,
                                suggestions: villageNames,
                                onAddNew: () => _quickAddVillageDialog(isFrom: false, stop: stop, isStopNext: true),
                                onAddNewText: '+ Add Village',
                                filter: (v, q) => v.toLowerCase().contains(q.toLowerCase()),
                                titleBuilder: (v) => v,
                                onSelected: (v) {
                                  setState(() => stop.nextDestinationController.text = v);
                                },
                              ),

                              // Stop District Incharge Selection (Search like Google Chrome)
                              GoogleSearchTypeAhead<String>(
                                label: 'District Incharge',
                                hint: 'Type incharge for this stop...',
                                prefixIcon: Icons.security_outlined,
                                controller: stop.inchargeController,
                                suggestions: inchargeOptions,
                                onAddNew: () => _quickAddInchargeDialog(stop: stop),
                                onAddNewText: '+ Add Incharge',
                                filter: (di, q) => di.toLowerCase().contains(q.toLowerCase()),
                                titleBuilder: (di) => di,
                                onSelected: (di) {
                                  setState(() {
                                    stop.selectedIncharge = di;
                                    stop.inchargeController.text = di;
                                  });
                                },
                                onChanged: (val) {
                                  stop.selectedIncharge = val;
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 10),

                    // 7. Dashed "+ Add Another Route / Stop" Button
                    InkWell(
                      onTap: _addAnotherStop,
                      borderRadius: BorderRadius.circular(12),
                      child: CustomPaint(
                        painter: _DashedRectPainter(
                          color: const Color(0xFF0D8A74).withValues(alpha: 0.5),
                          strokeWidth: 1.8,
                          gap: 5,
                          radius: 12,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F4F1).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0D8A74),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 15),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Add Another Route / Stop',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D8A74),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          // 8. NON-SCROLLABLE SAVE BUTTON FIXED AT BOTTOM
          bottomNavigationBar: Container(
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
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D8A74),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          isEdit ? 'UPDATE VIHAR' : 'SAVE VIHAR',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dynamic model for additional route / stop
class AdditionalRouteStop {
  final String id;
  DateTime dateTime;
  final TextEditingController stopLocationController;
  final TextEditingController nextDestinationController;
  final TextEditingController inchargeController;
  String? selectedIncharge;

  AdditionalRouteStop({
    required this.id,
    DateTime? initialDate,
    String initialStop = '',
    String initialNext = '',
    this.selectedIncharge,
  })  : dateTime = initialDate ?? DateTime.now(),
        stopLocationController = TextEditingController(text: initialStop),
        nextDestinationController = TextEditingController(text: initialNext),
        inchargeController = TextEditingController(text: selectedIncharge ?? '');

  void dispose() {
    stopLocationController.dispose();
    nextDestinationController.dispose();
    inchargeController.dispose();
  }
}

class _MahatmaFieldRow extends StatelessWidget {
  final String label;
  final String value;
  final String label2;
  final String value2;

  const _MahatmaFieldRow({
    required this.label,
    required this.value,
    required this.label2,
    required this.value2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryLight)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (label2.isNotEmpty)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label2, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryLight)),
                Text(value2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Painter to draw a clean dashed rounded rectangle border matching the Stitch design
class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  _DashedRectPainter({
    required this.color,
    this.strokeWidth = 2,
    this.gap = 5,
    this.radius = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = draw ? 6.0 : gap;
        if (draw) {
          dashPath.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) =>
      color != oldDelegate.color || strokeWidth != oldDelegate.strokeWidth;
}
