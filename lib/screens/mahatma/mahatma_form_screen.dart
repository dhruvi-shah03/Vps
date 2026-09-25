import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/app_state.dart';
import '../../widgets/app_widgets.dart';

class MahatmaFormScreen extends StatefulWidget {
  final Mahatma? mahatma;
  final bool isModal;

  const MahatmaFormScreen({super.key, this.mahatma, this.isModal = false});

  @override
  State<MahatmaFormScreen> createState() => _MahatmaFormScreenState();
}

class _MahatmaFormScreenState extends State<MahatmaFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _nameEngController;
  late TextEditingController _nameGujController;
  late TextEditingController _nameHinController;
  late TextEditingController _contactPersonController;
  late TextEditingController _contactNumberController;
  late TextEditingController _samudayController;

  String? _selectedSamuday;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final m = widget.mahatma;
    _codeController = TextEditingController(text: m?.code ?? '');
    _nameEngController = TextEditingController(text: m?.nameEnglish ?? '');
    _nameGujController = TextEditingController(text: m?.nameGujarati ?? '');
    _nameHinController = TextEditingController(text: m?.nameHindi ?? '');
    _contactPersonController = TextEditingController(
      text: m?.contactPerson.isNotEmpty == true ? m!.contactPerson : (m?.sevakName ?? ''),
    );
    _contactNumberController = TextEditingController(text: m?.contactNumber ?? '');
    _selectedSamuday = m?.samuday;
    _samudayController = TextEditingController(text: m?.samuday ?? '');
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameEngController.dispose();
    _nameGujController.dispose();
    _nameHinController.dispose();
    _contactPersonController.dispose();
    _contactNumberController.dispose();
    _samudayController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = AppStateScope.of(context);
    final enteredCode = _codeController.text.trim();
    final isDuplicate = appState.mahatmas.any((m) {
      if (widget.mahatma != null && m.id == widget.mahatma!.id) {
        return false;
      }
      return m.code.trim().toLowerCase() == enteredCode.toLowerCase();
    });

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot save: Mahatma Code "$enteredCode" is already in use.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final isEdit = widget.mahatma != null;
    final finalSamuday = _samudayController.text.trim();
    final item = Mahatma(
        id: isEdit ? widget.mahatma!.id : 'm_${DateTime.now().millisecondsSinceEpoch}',
        code: _codeController.text.trim(),
        nameEnglish: _nameEngController.text.trim(),
        nameGujarati: _nameGujController.text.trim(),
        nameHindi: _nameHinController.text.trim(),
        contactPerson: _contactPersonController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        samuday: finalSamuday,
        letterNo: widget.mahatma?.letterNo ?? '',
        sevakName: _contactPersonController.text.trim(),
        thanaNo: widget.mahatma?.thanaNo ?? '',
        selectedDate: widget.mahatma?.selectedDate ?? DateTime.now(),
        districtIncharge: widget.mahatma?.districtIncharge ?? '',
        salutation: widget.mahatma?.salutation ?? 'Shri',
        active: widget.mahatma?.active ?? true,
      );

    try {
      if (isEdit) {
        await appState.updateMahatma(item);
      } else {
        await appState.addMahatma(item);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Mahatma updated successfully' : 'Mahatma created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save Mahatma: $e'),
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

  Future<void> _quickAddSamudayDialog() async {
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
                        final appState = AppStateScope.of(context);
                        final newS = Samuday(
                          id: 'sam_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                        );
                        await appState.addSamuday(newS);
                        if (mounted) {
                          setState(() {
                            _selectedSamuday = name;
                            _samudayController.text = name;
                          });
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

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isEdit = widget.mahatma != null;

    final samudayOptions = appState.samudays.map((s) => s.name).toList();

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
                    isEdit ? 'Edit Mahatma' : 'Add Mahatma',
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
            const SectionHeader(title: 'MAHATMA INFORMATION'),
            const SizedBox(height: 12),

              // 1. Code (Primary Key - Unique)
              AppTextField(
                label: 'Code',
                hint: 'e.g. M001',
                controller: _codeController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Code is required';
                  }
                  final cleanCode = val.trim().toLowerCase();
                  final isDuplicate = appState.mahatmas.any((m) {
                    if (widget.mahatma != null && m.id == widget.mahatma!.id) {
                      return false;
                    }
                    return m.code.trim().toLowerCase() == cleanCode;
                  });
                  if (isDuplicate) {
                    return 'Mahatma Code "$val" is already used. Code must be unique.';
                  }
                  return null;
                },
              ),

              // 2. Name in English
              AppTextField(
                label: 'Name in English',
                hint: 'e.g. Mahavir Swami',
                controller: _nameEngController,
                validator: (val) => val == null || val.trim().isEmpty ? 'Name in English is required' : null,
              ),

              // 3. Name in Gujarati
              AppTextField(
                label: 'Name in Gujarati',
                hint: 'મહાવીર સ્વામી',
                controller: _nameGujController,
              ),

              // 4. Name in Hindi
              AppTextField(
                label: 'Name in Hindi',
                hint: 'महावीर स्वामी',
                controller: _nameHinController,
              ),

              // 5. Contact Person
              AppTextField(
                label: 'Contact Person',
                hint: 'Enter Contact Person Name',
                controller: _contactPersonController,
              ),

              // 6. Contact Number
              AppTextField(
                label: 'Contact Number',
                hint: 'e.g. 9876543210',
                controller: _contactNumberController,
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.trim().isEmpty ? 'Contact number is required' : null,
              ),

              // 7. Samuday Selection (Search like Google Chrome)
              GoogleSearchTypeAhead<String>(
                label: 'Samuday',
                hint: 'Type samuday name...',
                prefixIcon: Icons.groups_outlined,
                controller: _samudayController,
                suggestions: samudayOptions,
                onAddNew: _quickAddSamudayDialog,
                onAddNewText: '+ Add Samuday',
                filter: (s, q) => s.toLowerCase().contains(q.toLowerCase()),
                titleBuilder: (s) => s,
                onSelected: (s) {
                  setState(() {
                    _selectedSamuday = s;
                    _samudayController.text = s;
                  });
                },
                onChanged: (val) {
                  _selectedSamuday = val;
                },
              ),

              const SizedBox(height: 28),

              // Save Button
              AppButton(
                text: 'SAVE',
                isLoading: _isLoading,
                onPressed: _handleSave,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );

    if (widget.isModal) {
      return Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          top: false,
          child: formContent,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Mahatma' : 'Add Mahatma'),
      ),
      body: formContent,
    );
  }
}
