import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_model.dart';
import '../../../providers/employee_provider.dart';

class EmployeeTab extends StatefulWidget {
  final UserRole? roleFilter;
  const EmployeeTab({super.key, this.roleFilter});

  @override
  State<EmployeeTab> createState() => _EmployeeTabState();
}

class _EmployeeTabState extends State<EmployeeTab> {

  void _showFormDialog(BuildContext context, {UserModel? user}) {
    final isEditing = user != null;
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final userCtrl = TextEditingController(text: user?.username ?? '');
    final passCtrl = TextEditingController();
    String defaultRole = 'cashier';
    if (widget.roleFilter == UserRole.admin) defaultRole = 'admin';
    if (widget.roleFilter == UserRole.user) defaultRole = 'user';
    
    String role = user != null ? (user.isAdmin ? 'admin' : (user.isUser ? 'user' : 'cashier')) : defaultRole;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Karyawan' : 'Tambah Karyawan Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap *'),
                ),
                TextField(
                  controller: userCtrl,
                  decoration: const InputDecoration(labelText: 'Username Login *'),
                ),
                TextField(
                  controller: passCtrl,
                  decoration: InputDecoration(labelText: isEditing ? 'Password Baru (Kosongkan jika tidak diubah)' : 'Password *'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Akses / Role'),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('User')),
                    DropdownMenuItem(value: 'cashier', child: Text('Kasir')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin/Pemilik')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => role = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || userCtrl.text.trim().isEmpty) return;
                if (!isEditing && passCtrl.text.isEmpty) return;

                final prov = context.read<EmployeeProvider>();
                Navigator.pop(ctx);
                
                if (isEditing) {
                  await prov.updateEmployee(user.id, nameCtrl.text.trim(), userCtrl.text.trim(), passCtrl.text, role);
                } else {
                  await prov.addEmployee(nameCtrl.text.trim(), userCtrl.text.trim(), passCtrl.text, role);
                }
              },
              child: const Text('Simpan'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<EmployeeProvider>();
    
    final filteredEmployees = widget.roleFilter == null 
        ? prov.employees 
        : prov.employees.where((e) => e.role == widget.roleFilter).toList();

    String title = 'Daftar Akun Karyawan';
    if (widget.roleFilter == UserRole.admin) title = 'Daftar Akun Admin';
    if (widget.roleFilter == UserRole.cashier) title = 'Daftar Akun Kasir';
    if (widget.roleFilter == UserRole.user) title = 'Daftar Akun User';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              FilledButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Tambah Akun'),
                onPressed: () => _showFormDialog(context),
              )
            ],
          ),
        ),
        Expanded(
          child: prov.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: filteredEmployees.length,
                itemBuilder: (context, i) {
                  final e = filteredEmployees[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: e.isAdmin ? Colors.red.shade100 : (e.isUser ? Colors.green.shade100 : Colors.blue.shade100),
                      child: Icon(e.isAdmin ? Icons.admin_panel_settings : (e.isUser ? Icons.person : Icons.point_of_sale), color: e.isAdmin ? Colors.red : (e.isUser ? Colors.green : Colors.blue)),
                    ),
                    title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Username: ${e.username} • Role: ${e.isAdmin ? "Admin" : (e.isUser ? "User" : "Kasir")}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showFormDialog(context, user: e),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => prov.deleteEmployee(e.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }
}
