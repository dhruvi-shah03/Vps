import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../master/master_screens.dart';
import '../users/users_screen.dart';
import '../settings/settings_screen.dart';
import '../auth/login_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    final menuItems = [
      _MoreMenuItem(
        title: 'Samuday',
        subtitle: 'Manage Samuday master records',
        icon: Icons.account_tree_outlined,
        color: const Color(0xFF3B82F6),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SamudayScreen())),
      ),
      _MoreMenuItem(
        title: 'Districts',
        subtitle: 'District listings & master data',
        icon: Icons.map_outlined,
        color: const Color(0xFF0D9488),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DistrictsScreen())),
      ),
      _MoreMenuItem(
        title: 'Village',
        subtitle: 'Village & town master records',
        icon: Icons.holiday_village_outlined,
        color: const Color(0xFF10B981),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VillageScreen())),
      ),
      _MoreMenuItem(
        title: 'District Incharge',
        subtitle: 'Manage regional district incharges',
        icon: Icons.badge_outlined,
        color: const Color(0xFFF59E0B),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DistrictInchargeScreen())),
      ),
      _MoreMenuItem(
        title: 'States',
        subtitle: 'State master configurations',
        icon: Icons.flag_outlined,
        color: const Color(0xFF8B5CF6),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatesScreen())),
      ),
      _MoreMenuItem(
        title: 'Salutations',
        subtitle: 'Shri, Smt., Dr., Acharya title list',
        icon: Icons.title_outlined,
        color: const Color(0xFFEC4899),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalutationsScreen())),
      ),
      _MoreMenuItem(
        title: 'Users',
        subtitle: 'Role & permission user management',
        icon: Icons.people_alt_outlined,
        color: const Color(0xFF6366F1),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersScreen())),
      ),
      _MoreMenuItem(
        title: 'Settings',
        subtitle: 'Dark mode, data reset, system info',
        icon: Icons.settings_outlined,
        color: const Color(0xFF64748B),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('More Modules & Masters'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return Card(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: item.color, size: 22),
                    ),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item.subtitle, style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: item.onTap,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.logout, color: Colors.redAccent, size: 22),
                ),
                title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                subtitle: const Text('Sign out of VPS application'),
                onTap: () async {
                  await appState.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreMenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _MoreMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
