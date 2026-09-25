import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/app_state.dart';
import '../../widgets/app_widgets.dart';
import 'mahatma_form_screen.dart';
import 'mahatma_detail_screen.dart';

class MahatmaListScreen extends StatefulWidget {
  const MahatmaListScreen({super.key});

  @override
  State<MahatmaListScreen> createState() => _MahatmaListScreenState();
}

class _MahatmaListScreenState extends State<MahatmaListScreen> {
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
    final filteredMahatmas = appState.mahatmas.where((m) {
      final query = _searchQuery.toLowerCase();
      return m.nameEnglish.toLowerCase().contains(query) ||
          m.code.toLowerCase().contains(query) ||
          m.samuday.toLowerCase().contains(query) ||
          m.contactNumber.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mahatmas'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_mahatma_list',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MahatmaFormScreen()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Mahatma'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchBarWidget(
              hint: 'Search Mahatma by name, code, samuday...',
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
              onRefresh: () => appState.refreshMahatmas(),
              child: filteredMahatmas.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 40),
                        EmptyStateWidget(
                          title: _searchQuery.isEmpty ? 'No Mahatmas Available' : 'No Records Found',
                          message: _searchQuery.isEmpty
                              ? 'Pull down to refresh or tap below to add your first Mahatma record.'
                              : 'No Mahatmas matching "$_searchQuery".',
                          buttonText: _searchQuery.isEmpty ? '+ Add Mahatma' : null,
                          onButtonPressed: _searchQuery.isEmpty
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const MahatmaFormScreen()),
                                  );
                                }
                              : null,
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                      itemCount: filteredMahatmas.length,
                      itemBuilder: (context, index) {
                        final item = filteredMahatmas[index];
                        return _MahatmaCard(item: item);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MahatmaCard extends StatelessWidget {
  final Mahatma item;

  const _MahatmaCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MahatmaDetailScreen(mahatmaId: item.id),
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
                  Expanded(
                    child: Text(
                      '${item.salutation} ${item.nameEnglish}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.active
                          ? Colors.green.withOpacity(0.12)
                          : Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.active ? 'ACTIVE' : 'INACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: item.active ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Code: ${item.code}   |   Letter No: ${item.letterNo}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
              ),
              const Divider(height: 16),
              Row(
                children: [
                  const Icon(Icons.account_tree_outlined, size: 16, color: AppTheme.textSecondaryLight),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Samuday: ${item.samuday}',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryLight),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 16, color: AppTheme.textSecondaryLight),
                  const SizedBox(width: 6),
                  Text(
                    'Contact: ${item.contactNumber}',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryLight),
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
