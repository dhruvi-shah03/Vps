import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/app_state.dart';
import '../../widgets/app_widgets.dart';
import 'mahatma_form_screen.dart';

class MahatmaDetailScreen extends StatelessWidget {
  final String mahatmaId;

  const MahatmaDetailScreen({super.key, required this.mahatmaId});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final mahatma = appState.mahatmas.firstWhere(
      (m) => m.id == mahatmaId,
      orElse: () => appState.mahatmas.first,
    );

    final contactPersonDisplay = mahatma.contactPerson.isNotEmpty == true
        ? mahatma.contactPerson
        : (mahatma.sevakName.isNotEmpty == true ? mahatma.sevakName : '-');

    return Scaffold(
      appBar: AppBar(
        title: Text(mahatma.nameEnglish),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MahatmaFormScreen(mahatma: mahatma),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () async {
              final confirm = await ConfirmDeleteDialog.show(
                context,
                title: 'Delete Mahatma?',
                content: 'Are you sure you want to delete ${mahatma.nameEnglish}? This action cannot be undone.',
              );
              if (confirm && context.mounted) {
                await appState.deleteMahatma(mahatmaId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mahatma deleted successfully.'),
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
            // Status Header Card
            Card(
              color: AppTheme.primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        mahatma.code,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mahatma.nameEnglish,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Samuday: ${mahatma.samuday}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Detailed Card
            _DetailCard(
              title: 'MAHATMA INFORMATION',
              icon: Icons.badge_outlined,
              children: [
                _DetailRow(label: 'Code', value: mahatma.code),
                _DetailRow(label: 'Name in English', value: mahatma.nameEnglish),
                _DetailRow(label: 'Name in Gujarati', value: mahatma.nameGujarati.isEmpty ? '-' : mahatma.nameGujarati),
                _DetailRow(label: 'Name in Hindi', value: mahatma.nameHindi.isEmpty ? '-' : mahatma.nameHindi),
                _DetailRow(label: 'Contact Person', value: contactPersonDisplay),
                _DetailRow(label: 'Contact Number', value: mahatma.contactNumber),
                _DetailRow(label: 'Samuday', value: mahatma.samuday),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _DetailCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondaryLight),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
