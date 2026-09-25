import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/app_state.dart';
import '../../widgets/app_widgets.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  void _showAddEditDialog([UserModel? user]) {
    final usernameCtrl = TextEditingController(text: user?.username ?? '');
    final nameCtrl = TextEditingController(text: user?.fullName ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    String selectedRole = user?.role ?? AppConstants.userRoles.first;
    String selectedStatus = user?.status ?? 'Active';
    final isEdit = user != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit User' : 'Add User'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: 'Username')),
                  const SizedBox(height: 12),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                  const SizedBox(height: 12),
                  TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: AppConstants.userRoles
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: ['Active', 'Inactive']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedStatus = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
              ElevatedButton(
                onPressed: () async {
                  if (usernameCtrl.text.trim().isEmpty) return;
                  final appState = AppStateScope.of(context);
                  final item = UserModel(
                    id: isEdit ? user.id : 'usr_${DateTime.now().millisecondsSinceEpoch}',
                    username: usernameCtrl.text.trim(),
                    fullName: nameCtrl.text.trim(),
                    role: selectedRole,
                    email: emailCtrl.text.trim(),
                    status: selectedStatus,
                  );
                  if (isEdit) {
                    await appState.updateUser(item);
                  } else {
                    await appState.addUser(item);
                  }
                  if (mounted) Navigator.pop(ctx);
                },
                child: const Text('SAVE'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final filteredUsers = appState.users.where((u) {
      final q = _query.toLowerCase();
      return u.username.toLowerCase().contains(q) ||
          u.fullName.toLowerCase().contains(q) ||
          u.role.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Users Management')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_users_screen',
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchBarWidget(
              hint: 'Search users by name, role...',
              controller: _searchController,
              onChanged: (val) => setState(() => _query = val),
              onClear: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
          ),
          Expanded(
            child: filteredUsers.isEmpty
                ? const EmptyStateWidget(title: 'No Users Found')
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final u = filteredUsers[index];
                      final isActive = u.status == 'Active';
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          onTap: () => _showAddEditDialog(u),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            child: const Icon(Icons.person_outline, color: AppTheme.primaryColor, size: 18),
                          ),
                          title: Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            'User: ${u.username} | Role: ${u.role}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: CompactActionTrailing(
                            isActive: isActive,
                            statusText: u.status,
                            onEdit: () => _showAddEditDialog(u),
                            onDelete: () async {
                              final confirm = await ConfirmDeleteDialog.show(context, title: 'Delete User?', content: 'Delete ${u.fullName}?');
                              if (confirm) appState.deleteUser(u.id);
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
