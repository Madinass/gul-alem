import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app_language.dart';
import 'custom_bouquet_item.dart';
import 'services/api_service.dart';
import 'services/image_upload_service.dart';

class AdminCustomItemsScreen extends StatefulWidget {
  const AdminCustomItemsScreen({super.key});

  @override
  State<AdminCustomItemsScreen> createState() => _AdminCustomItemsScreenState();
}

class _AdminCustomItemsScreenState extends State<AdminCustomItemsScreen> {
  final Color darkPink = const Color(0xFFE60064);
  final List<String> _groups = const ['flowers', 'wrapping', 'extras'];
  final ImagePicker _imagePicker = ImagePicker();

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
    final imageController = TextEditingController(text: item?.imagePath ?? '');
    final stockController = TextEditingController(
      text: item?.stockCount.toString() ?? '0',
    );
    final orderController = TextEditingController(
      text: item?.order.toString() ?? '0',
    );
    var group = item?.group ?? _groups.first;
    var inStock = item?.inStock ?? true;
    File? selectedImageFile;
    var saving = false;
    String? errorMessage;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> pickImage() async {
              try {
                final image = await _imagePicker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 90,
                );
                if (image == null) return;
                setDialogState(() {
                  selectedImageFile = File(image.path);
                  errorMessage = null;
                });
              } catch (error) {
                setDialogState(() => errorMessage = t.errorWith(error));
              }
            }

            Future<void> save() async {
              if (saving) return;
              final name = nameController.text.trim();
              final price = int.tryParse(priceController.text.trim());
              final stock = int.tryParse(stockController.text.trim());
              final order = int.tryParse(orderController.text.trim()) ?? 0;
              var imagePath = imageController.text.trim();
              var imageUrl = item?.imageUrl ?? '';
              if (name.isEmpty || price == null || stock == null) {
                setDialogState(() => errorMessage = t.fillAllFields);
                return;
              }
              setDialogState(() {
                saving = true;
                errorMessage = null;
              });
              try {
                if (selectedImageFile != null) {
                  imageUrl = await ImageUploadService.uploadCustomBouquetImage(
                    selectedImageFile!,
                  );
                  imagePath = imageUrl;
                  imageController.text = imageUrl;
                } else if (imagePath.startsWith('http://') ||
                    imagePath.startsWith('https://')) {
                  imageUrl = imagePath;
                } else if (imagePath != item?.imagePath) {
                  imageUrl = '';
                }

                final updated = CustomBouquetItem(
                  id: item?.id ?? '',
                  name: name,
                  group: group,
                  price: price,
                  stockCount: stock,
                  inStock: inStock,
                  order: order,
                  imagePath: imagePath,
                  imageUrl: imageUrl,
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
                    _editorImagePreview(
                      file: selectedImageFile,
                      source: item?.displayImage ?? '',
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: saving ? null : pickImage,
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Choose image'),
                    ),
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
                      controller: imageController,
                      enabled: !saving,
                      decoration: InputDecoration(labelText: t.imagePath),
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
    imageController.dispose();
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
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE6EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: item.displayImage.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(4),
                              child: _sourceImage(item.displayImage),
                            )
                          : Icon(_iconForGroup(item.group), color: darkPink),
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

  Widget _editorImagePreview({required File? file, required String source}) {
    return Container(
      height: 130,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFE6EB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: file != null
            ? Image.file(file, fit: BoxFit.contain)
            : source.isNotEmpty
            ? _sourceImage(source)
            : Icon(Icons.image, color: darkPink, size: 42),
      ),
    );
  }

  Widget _sourceImage(String source) {
    final uri = Uri.tryParse(source);
    final isNetwork =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    if (isNetwork) {
      return Image.network(
        source,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.image_not_supported, color: darkPink),
      );
    }
    return Image.asset(
      source,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.image_not_supported, color: darkPink),
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
