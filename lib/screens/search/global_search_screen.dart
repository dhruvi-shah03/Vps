import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/app_state.dart';
import '../../widgets/app_widgets.dart';
import '../mahatma/mahatma_detail_screen.dart';
import '../vihar/vihar_detail_screen.dart';
import '../route/route_detail_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedCategory = 'All';
  DateTime? _selectedDate;
  String _selectedStatus = 'All';

  final List<String> _categories = ['All', 'Mahatmas', 'Vihars', 'Routes', 'Districts'];
  final List<String> _statuses = ['All', 'Active', 'Upcoming', 'Completed'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickFilterDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final q = _query.trim().toLowerCase();
    final hasActiveFilter = q.isNotEmpty || _selectedDate != null || _selectedStatus != 'All' || _selectedCategory != 'All';

    // 1. Mahatmas
    final matchedMahatmas = (!hasActiveFilter || (_selectedCategory != 'All' && _selectedCategory != 'Mahatmas') || _selectedDate != null)
        ? []
        : appState.mahatmas
            .where((m) =>
                (q.isEmpty ||
                    m.nameEnglish.toLowerCase().contains(q) ||
                    m.code.toLowerCase().contains(q) ||
                    m.samuday.toLowerCase().contains(q)) &&
                (_selectedStatus == 'All' || (_selectedStatus == 'Active' && m.active) || (_selectedStatus != 'Active' && !m.active)))
            .toList();

    // 2. Vihars
    final matchedVihars = (!hasActiveFilter || (_selectedCategory != 'All' && _selectedCategory != 'Vihars'))
        ? []
        : appState.vihars
            .where((v) {
              final matchesQuery = q.isEmpty ||
                  v.mahatmaName.toLowerCase().contains(q) ||
                  v.startLocation.toLowerCase().contains(q) ||
                  v.endLocation.toLowerCase().contains(q);
              final matchesStatus = _selectedStatus == 'All' || v.status.toLowerCase() == _selectedStatus.toLowerCase();
              final matchesDate = _selectedDate == null ||
                  (v.startDate.year == _selectedDate!.year &&
                      v.startDate.month == _selectedDate!.month &&
                      v.startDate.day == _selectedDate!.day);
              return matchesQuery && matchesStatus && matchesDate;
            })
            .toList();

    // 3. Routes
    final matchedRoutes = (!hasActiveFilter || (_selectedCategory != 'All' && _selectedCategory != 'Routes'))
        ? []
        : appState.routes
            .where((r) {
              final matchesQuery = q.isEmpty ||
                  r.fromLocation.toLowerCase().contains(q) ||
                  r.toLocation.toLowerCase().contains(q) ||
                  r.district.toLowerCase().contains(q);
              final matchesStatus = _selectedStatus == 'All' || r.status.toLowerCase() == _selectedStatus.toLowerCase();
              final matchesDate = _selectedDate == null ||
                  (r.viharDate.year == _selectedDate!.year &&
                      r.viharDate.month == _selectedDate!.month &&
                      r.viharDate.day == _selectedDate!.day);
              return matchesQuery && matchesStatus && matchesDate;
            })
            .toList();

    // 4. Districts
    final matchedDistricts = (!hasActiveFilter || (_selectedCategory != 'All' && _selectedCategory != 'Districts') || _selectedDate != null || _selectedStatus != 'All')
        ? []
        : (q.isEmpty ? [] : appState.districts.where((d) => d.name.toLowerCase().contains(q)).toList());

    // 5. Samudays
    final matchedSamudays = (!hasActiveFilter || _selectedCategory != 'All' || _selectedDate != null || _selectedStatus != 'All')
        ? []
        : (q.isEmpty ? [] : appState.samudays.where((s) => s.name.toLowerCase().contains(q)).toList());

    // 6. Incharges
    final matchedIncharges = (!hasActiveFilter || _selectedCategory != 'All' || _selectedDate != null || _selectedStatus != 'All')
        ? []
        : (q.isEmpty ? [] : appState.incharges.where((di) => di.name.toLowerCase().contains(q) || di.district.toLowerCase().contains(q)).toList());

    final totalCount = matchedMahatmas.length +
        matchedVihars.length +
        matchedRoutes.length +
        matchedDistricts.length +
        matchedSamudays.length +
        matchedIncharges.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Search & Filters'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchBarWidget(
              hint: 'Search VPS (Mahatmas, Vihars, Routes...)...',
              controller: _searchController,
              onChanged: (val) => setState(() => _query = val),
              onClear: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
          ),

          // Filter Controls Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Date Filter Chip
                ActionChip(
                  avatar: Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: _selectedDate != null ? Colors.white : AppTheme.primaryColor,
                  ),
                  label: Text(
                    _selectedDate != null ? DateFormat('dd/MM/yyyy').format(_selectedDate!) : 'Date Filter',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _selectedDate != null ? Colors.white : AppTheme.primaryColor,
                    ),
                  ),
                  backgroundColor: _selectedDate != null ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.08),
                  onPressed: _pickFilterDate,
                ),
                if (_selectedDate != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.cancel, size: 18, color: Colors.grey),
                    tooltip: 'Clear Date Filter',
                    onPressed: () => setState(() => _selectedDate = null),
                  ),
                ],
                const SizedBox(width: 8),

                // Status Filter Dropdown Chip
                PopupMenuButton<String>(
                  onSelected: (val) => setState(() => _selectedStatus = val),
                  itemBuilder: (ctx) => _statuses
                      .map((s) => PopupMenuItem(value: s, child: Text('Status: $s')))
                      .toList(),
                  child: Chip(
                    avatar: const Icon(Icons.filter_alt_outlined, size: 14, color: AppTheme.secondaryColor),
                    label: Text(
                      'Status: $_selectedStatus',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                    ),
                    backgroundColor: _selectedStatus != 'All' ? AppTheme.secondaryColor.withOpacity(0.18) : AppTheme.secondaryColor.withOpacity(0.08),
                  ),
                ),
                const SizedBox(width: 8),

                // Category Chips
                ..._categories.map((cat) {
                  final isSel = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSel,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSel ? Colors.white : AppTheme.textSecondaryLight,
                      ),
                      selectedColor: AppTheme.primaryColor,
                      backgroundColor: Theme.of(context).cardColor,
                      onSelected: (val) {
                        if (val) setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: q.isEmpty
                ? const EmptyStateWidget(
                    title: 'Search VPS System',
                    message: 'Type a name, location, district, or code to search across all modules.',
                    icon: Icons.search_outlined,
                  )
                : totalCount == 0
                    ? EmptyStateWidget(
                        title: 'No Results Found',
                        message: 'No matching records found for "$_query".',
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          if (matchedMahatmas.isNotEmpty) ...[
                            _CategoryHeader(title: 'Mahatmas (${matchedMahatmas.length})'),
                            ...matchedMahatmas.map((m) => Card(
                                  child: ListTile(
                                    leading: const CircleAvatar(child: Icon(Icons.person, size: 20)),
                                    title: Text('${m.salutation} ${m.nameEnglish}'),
                                    subtitle: Text('Code: ${m.code} | Samuday: ${m.samuday}'),
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MahatmaDetailScreen(mahatmaId: m.id))),
                                  ),
                                )),
                          ],
                          if (matchedVihars.isNotEmpty) ...[
                            _CategoryHeader(title: 'Vihars (${matchedVihars.length})'),
                            ...matchedVihars.map((v) => Card(
                                  child: ListTile(
                                    leading: const CircleAvatar(child: Icon(Icons.directions_walk, size: 20)),
                                    title: Text(v.mahatmaName),
                                    subtitle: Text('${v.startLocation} → ${v.endLocation}'),
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViharDetailScreen(viharId: v.id))),
                                  ),
                                )),
                          ],
                          if (matchedRoutes.isNotEmpty) ...[
                            _CategoryHeader(title: 'Vihar Routes (${matchedRoutes.length})'),
                            ...matchedRoutes.map((r) => Card(
                                  child: ListTile(
                                    leading: const CircleAvatar(child: Icon(Icons.alt_route, size: 20)),
                                    title: Text('${r.fromLocation} → ${r.toLocation}'),
                                    subtitle: Text('District: ${r.district}'),
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RouteDetailScreen(routeId: r.id))),
                                  ),
                                )),
                          ],
                          if (matchedDistricts.isNotEmpty) ...[
                            _CategoryHeader(title: 'Districts (${matchedDistricts.length})'),
                            ...matchedDistricts.map((d) => Card(
                                  child: ListTile(
                                    leading: const CircleAvatar(child: Icon(Icons.map, size: 20)),
                                    title: Text(d.name),
                                    subtitle: Text('State: ${d.state}'),
                                  ),
                                )),
                          ],
                          if (matchedSamudays.isNotEmpty) ...[
                            _CategoryHeader(title: 'Samudays (${matchedSamudays.length})'),
                            ...matchedSamudays.map((s) => Card(
                                  child: ListTile(
                                    leading: const CircleAvatar(child: Icon(Icons.account_tree, size: 20)),
                                    title: Text(s.name),
                                    subtitle: Text('Code: ${s.code}'),
                                  ),
                                )),
                          ],
                          if (matchedIncharges.isNotEmpty) ...[
                            _CategoryHeader(title: 'District Incharges (${matchedIncharges.length})'),
                            ...matchedIncharges.map((di) => Card(
                                  child: ListTile(
                                    leading: const CircleAvatar(child: Icon(Icons.badge, size: 20)),
                                    title: Text(di.name),
                                    subtitle: Text('District: ${di.district} | Contact: ${di.contactNumber}'),
                                  ),
                                )),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String title;

  const _CategoryHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
      ),
    );
  }
}
