import 'package:flutter/material.dart';

import 'app_language.dart';
import 'custom_bouquet_item.dart';
import 'services/api_service.dart';

class AdminCustomItemsScreen extends StatefulWidget {
  const AdminCustomItemsScreen({super.key});

  @override
  State<AdminCustomItemsScreen> createState() => _AdminCustomItemsScreenState();
}

class _AdminCustomItemsScreenState extends State<AdminCustomItemsScreen> {
  final Color darkPink = const Color(0xFFE60064);
  final List<String> _groups = const ['flowers', 'wrapping', 'extras'];

  bool _loading = true;
  List<CustomBouquetItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await ApiService.fetchCustomBouquetItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _showEditor({CustomBouquetItem? item}) async {
    final t = context.t;
    final nameController = TextEditingController(text: item?.name ?? '');
    final priceController = TextEditingController(
      text: item?.price.toString() ?? '',
    );
    final stockController = TextEditingController(
      text: item?.stockCount.toString() ?? '0',
    );
    final orderController = TextEditingController(
      text: item?.order.toString() ?? '0',
    );
    var group = item?.group ?? _groups.first;
    var inStock = item?.inStock ?? true;
    var saving = false;
    String? errorMessage;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> save() async {
              if (saving) return;
              final name = nameController.text.trim();
              final price = int.tryParse(priceController.text.trim());
              final stock = int.tryParse(stockController.text.trim());
              final order = int.tryParse(orderController.text.trim()) ?? 0;
              if (name.isEmpty || price == null || stock == null) {
                setDialogState(() => errorMessage = t.fillAllFields);
                return;
              }
              setDialogState(() {
                saving = true;
                errorMessage = null;
              });
              try {
                final updated = CustomBouquetItem(
                  id: item?.id ?? '',
                  name: name,
                  group: group,
                  price: price,
                  stockCount: stock,
                  inStock: inStock,
                  order: order,
                );
                if (item == null) {
                  await ApiService.createCustomBouquetItem(updated);
                } else {
                  await ApiService.updateCustomBouquetItem(updated);
                }
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              } catch (error) {
                setDialogState(() {
                  saving = false;
                  errorMessage = t.errorWith(error);
                });
              }
            }

            return AlertDialog(
              title: Text(item == null ? t.newCustomItem : t.editCustomItem),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      enabled: !saving,
                      decoration: InputDecoration(labelText: t.name),
                    ),
                    TextField(
                      controller: priceController,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: t.price),
                    ),
                    TextField(
                      controller: stockController,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: t.stockCount),
                    ),
                    TextField(
                      controller: orderController,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Order'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: group,
                      decoration: InputDecoration(labelText: t.itemGroup),
                      items: _groups
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(t.customGroupLabel(value)),
                            ),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (value) => setDialogState(
                              () => group = value ?? _groups.first,
                            ),
                    ),
                    SwitchListTile(
                      value: inStock,
                      onChanged: saving
                          ? null
                          : (value) => setDialogState(() => inStock = value),
                      title: Text(t.inStock),
                    ),
                    if (saving)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(color: darkPink),
                      ),
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: Text(t.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: darkPink),
                  onPressed: saving ? null : save,
                  child: Text(
                    t.save,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    orderController.dispose();

    if (saved == true) {
      await _loadItems();
    }
  }

  Future<void> _deleteItem(CustomBouquetItem item) async {
    try {
      await ApiService.deleteCustomBouquetItem(item.id);
      await _loadItems();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t.errorWith(error)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(t.customItems, style: const TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: darkPink,
        onPressed: () => _showEditor(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE60064)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFFFE6EB),
                      child: Icon(_iconForGroup(item.group), color: darkPink),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${t.customGroupLabel(item.group)} • ${t.priceValue(item.price)} • ${t.stock}: ${item.stockCount}',
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          icon: Icon(
                            item.inStock
                                ? Icons.check_circle
                                : Icons.remove_circle,
                            color: darkPink,
                          ),
                          onPressed: () => _showEditor(item: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.black54),
                          onPressed: () => _showEditor(item: item),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _deleteItem(item),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _iconForGroup(String group) {
    switch (group) {
      case 'flowers':
        return Icons.local_florist;
      case 'wrapping':
        return Icons.redeem;
      default:
        return Icons.add_circle_outline;
    }
  }
}
