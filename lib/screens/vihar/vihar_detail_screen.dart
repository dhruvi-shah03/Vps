import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/app_state.dart';
import '../../widgets/app_widgets.dart';
import 'vihar_form_screen.dart';

class ViharDetailScreen extends StatelessWidget {
  final String viharId;

  const ViharDetailScreen({super.key, required this.viharId});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final vihar = appState.vihars.firstWhere(
      (v) => v.id == viharId,
      orElse: () => appState.vihars.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vihar Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ViharFormScreen(vihar: vihar, appState: appState)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () async {
              final confirm = await ConfirmDeleteDialog.show(
                context,
                title: 'Delete Vihar?',
                content: 'Are you sure you want to delete this Vihar schedule?',
              );
              if (confirm && context.mounted) {
                await appState.deleteVihar(viharId);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vihar deleted successfully.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Card(
              color: AppTheme.secondaryColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vihar.mahatmaName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.alt_route, color: Colors.white70, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${vihar.startLocation} → ${vihar.endLocation}',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Section 1: MAHATMA'S INFORMATION
            const SectionHeader(title: "MAHATMA'S INFORMATION"),
            const SizedBox(height: 8),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _RowItem(label: 'Mahatma Name', value: vihar.mahatmaName),
                    const Divider(),
                    _RowItem(label: 'Mahatma Code', value: 'M-${vihar.mahatmaId}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Section 2: VIHAR'S INFORMATION
            const SectionHeader(title: "VIHAR'S INFORMATION"),
            const SizedBox(height: 8),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RowItem(label: 'Start Location', value: vihar.startLocation),
                    const Divider(),
                    _RowItem(label: 'End Location', value: vihar.endLocation),
                    const Divider(),
                    _RowItem(label: 'Start Date', value: DateFormat('dd MMMM yyyy').format(vihar.startDate)),
                    const Divider(),
                    _RowItem(label: 'End Date', value: DateFormat('dd MMMM yyyy').format(vihar.endDate)),
                    const Divider(),
                    _RowItem(label: 'Status', value: vihar.status),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Vihar Routes Lines Sub-section
            const SectionHeader(title: 'Vihar Routes'),
            const SizedBox(height: 8),

            if (vihar.routes.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No routes recorded for this Vihar.'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vihar.routes.length,
                itemBuilder: (context, index) {
                  final route = vihar.routes[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.alt_route, size: 20),
                      ),
                      title: Text('${route.fromLocation} → ${route.toLocation}'),
                      subtitle: Text('Date: ${DateFormat('dd/MM/yyyy').format(route.viharDate)} | District: ${route.district}'),
                      trailing: Text('${route.distanceKm} km', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final String value;

  const _RowItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondaryLight, fontSize: 14)),
          Flexible(
            child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
