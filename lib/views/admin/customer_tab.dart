import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/customer_model.dart';
import '../../../providers/customer_provider.dart';

class CustomerTab extends StatefulWidget {
  const CustomerTab({super.key});

  @override
  State<CustomerTab> createState() => _CustomerTabState();
}

class _CustomerTabState extends State<CustomerTab> {
  String _searchQuery = '';

  void _showFormDialog(BuildContext context, {CustomerModel? customer}) {
    final isEditing = customer != null;
    final nameCtrl = TextEditingController(text: customer?.name ?? '');
    final phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    final emailCtrl = TextEditingController(text: customer?.email ?? '');
    final pointsCtrl = TextEditingController(text: customer?.points.toString() ?? '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Pelanggan' : 'Tambah Pelanggan Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Pelanggan *'),
              ),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'No WhatsApp / HP'),
              ),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email (Opsional)'),
              ),
              if (isEditing)
                TextField(
                  controller: pointsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Poin Loyalty'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              
              final prov = context.read<CustomerProvider>();
              final model = CustomerModel(
                id: customer?.id ?? '',
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                points: int.tryParse(pointsCtrl.text) ?? 0,
              );

              Navigator.pop(ctx);
              if (isEditing) {
                await prov.updateCustomer(model);
              } else {
                await prov.addCustomer(model);
              }
            },
            child: const Text('Simpan'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CustomerProvider>();
    final filtered = prov.customers.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
             (c.phone != null && c.phone!.contains(_searchQuery));
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari nama / no HP pelanggan...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Tambah Pelanggan'),
                onPressed: () => _showFormDialog(context),
              )
            ],
          ),
        ),
        Expanded(
          child: prov.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final c = filtered[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text(c.name[0].toUpperCase())),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${c.phone ?? "No HP Kosong"} • Poin: ${c.points}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showFormDialog(context, customer: c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            prov.deleteCustomer(c.id);
                          },
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
