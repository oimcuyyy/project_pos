import 'package:flutter/material.dart';

void showOptionsEditorDialog(BuildContext context, List<dynamic> currentOptions, Function(List<dynamic>) onSave) {
  List<dynamic> localOptions = [];
  
  for (var opt in currentOptions) {
    if (opt is Map) {
      Map<String, dynamic> newOpt = Map<String, dynamic>.from(opt);
      if (newOpt['choices'] is List) {
        newOpt['choices'] = List<dynamic>.from(
          (newOpt['choices'] as List).map((c) => c is Map ? Map<String, dynamic>.from(c) : c)
        );
      } else {
        newOpt['choices'] = [];
      }
      localOptions.add(newOpt);
    }
  }

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Atur Varian & Topping'),
          content: SizedBox(
            width: 500,
            height: 400,
            child: ListView.builder(
              itemCount: localOptions.length + 1,
              itemBuilder: (context, index) {
                if (index == localOptions.length) {
                  return TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Grup Varian (Misal: Ukuran)'),
                    onPressed: () {
                      setState(() {
                        localOptions.add({
                          'name': 'Grup Baru',
                          'choices': []
                        });
                      });
                    },
                  );
                }
                
                final group = localOptions[index] as Map<String, dynamic>;
                final groupNameCtrl = TextEditingController(text: group['name']);
                final choices = group['choices'] as List<dynamic>;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: groupNameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Nama Grup (Misal: Ukuran)',
                                  isDense: true,
                                ),
                                onChanged: (val) => group['name'] = val,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  localOptions.removeAt(index);
                                });
                              },
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...choices.asMap().entries.map((entry) {
                          int cIndex = entry.key;
                          Map<String, dynamic> choice = entry.value;
                          final cNameCtrl = TextEditingController(text: choice['name']?.toString() ?? '');
                          final cPriceCtrl = TextEditingController(text: choice['price']?.toString() ?? '0');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: cNameCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Pilihan (Misal: Besar)',
                                      isDense: true,
                                    ),
                                    onChanged: (val) => choice['name'] = val,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: TextField(
                                    controller: cPriceCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Harga (+Rp)',
                                      isDense: true,
                                    ),
                                    onChanged: (val) => choice['price'] = double.tryParse(val) ?? 0.0,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      choices.removeAt(cIndex);
                                    });
                                  },
                                )
                              ],
                            ),
                          );
                        }),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Tambah Pilihan'),
                          onPressed: () {
                            setState(() {
                              choices.add({'name': '', 'price': 0.0});
                            });
                          },
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                onSave(localOptions);
                Navigator.pop(ctx);
              },
              child: const Text('Simpan Varian'),
            )
          ],
        );
      },
    ),
  );
}
