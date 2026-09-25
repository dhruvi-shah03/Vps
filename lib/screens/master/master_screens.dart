import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/app_state.dart';
import '../../widgets/app_widgets.dart';

// --- Samuday Screen ---
class SamudayScreen extends StatefulWidget {
  const SamudayScreen({super.key});

  @override
  State<SamudayScreen> createState() => _SamudayScreenState();
}

class _SamudayScreenState extends State<SamudayScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  void _showAddEditDialog([Samuday? item]) {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    String status = item?.status ?? 'active';
    final isEdit = item != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Samuday' : 'Add Samuday'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  hintText: 'Enter Samuday Name',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: status,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => status = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final appState = AppStateScope.of(context);
                if (isEdit) {
                  await appState.updateSamuday(Samuday(
                    id: item.id,
                    name: nameCtrl.text.trim(),
                    status: status,
                    active: status == 'active',
                  ));
                } else {
                  await appState.addSamuday(Samuday(
                    id: 's_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    status: status,
                    active: status == 'active',
                  ));
                }
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final items = appState.samudays
        .where((s) => s.name.toLowerCase().contains(_query.toLowerCase()) || s.code.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Samuday')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_samuday',
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchBarWidget(
              hint: 'Search Samuday...',
              controller: _searchController,
              onChanged: (val) => setState(() => _query = val),
              onClear: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const EmptyStateWidget(title: 'No Samudays Found')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final s = items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          onTap: () => _showAddEditDialog(s),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            child: const Icon(Icons.account_balance, color: AppTheme.primaryColor, size: 18),
                          ),
                          title: Text(
                            s.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'Status: ${s.status == 'active' ? 'Active' : 'Inactive'}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: CompactActionTrailing(
                            isActive: s.status == 'active',
                            onEdit: () => _showAddEditDialog(s),
                            onDelete: () async {
                              final confirm = await ConfirmDeleteDialog.show(context, title: 'Delete Samuday?', content: 'Delete ${s.name}?');
                              if (confirm) appState.deleteSamuday(s.id);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// --- Districts Screen ---
class DistrictsScreen extends StatefulWidget {
  const DistrictsScreen({super.key});

  @override
  State<DistrictsScreen> createState() => _DistrictsScreenState();
}

class _DistrictsScreenState extends State<DistrictsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  void _showAddEditDialog([District? item]) {
    final appState = AppStateScope.of(context);
    final nameEnCtrl = TextEditingController(text: item?.nameEnglish.isNotEmpty == true ? item!.nameEnglish : (item?.name ?? ''));
    final nameGuCtrl = TextEditingController(text: item?.nameGujarati ?? '');
    final nameHiCtrl = TextEditingController(text: item?.nameHindi ?? '');
    String? selectedInchargeId = item?.inchargeId.isNotEmpty == true ? item!.inchargeId : null;
    String? selectedStateId = item?.stateId.isNotEmpty == true ? item!.stateId : null;
    String status = item?.status ?? 'active';
    final isEdit = item != null;

    if (selectedInchargeId != null && !appState.incharges.any((i) => i.id == selectedInchargeId)) {
      selectedInchargeId = null;
    }
    if (selectedStateId != null && !appState.states.any((s) => s.id == selectedStateId)) {
      selectedStateId = null;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit District' : 'Add District'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameEnCtrl,
                  decoration: const InputDecoration(labelText: 'Name in English *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameGuCtrl,
                  decoration: const InputDecoration(labelText: 'Name in Gujarati'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameHiCtrl,
                  decoration: const InputDecoration(labelText: 'Name in Hindi'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedInchargeId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'District Incharge'),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('-- Select Incharge --')),
                    ...appState.incharges.map((inc) => DropdownMenuItem(
                          value: inc.id,
                          child: Text(inc.name, overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (val) => setDialogState(() => selectedInchargeId = val),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStateId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'State'),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('-- Select State --')),
                    ...appState.states.map((st) => DropdownMenuItem(
                          value: st.id,
                          child: Text(st.name, overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (val) => setDialogState(() => selectedStateId = val),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => status = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (nameEnCtrl.text.trim().isEmpty) return;
                final inchargeObj = appState.incharges.cast<DistrictIncharge?>().firstWhere((i) => i?.id == selectedInchargeId, orElse: () => null);
                final stateObj = appState.states.cast<StateModel?>().firstWhere((s) => s?.id == selectedStateId, orElse: () => null);

                final newDistrict = District(
                  id: isEdit ? item.id : 'd_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameEnCtrl.text.trim(),
                  nameEnglish: nameEnCtrl.text.trim(),
                  nameGujarati: nameGuCtrl.text.trim(),
                  nameHindi: nameHiCtrl.text.trim(),
                  inchargeId: selectedInchargeId ?? '',
                  inchargeName: inchargeObj?.name ?? '',
                  stateId: selectedStateId ?? '',
                  state: stateObj?.name ?? (item?.state ?? 'Gujarat'),
                  status: status,
                  active: status == 'active',
                );

                if (isEdit) {
                  await appState.updateDistrict(newDistrict);
                } else {
                  await appState.addDistrict(newDistrict);
                }
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final items = appState.districts
        .where((d) => d.name.toLowerCase().contains(_query.toLowerCase()) || d.state.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Districts')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_district',
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchBarWidget(
              hint: 'Search District...',
              controller: _searchController,
              onChanged: (val) => setState(() => _query = val),
              onClear: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const EmptyStateWidget(title: 'No Districts Found')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final d = items[index];
                      final displayName = d.nameEnglish.isNotEmpty ? d.nameEnglish : d.name;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          onTap: () => _showAddEditDialog(d),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            child: const Icon(Icons.map, color: AppTheme.primaryColor, size: 18),
                          ),
                          title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            'State: ${d.state}${d.inchargeName.isNotEmpty ? ' | Incharge: ${d.inchargeName}' : ''}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: CompactActionTrailing(
                            isActive: d.status == 'active',
                            onEdit: () => _showAddEditDialog(d),
                            onDelete: () async {
                              final confirm = await ConfirmDeleteDialog.show(context, title: 'Delete District?', content: 'Delete ${d.name}?');
                              if (confirm) appState.deleteDistrict(d.id);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// --- Village Screen ---
class VillageScreen extends StatefulWidget {
  const VillageScreen({super.key});

  @override
  State<VillageScreen> createState() => _VillageScreenState();
}

class _VillageScreenState extends State<VillageScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedDistrictFilter;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final appState = AppStateScope.of(context);
    setState(() => _isFetching = true);
    await appState.refreshVillages();
    if (mounted) {
      setState(() => _isFetching = false);
      if (appState.villages.isNotEmpty) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded ${appState.villages.length} villages from backend'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditDialog([Village? item]) {
    final nameEnCtrl = TextEditingController(text: item?.nameEnglish.isNotEmpty == true ? item!.nameEnglish : (item?.name ?? ''));
    final nameGuCtrl = TextEditingController(text: item?.nameGujarati ?? '');
    final nameHiCtrl = TextEditingController(text: item?.nameHindi ?? '');
    final appState = AppStateScope.of(context);
    
    String? selectedDistrictId = item?.districtId.isNotEmpty == true ? item!.districtId : null;
    if (selectedDistrictId != null && !appState.districts.any((d) => d.id == selectedDistrictId)) {
      final matchByName = appState.districts.cast<District?>().firstWhere(
        (d) => d?.name.toLowerCase() == item?.districtName.toLowerCase(),
        orElse: () => null,
      );
      if (matchByName != null) selectedDistrictId = matchByName.id;
    }

    String status = item?.status ?? 'active';
    final isEdit = item != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Village' : 'Add Village'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameEnCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name in English *',
                    hintText: 'e.g. Navrangpura',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameGuCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name in Gujarati',
                    hintText: 'e.g. નવરંગપુરા',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameHiCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name in Hindi',
                    hintText: 'e.g. नवरंगपुरा',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedDistrictId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'District'),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('-- Select District --')),
                    ...appState.districts.map((d) => DropdownMenuItem(
                          value: d.id,
                          child: Text(d.nameEnglish.isNotEmpty ? d.nameEnglish : d.name, overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (val) => setDialogState(() => selectedDistrictId = val),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => status = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (nameEnCtrl.text.trim().isEmpty) return;
                final distObj = appState.districts.cast<District?>().firstWhere(
                      (d) => d?.id == selectedDistrictId,
                      orElse: () => null,
                    );

                final newVillage = Village(
                  id: isEdit ? item.id : 'v_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameEnCtrl.text.trim(),
                  nameEnglish: nameEnCtrl.text.trim(),
                  nameGujarati: nameGuCtrl.text.trim(),
                  nameHindi: nameHiCtrl.text.trim(),
                  districtId: selectedDistrictId ?? '',
                  districtName: distObj?.name ?? (item?.districtName ?? ''),
                  status: status,
                  active: status == 'active',
                );

                if (isEdit) {
                  await appState.updateVillage(newVillage);
                } else {
                  await appState.addVillage(newVillage);
                }
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final q = _query.toLowerCase();
    final items = appState.villages.where((v) {
      final matchesQuery = _query.isEmpty ||
          v.name.toLowerCase().contains(q) ||
          v.nameEnglish.toLowerCase().contains(q) ||
          v.nameGujarati.toLowerCase().contains(q) ||
          v.nameHindi.toLowerCase().contains(q) ||
          v.districtName.toLowerCase().contains(q);

      final matchesDistrict = _selectedDistrictFilter == null ||
          v.districtName.toLowerCase() == _selectedDistrictFilter!.toLowerCase() ||
          v.districtId == _selectedDistrictFilter;

      return matchesQuery && matchesDistrict;
    }).toList();

    final titleText = appState.villages.isEmpty
        ? 'Villages'
        : 'Villages (${items.length}${items.length != appState.villages.length ? '/${appState.villages.length}' : ''})';

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        actions: [
          IconButton(
            icon: _isFetching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isFetching ? null : _loadData,
            tooltip: 'Refresh Villages from Backend',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_village',
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SearchBarWidget(
                hint: 'Search Village...',
                controller: _searchController,
                onChanged: (val) => setState(() => _query = val),
                onClear: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
            ),
            if (appState.districts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDistrictFilter,
                        isDense: true,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          hintText: 'All Districts',
                          prefixIcon: const Icon(Icons.filter_alt_outlined, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('All Districts')),
                          ...appState.districts.map((d) => DropdownMenuItem(
                                value: d.name,
                                child: Text(d.nameEnglish.isNotEmpty ? d.nameEnglish : d.name, overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (val) => setState(() => _selectedDistrictFilter = val),
                      ),
                    ),
                    if (_selectedDistrictFilter != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        tooltip: 'Clear district filter',
                        onPressed: () => setState(() => _selectedDistrictFilter = null),
                      ),
                    ],
                  ],
                ),
              ),
            Expanded(
              child: _isFetching && items.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppTheme.primaryColor),
                          SizedBox(height: 14),
                          Text('Fetching villages from Odoo backend...', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            EmptyStateWidget(title: 'No Villages Found'),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final v = items[index];
                            final displayName = v.nameEnglish.isNotEmpty ? v.nameEnglish : v.name;
                            final otherNames = [
                              if (v.nameGujarati.isNotEmpty) v.nameGujarati,
                              if (v.nameHindi.isNotEmpty) v.nameHindi,
                            ].join(' / ');

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                onTap: () => _showAddEditDialog(v),
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFF10B981).withOpacity(0.12),
                                  child: const Icon(Icons.holiday_village_outlined, color: Color(0xFF10B981), size: 18),
                                ),
                                title: Text(
                                  displayName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  'District: ${v.districtName.isNotEmpty ? v.districtName : 'Not Specified'}${otherNames.isNotEmpty ? ' • $otherNames' : ''}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: CompactActionTrailing(
                                  isActive: v.status == 'active',
                                  onEdit: () => _showAddEditDialog(v),
                                  onDelete: () async {
                                    final confirm = await ConfirmDeleteDialog.show(context, title: 'Delete Village?', content: 'Delete ${v.name}?');
                                    if (confirm) appState.deleteVillage(v.id);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- District Incharge Screen ---
class DistrictInchargeScreen extends StatefulWidget {
  const DistrictInchargeScreen({super.key});

  @override
  State<DistrictInchargeScreen> createState() => _DistrictInchargeScreenState();
}

class _DistrictInchargeScreenState extends State<DistrictInchargeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  void _showAddEditDialog([DistrictIncharge? item]) {
    final firstNameCtrl = TextEditingController(text: item?.firstName.isNotEmpty == true ? item!.firstName : (item?.name ?? ''));
    final lastNameCtrl = TextEditingController(text: item?.lastName ?? '');
    final phoneCtrl = TextEditingController(text: item?.phone.isNotEmpty == true ? item!.phone : (item?.contactNumber ?? ''));
    final emailCtrl = TextEditingController(text: item?.email ?? '');
    final passwordCtrl = TextEditingController(text: item?.password ?? '');
    String stage = item?.stage ?? 'active';
    bool obscurePassword = true;
    final isEdit = item != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit District Incharge' : 'Add District Incharge'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameCtrl,
                  decoration: const InputDecoration(labelText: 'First Name *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lastNameCtrl,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: stage,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Stage'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => stage = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (firstNameCtrl.text.trim().isEmpty) return;
                final appState = AppStateScope.of(context);
                final di = DistrictIncharge(
                  id: isEdit ? item.id : 'di_${DateTime.now().millisecondsSinceEpoch}',
                  firstName: firstNameCtrl.text.trim(),
                  lastName: lastNameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  contactNumber: phoneCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  password: passwordCtrl.text.trim(),
                  district: item?.district ?? 'Gujarat',
                  stage: stage,
                  active: stage == 'active',
                );
                if (isEdit) {
                  await appState.updateDistrictIncharge(di);
                } else {
                  await appState.addDistrictIncharge(di);
                }
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final items = appState.incharges
        .where((di) =>
            di.name.toLowerCase().contains(_query.toLowerCase()) ||
            di.firstName.toLowerCase().contains(_query.toLowerCase()) ||
            di.lastName.toLowerCase().contains(_query.toLowerCase()) ||
            di.email.toLowerCase().contains(_query.toLowerCase()) ||
            di.phone.contains(_query))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('District Incharge')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_incharge',
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchBarWidget(
              hint: 'Search Incharge...',
              controller: _searchController,
              onChanged: (val) => setState(() => _query = val),
              onClear: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const EmptyStateWidget(title: 'No District Incharge Found')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final di = items[index];
                      final fullName = '${di.firstName} ${di.lastName}'.trim();
                      final displayName = fullName.isNotEmpty ? fullName : di.name;
                      final phone = di.phone.isNotEmpty ? di.phone : di.contactNumber;
                      final subtitle = [
                        if (phone.isNotEmpty) phone,
                        if (di.district.isNotEmpty) di.district,
                        if (di.email.isNotEmpty) di.email,
                      ].join(' | ');

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          onTap: () => _showAddEditDialog(di),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
                            child: const Icon(Icons.person, color: AppTheme.secondaryColor, size: 18),
                          ),
                          title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            subtitle.isNotEmpty ? subtitle : 'District Incharge',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: CompactActionTrailing(
                            isActive: di.stage == 'active',
                            onEdit: () => _showAddEditDialog(di),
                            onDelete: () async {
                              final confirm = await ConfirmDeleteDialog.show(context, title: 'Delete Incharge?', content: 'Delete $displayName?');
                              if (confirm) appState.deleteDistrictIncharge(di.id);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// --- States Screen ---
class StatesScreen extends StatefulWidget {
  const StatesScreen({super.key});

  @override
  State<StatesScreen> createState() => _StatesScreenState();
}

class _StatesScreenState extends State<StatesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  void _showAddEditDialog([StateModel? item]) {
    final nameEnCtrl = TextEditingController(text: item?.nameEnglish.isNotEmpty == true ? item!.nameEnglish : (item?.name ?? ''));
    final nameGuCtrl = TextEditingController(text: item?.nameGujarati ?? '');
    final nameHiCtrl = TextEditingController(text: item?.nameHindi ?? '');
    String status = item?.status ?? 'active';
    final isEdit = item != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit State' : 'Add State'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameEnCtrl,
                  decoration: const InputDecoration(labelText: 'Name in English *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameGuCtrl,
                  decoration: const InputDecoration(labelText: 'Name in Gujarati'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameHiCtrl,
                  decoration: const InputDecoration(labelText: 'Name in Hindi'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => status = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (nameEnCtrl.text.trim().isEmpty) return;
                final appState = AppStateScope.of(context);
                final st = StateModel(
                  id: isEdit ? item.id : 'st_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameEnCtrl.text.trim(),
                  nameEnglish: nameEnCtrl.text.trim(),
                  nameGujarati: nameGuCtrl.text.trim(),
                  nameHindi: nameHiCtrl.text.trim(),
                  code: item?.code ?? 'ST',
                  country: 'India',
                  status: status,
                  active: status == 'active',
                );
                if (isEdit) {
                  await appState.updateState(st);
                } else {
                  await appState.addState(st);
                }
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final items = appState.states
        .where((st) =>
            st.name.toLowerCase().contains(_query.toLowerCase()) ||
            st.nameEnglish.toLowerCase().contains(_query.toLowerCase()) ||
            st.nameGujarati.toLowerCase().contains(_query.toLowerCase()) ||
            st.nameHindi.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('States')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_state',
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchBarWidget(
              hint: 'Search State...',
              controller: _searchController,
              onChanged: (val) => setState(() => _query = val),
              onClear: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const EmptyStateWidget(title: 'No States Found')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final st = items[index];
                      final displayName = st.nameEnglish.isNotEmpty ? st.nameEnglish : st.name;
                      final otherLang = [
                        if (st.nameGujarati.isNotEmpty) 'GU: ${st.nameGujarati}',
                        if (st.nameHindi.isNotEmpty) 'HI: ${st.nameHindi}',
                        'Country: ${st.country}',
                      ].join(' | ');

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          onTap: () => _showAddEditDialog(st),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.accentColor.withOpacity(0.1),
                            child: const Icon(Icons.flag_outlined, color: AppTheme.accentColor, size: 18),
                          ),
                          title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            otherLang,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: CompactActionTrailing(
                            isActive: st.status == 'active',
                            onEdit: () => _showAddEditDialog(st),
                            onDelete: () async {
                              final confirm = await ConfirmDeleteDialog.show(context, title: 'Delete State?', content: 'Delete $displayName?');
                              if (confirm) appState.deleteState(st.id);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// --- Salutations Screen ---
class SalutationsScreen extends StatefulWidget {
  const SalutationsScreen({super.key});

  @override
  State<SalutationsScreen> createState() => _SalutationsScreenState();
}

class _SalutationsScreenState extends State<SalutationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  void _showAddEditDialog([Salutation? item]) {
    final appState = AppStateScope.of(context);
    final nameEnCtrl = TextEditingController(text: item?.nameEnglish.isNotEmpty == true ? item!.nameEnglish : (item?.title ?? ''));
    final nameGuCtrl = TextEditingController(text: item?.nameGujarati ?? '');
    final nameHiCtrl = TextEditingController(text: item?.nameHindi ?? '');
    String? selectedPrefix = item?.salutationPrefix.isNotEmpty == true ? item!.salutationPrefix.toLowerCase() : 's.p.';
    if (!['d.g.p.', 'c.p.', 's.p.'].contains(selectedPrefix)) {
      selectedPrefix = 's.p.';
    }
    String status = item?.status ?? 'active';
    String groupType = item?.groupType.isNotEmpty == true ? item!.groupType : 'district';
    String? selectedDistId = item?.districtId.isNotEmpty == true ? item!.districtId : null;
    String? selectedStateId = item?.stateId.isNotEmpty == true ? item!.stateId : null;
    final isEdit = item != null;

    if (selectedDistId != null && !appState.districts.any((d) => d.id == selectedDistId)) {
      selectedDistId = null;
    }
    if (selectedStateId != null && !appState.states.any((s) => s.id == selectedStateId)) {
      selectedStateId = null;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Salutation' : 'Add Salutation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameEnCtrl,
                  decoration: const InputDecoration(labelText: 'Name in English *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameGuCtrl,
                  decoration: const InputDecoration(labelText: 'Name in Gujarati'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameHiCtrl,
                  decoration: const InputDecoration(labelText: 'Name in Hindi'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedPrefix,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Salutation Prefix'),
                  items: const [
                    DropdownMenuItem(value: 'd.g.p.', child: Text('D.G.P.')),
                    DropdownMenuItem(value: 'c.p.', child: Text('C.P.')),
                    DropdownMenuItem(value: 's.p.', child: Text('S.P.')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedPrefix = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: groupType,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Group Type'),
                  items: const [
                    DropdownMenuItem(value: 'state', child: Text('State')),
                    DropdownMenuItem(value: 'district', child: Text('District')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => groupType = val);
                  },
                ),
                const SizedBox(height: 12),
                if (groupType == 'district')
                  DropdownButtonFormField<String>(
                    value: selectedDistId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'District'),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('-- Select District --')),
                      ...appState.districts.map((d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.name, overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (val) => setDialogState(() => selectedDistId = val),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: selectedStateId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'State'),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('-- Select State --')),
                      ...appState.states.map((st) => DropdownMenuItem(
                            value: st.id,
                            child: Text(st.name, overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (val) => setDialogState(() => selectedStateId = val),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => status = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (nameEnCtrl.text.trim().isEmpty) return;
                final distObj = appState.districts.cast<District?>().firstWhere((d) => d?.id == selectedDistId, orElse: () => null);
                final stateObj = appState.states.cast<StateModel?>().firstWhere((s) => s?.id == selectedStateId, orElse: () => null);

                final sal = Salutation(
                  id: isEdit ? item.id : 'sal_${DateTime.now().millisecondsSinceEpoch}',
                  title: nameEnCtrl.text.trim(),
                  nameEnglish: nameEnCtrl.text.trim(),
                  nameGujarati: nameGuCtrl.text.trim(),
                  nameHindi: nameHiCtrl.text.trim(),
                  salutationPrefix: selectedPrefix ?? 's.p.',
                  groupType: groupType,
                  districtId: selectedDistId ?? '',
                  districtName: distObj?.name ?? '',
                  stateId: selectedStateId ?? '',
                  stateName: stateObj?.name ?? '',
                  status: status,
                  active: status == 'active',
                );

                if (isEdit) {
                  await appState.updateSalutation(sal);
                } else {
                  await appState.addSalutation(sal);
                }
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final items = appState.salutations
        .where((s) =>
            s.title.toLowerCase().contains(_query.toLowerCase()) ||
            s.nameEnglish.toLowerCase().contains(_query.toLowerCase()) ||
            s.nameGujarati.toLowerCase().contains(_query.toLowerCase()) ||
            s.nameHindi.toLowerCase().contains(_query.toLowerCase()) ||
            s.salutationPrefix.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Salutations')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_salutation',
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchBarWidget(
              hint: 'Search Salutation...',
              controller: _searchController,
              onChanged: (val) => setState(() => _query = val),
              onClear: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const EmptyStateWidget(title: 'No Salutations Found')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final sal = items[index];
                      final locationInfo = sal.districtName.isNotEmpty
                          ? 'District: ${sal.districtName}'
                          : (sal.stateName.isNotEmpty ? 'State: ${sal.stateName}' : '');
                      final prefixText = sal.salutationPrefix.isNotEmpty ? 'Prefix: ${sal.salutationPrefix.toUpperCase()}' : '';
                      final subtitleText = [
                        if (prefixText.isNotEmpty) prefixText,
                        if (locationInfo.isNotEmpty) locationInfo,
                      ].join(' | ');

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          onTap: () => _showAddEditDialog(sal),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            child: const Icon(Icons.badge_outlined, color: AppTheme.primaryColor, size: 18),
                          ),
                          title: Text(sal.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            subtitleText.isNotEmpty ? subtitleText : 'Salutation',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: CompactActionTrailing(
                            isActive: sal.status == 'active',
                            onEdit: () => _showAddEditDialog(sal),
                            onDelete: () async {
                              final confirm = await ConfirmDeleteDialog.show(context, title: 'Delete Salutation?', content: 'Delete ${sal.title}?');
                              if (confirm) appState.deleteSalutation(sal.id);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
