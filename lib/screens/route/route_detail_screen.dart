import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/app_state.dart';
import '../../widgets/app_widgets.dart';
import 'route_form_screen.dart';

class RouteDetailScreen extends StatelessWidget {
  final String routeId;

  const RouteDetailScreen({super.key, required this.routeId});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final route = appState.routes.firstWhere(
      (r) => r.id == routeId,
      orElse: () => appState.routes.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vihar Route Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => RouteFormScreen(route: route)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () async {
              final confirm = await ConfirmDeleteDialog.show(
                context,
                title: 'Delete Route?',
                content: 'Are you sure you want to delete this route record?',
              );
              if (confirm && context.mounted) {
                await appState.deleteViharRoute(routeId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Route deleted successfully.'),
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
          children: [
            Card(
              color: AppTheme.accentColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd MMMM yyyy').format(route.viharDate),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            route.status.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${route.fromLocation} → ${route.toLocation}',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (route.viharName.isNotEmpty || route.viharId.isNotEmpty) ...[
                      _RowItem(
                        label: 'Linked Vihar',
                        value: route.viharName.isNotEmpty ? route.viharName : 'Vihar #${route.viharId}',
                      ),
                      const Divider(),
                    ],
                    _RowItem(label: 'District', value: route.district),
                    const Divider(),
                    _RowItem(label: 'District Incharge Info', value: route.districtInchargeInfo),
                    const Divider(),
                    _RowItem(label: 'Status', value: route.status),
                  ],
                ),
              ),
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
