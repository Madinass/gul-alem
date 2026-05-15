import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'app_language.dart';
import 'product.dart';
import 'category.dart';
import 'services/api_service.dart';
import 'services/image_upload_service.dart';
import 'widgets/product_image.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final Color darkPink = const Color(0xFFE60064);
  List<Product> products = [];
  List<Category> categories = [];
  bool _loading = true;
  final ImagePicker _imagePicker = ImagePicker();
  final Set<String> _popularUpdating = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.fetchProducts(),
        ApiService.fetchCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        products = results[0] as List<Product>;
        categories = results[1] as List<Category>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _showEditor({Product? product}) async {
    final t = context.t;
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(
      text: product?.price.toString() ?? '',
    );
    final imageController = TextEditingController(
      text: product?.imagePath ?? '',
    );
    final flowerController = TextEditingController(
      text: product?.flowerType ?? '',
    );
    final stockController = TextEditingController(
      text: product?.stockCount.toString() ?? '0',
    );
    bool inStock = product?.inStock ?? true;
    bool popular = product?.popular ?? false;
    String? categoryId =
        product?.categoryId ??
        (categories.isNotEmpty ? categories.first.id : null);
    XFile? selectedImageFile;
    bool saving = false;
    String? errorMessage;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> pickImage() async {
              try {
                final image = await _imagePicker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                if (image == null) return;
                setDialogState(() {
                  selectedImageFile = image;
                  errorMessage = null;
                });
              } catch (e) {
                setDialogState(() => errorMessage = e.toString());
              }
            }

            Future<void> saveProduct() async {
              if (saving) return;
              setDialogState(() {
                saving = true;
                errorMessage = null;
              });

              try {
                var imagePath = imageController.text.trim();
                var imageUrl = product?.imageUrl ?? '';

                if (selectedImageFile != null) {
                  imageUrl = await ImageUploadService.uploadProductImage(
                    selectedImageFile!,
                  );
                  imagePath = imageUrl;
                  imageController.text = imageUrl;
                } else if (imagePath.startsWith('http://') ||
                    imagePath.startsWith('https://')) {
                  imageUrl = imagePath;
                } else if (imagePath != product?.imagePath) {
                  imageUrl = '';
                }

                final updated = Product(
                  id: product?.id ?? '',
                  name: nameController.text.trim(),
                  price: int.tryParse(priceController.text.trim()) ?? 0,
                  imagePath: imagePath,
                  imageUrl: imageUrl,
                  flowerType: flowerController.text.trim(),
                  categoryId: categoryId,
                  inStock: inStock,
                  stockCount: int.tryParse(stockController.text.trim()) ?? 0,
                  popular: popular,
                );

                if (product == null) {
                  await ApiService.createProduct(updated);
                } else {
                  await ApiService.updateProduct(updated);
                }

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              } catch (e) {
                setDialogState(() {
                  saving = false;
                  errorMessage = e.toString();
                });
              }
            }

            return AlertDialog(
              title: Text(product == null ? t.newProduct : t.editProduct),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.pink[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: selectedImageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: FutureBuilder<Uint8List>(
                                future: selectedImageFile!.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  return Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.contain,
                                  );
                                },
                              ),
                            )
                          : product != null && product.displayImage.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ProductImage(
                                product: product,
                                fit: BoxFit.contain,
                                width: double.infinity,
                              ),
                            )
                          : Icon(Icons.image, color: darkPink, size: 48),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: saving ? null : pickImage,
                      icon: const Icon(Icons.image_outlined),
                      label: Text(t.chooseImage),
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
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(labelText: t.price),
                    ),
                    TextField(
                      controller: imageController,
                      enabled: !saving,
                      decoration: InputDecoration(labelText: t.imagePath),
                    ),
                    TextField(
                      controller: flowerController,
                      enabled: !saving,
                      decoration: InputDecoration(labelText: t.flowerType),
                    ),
                    TextField(
                      controller: stockController,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(labelText: t.stockCount),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: categoryId,
                      items: categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category.id,
                              child: Text(t.categoryName(category)),
                            ),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (value) => setDialogState(() => categoryId = value),
                      decoration: InputDecoration(labelText: t.category),
                    ),
                    SwitchListTile(
                      value: inStock,
                      onChanged: saving
                          ? null
                          : (value) => setDialogState(() => inStock = value),
                      title: Text(t.inStock),
                    ),
                    SwitchListTile(
                      value: popular,
                      onChanged: saving
                          ? null
                          : (value) => setDialogState(() => popular = value),
                      title: Text(t.popular),
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
                      : () => Navigator.pop(context, false),
                  child: Text(t.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: darkPink),
                  onPressed: saving ? null : saveProduct,
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(t.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _toggleStock(Product product) async {
    try {
      await ApiService.updateStock(
        product.id,
        !product.inStock,
        product.stockCount,
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t.errorWith(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _togglePopular(Product product) async {
    if (_popularUpdating.contains(product.id)) return;
    setState(() => _popularUpdating.add(product.id));
    try {
      await ApiService.updatePopular(product.id, !product.popular);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t.errorWith(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _popularUpdating.remove(product.id));
      }
    }
  }

  Future<void> _deleteProduct(Product product) async {
    try {
      await ApiService.deleteProduct(product.id);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t.errorWith(e)),
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
        title: Text(t.products, style: const TextStyle(color: Colors.black)),
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
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ProductImage(
                        product: product,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorWidget: Icon(Icons.local_florist, color: darkPink),
                      ),
                    ),
                    title: Text(
                      t.productName(product),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${t.priceValue(product.price)} • ${t.stock}: ${product.stockCount}',
                    ),
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        IconButton(
                          icon: _popularUpdating.contains(product.id)
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  product.popular
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: product.popular
                                      ? Colors.amber
                                      : Colors.black45,
                                ),
                          onPressed: _popularUpdating.contains(product.id)
                              ? null
                              : () => _togglePopular(product),
                        ),
                        IconButton(
                          icon: Icon(
                            product.inStock
                                ? Icons.check_circle
                                : Icons.remove_circle,
                            color: darkPink,
                          ),
                          onPressed: () => _toggleStock(product),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.black54),
                          onPressed: () => _showEditor(product: product),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _deleteProduct(product),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
