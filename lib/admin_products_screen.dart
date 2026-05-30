import 'dart:math' as math;

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
  final Future<List<Product>> Function() fetchProducts;
  final Future<List<Category>> Function() fetchCategories;
  final Future<List<String>> Function() fetchFlowerTypes;

  const AdminProductsScreen({
    super.key,
    Future<List<Product>> Function()? fetchProducts,
    Future<List<Category>> Function()? fetchCategories,
    Future<List<String>> Function()? fetchFlowerTypes,
  }) : fetchProducts = fetchProducts ?? ApiService.fetchProducts,
       fetchCategories = fetchCategories ?? ApiService.fetchCategories,
       fetchFlowerTypes = fetchFlowerTypes ?? ApiService.fetchFlowerTypes;

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final Color darkPink = const Color(0xFFE60064);
  final List<String> _defaultFlowerTypes = const [
    'rose',
    'tulip',
    'peony',
    'lily',
    'hydrangea',
    'chrysanthemum',
    'mixed',
    'bouquet',
    'umbrella',
    'balloon',
  ];
  List<Product> products = [];
  List<Category> categories = [];
  List<String> flowerTypes = [];
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
      final loadedProducts = await widget.fetchProducts();
      final loadedCategories = await widget.fetchCategories();
      var loadedFlowerTypes = <String>[];
      try {
        loadedFlowerTypes = await widget.fetchFlowerTypes();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        products = loadedProducts;
        categories = loadedCategories;
        flowerTypes = _mergeFlowerTypes([
          ...loadedFlowerTypes,
          ...loadedProducts.map((product) => product.flowerType),
        ]);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _normalizeFlowerType(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
  }

  List<String> _mergeFlowerTypes(Iterable<String> values) {
    final seen = <String>{};
    final merged = <String>[];
    for (final value in [...values, ..._defaultFlowerTypes]) {
      final normalized = _normalizeFlowerType(value);
      if (normalized.isEmpty || seen.contains(normalized)) continue;
      seen.add(normalized);
      merged.add(normalized);
    }
    return merged;
  }

  Future<void> _disposeControllersAfterClose(
    List<TextEditingController> controllers,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    for (final controller in controllers) {
      controller.dispose();
    }
  }

  Future<void> _showEditor({Product? product}) async {
    final t = context.t;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(
      text: product?.price.toString() ?? '',
    );
    final imageController = TextEditingController(
      text: product?.imagePath ?? '',
    );
    final stockController = TextEditingController(
      text: product?.stockCount.toString() ?? '0',
    );
    bool inStock = product?.inStock ?? true;
    bool popular = product?.popular ?? false;
    final flowerTypeOptions = _mergeFlowerTypes([
      ...flowerTypes,
      if (product != null) product.flowerType,
    ]);
    String? selectedFlowerType = product == null
        ? flowerTypeOptions.first
        : _normalizeFlowerType(product.flowerType);
    if (!flowerTypeOptions.contains(selectedFlowerType)) {
      selectedFlowerType = flowerTypeOptions.first;
    }
    final categoryIds = categories.map((category) => category.id).toSet();
    String? categoryId = product?.categoryId;
    if (categoryId == null || !categoryIds.contains(categoryId)) {
      categoryId = categories.isNotEmpty ? categories.first.id : null;
    }
    XFile? selectedImageFile;
    bool saving = false;
    String? errorMessage;

    String? requiredValidator(String? value) {
      if (value == null || value.trim().isEmpty) {
        return t.fillAllFields;
      }
      return null;
    }

    String? priceValidator(String? value) {
      final number = int.tryParse(value?.trim() ?? '');
      if (number == null || number <= 0) {
        return t.fillAllFields;
      }
      return null;
    }

    String? stockValidator(String? value) {
      final number = int.tryParse(value?.trim() ?? '');
      if (number == null || number < 0) {
        return t.fillAllFields;
      }
      return null;
    }

    String? imageValidator(String? value) {
      final hasExistingImage = product?.displayImage.isNotEmpty ?? false;
      if (selectedImageFile == null &&
          !hasExistingImage &&
          (value == null || value.trim().isEmpty)) {
        return t.productImageRequired;
      }
      return null;
    }

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
                if (!dialogContext.mounted) return;
                if (image == null) return;
                setDialogState(() {
                  selectedImageFile = image;
                  errorMessage = null;
                });
              } catch (e) {
                if (!dialogContext.mounted) return;
                setDialogState(() => errorMessage = e.toString());
              }
            }

            Future<void> saveProduct() async {
              if (saving) return;
              if (!(formKey.currentState?.validate() ?? false)) {
                return;
              }
              final imageInput = imageController.text.trim();
              if (selectedImageFile == null &&
                  imageInput.isEmpty &&
                  (product?.displayImage.isNotEmpty ?? false) == false) {
                setDialogState(() => errorMessage = t.productImageRequired);
                return;
              }
              if (selectedFlowerType == null ||
                  selectedFlowerType!.trim().isEmpty) {
                setDialogState(() => errorMessage = t.fillAllFields);
                return;
              }
              setDialogState(() {
                saving = true;
                errorMessage = null;
              });

              try {
                var imagePath = product?.imagePath ?? '';
                var imageUrl = product?.imageUrl ?? '';

                if (selectedImageFile != null) {
                  imageUrl = await ImageUploadService.uploadProductImage(
                    selectedImageFile!,
                  );
                  imagePath = imageUrl;
                  imageController.text = imageUrl;
                } else if (imageInput.isNotEmpty) {
                  imagePath = imageInput;
                  if (imageInput.startsWith('http://') ||
                      imageInput.startsWith('https://')) {
                    imageUrl = imageInput;
                  } else if (imageInput != product?.imagePath) {
                    imageUrl = '';
                  }
                }

                final updated = Product(
                  id: product?.id ?? '',
                  name: nameController.text.trim(),
                  price: int.parse(priceController.text.trim()),
                  imagePath: imagePath,
                  imageUrl: imageUrl,
                  flowerType: selectedFlowerType!,
                  categoryId: categoryId,
                  inStock: inStock,
                  stockCount: int.parse(stockController.text.trim()),
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
                if (!dialogContext.mounted) return;
                setDialogState(() {
                  saving = false;
                  errorMessage = e.toString();
                });
              }
            }

            final mediaQuery = MediaQuery.of(dialogContext);
            final horizontalInset = mediaQuery.size.width < 480 ? 12.0 : 40.0;
            final availableContentWidth = math.max(
              0.0,
              mediaQuery.size.width - horizontalInset * 2 - 48,
            );
            final contentWidth = math.min(availableContentWidth, 520.0);
            final maxContentHeight = math.max(
              260.0,
              mediaQuery.size.height - mediaQuery.viewInsets.bottom - 220,
            );

            return PopScope(
              canPop: !saving,
              child: AlertDialog(
                insetPadding: EdgeInsets.symmetric(
                  horizontal: horizontalInset,
                  vertical: 16,
                ),
                titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                actionsOverflowAlignment: OverflowBarAlignment.end,
                actionsOverflowDirection: VerticalDirection.down,
                title: Text(product == null ? t.newProduct : t.editProduct),
                content: SizedBox(
                  width: contentWidth,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxContentHeight),
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: mediaQuery.size.width < 360 ? 120 : 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.pink[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: selectedImageFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: FutureBuilder<Uint8List>(
                                        future: selectedImageFile!
                                            .readAsBytes(),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          }
                                          return Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.contain,
                                          );
                                        },
                                      ),
                                    )
                                  : product != null &&
                                        product.displayImage.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: ProductImage(
                                        product: product,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                      ),
                                    )
                                  : Icon(
                                      Icons.image,
                                      color: darkPink,
                                      size: 48,
                                    ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: saving ? null : pickImage,
                                icon: const Icon(Icons.image_outlined),
                                label: Text(
                                  t.chooseImage,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            TextFormField(
                              controller: nameController,
                              enabled: !saving,
                              textInputAction: TextInputAction.next,
                              validator: requiredValidator,
                              decoration: InputDecoration(labelText: t.name),
                            ),
                            TextFormField(
                              controller: priceController,
                              enabled: !saving,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: priceValidator,
                              decoration: InputDecoration(labelText: t.price),
                            ),
                            TextFormField(
                              controller: imageController,
                              enabled: !saving,
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.next,
                              validator: imageValidator,
                              decoration: InputDecoration(
                                labelText: t.imagePath,
                              ),
                            ),
                            DropdownButtonFormField<String>(
                              initialValue: selectedFlowerType,
                              isExpanded: true,
                              validator: requiredValidator,
                              items: flowerTypeOptions
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(
                                        value,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: saving
                                  ? null
                                  : (value) => setDialogState(
                                      () => selectedFlowerType = value,
                                    ),
                              decoration: InputDecoration(
                                labelText: t.flowerType,
                              ),
                            ),
                            TextFormField(
                              controller: stockController,
                              enabled: !saving,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: stockValidator,
                              decoration: InputDecoration(
                                labelText: t.stockCount,
                              ),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              initialValue: categoryId,
                              isExpanded: true,
                              items: categories
                                  .map(
                                    (category) => DropdownMenuItem(
                                      value: category.id,
                                      child: Text(
                                        t.categoryName(category),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: saving
                                  ? null
                                  : (value) => setDialogState(
                                      () => categoryId = value,
                                    ),
                              decoration: InputDecoration(
                                labelText: t.category,
                              ),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              value: inStock,
                              onChanged: saving
                                  ? null
                                  : (value) =>
                                        setDialogState(() => inStock = value),
                              title: Text(t.inStock),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              value: popular,
                              onChanged: saving
                                  ? null
                                  : (value) =>
                                        setDialogState(() => popular = value),
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
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkPink,
                      foregroundColor: Colors.white,
                    ),
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
              ),
            );
          },
        );
      },
    );

    await _disposeControllersAfterClose([
      nameController,
      priceController,
      imageController,
      stockController,
    ]);

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

  Widget _productCard(Product product, {required bool compact}) {
    final t = context.t;
    final actions = _productActions(product);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ProductImage(
                    product: product,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorWidget: SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(Icons.local_florist, color: darkPink),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.productName(product),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t.priceValue(product.price)} | ${t.stock}: ${product.stockCount}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                if (!compact) ...[const SizedBox(width: 8), actions],
              ],
            ),
            if (compact) ...[
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: actions),
            ],
          ],
        ),
      ),
    );
  }

  Widget _productActions(Product product) {
    final t = context.t;
    final popularUpdating = _popularUpdating.contains(product.id);

    return Wrap(
      spacing: 2,
      runSpacing: 2,
      alignment: WrapAlignment.end,
      children: [
        _actionButton(
          tooltip: t.popular,
          onPressed: popularUpdating ? null : () => _togglePopular(product),
          icon: popularUpdating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  product.popular ? Icons.star : Icons.star_border,
                  color: product.popular ? Colors.amber : Colors.black45,
                ),
        ),
        _actionButton(
          tooltip: t.inStock,
          onPressed: () => _toggleStock(product),
          icon: Icon(
            product.inStock ? Icons.check_circle : Icons.remove_circle,
            color: darkPink,
          ),
        ),
        _actionButton(
          tooltip: t.editProduct,
          onPressed: () => _showEditor(product: product),
          icon: const Icon(Icons.edit, color: Colors.black54),
        ),
        _actionButton(
          tooltip: t.delete,
          onPressed: () => _deleteProduct(product),
          icon: const Icon(Icons.delete, color: Colors.redAccent),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String tooltip,
    required Widget icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        tooltip: tooltip,
        icon: icon,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        onPressed: onPressed,
      ),
    );
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
          : LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 520;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _productCard(products[index], compact: compact);
                  },
                );
              },
            ),
    );
  }
}
