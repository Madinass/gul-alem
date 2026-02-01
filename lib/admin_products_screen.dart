import 'package:flutter/material.dart';
import 'product.dart';
import 'category.dart';
import 'services/api_service.dart';

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
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final imageController = TextEditingController(text: product?.imagePath ?? '');
    final flowerController = TextEditingController(text: product?.flowerType ?? '');
    final stockController = TextEditingController(text: product?.stockCount.toString() ?? '0');
    bool inStock = product?.inStock ?? true;
    bool popular = product?.popular ?? false;
    String? categoryId = product?.categoryId ?? (categories.isNotEmpty ? categories.first.id : null);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product == null ? 'Жаңа өнім' : 'Өнімді өңдеу'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Атауы')),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Бағасы')),
              TextField(controller: imageController, decoration: const InputDecoration(labelText: 'Image path')),
              TextField(controller: flowerController, decoration: const InputDecoration(labelText: 'Flower type')),
              TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Stock count')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: categoryId,
                items: categories
                    .map((category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ))
                    .toList(),
                onChanged: (value) => categoryId = value,
                decoration: const InputDecoration(labelText: 'Категория'),
              ),
              SwitchListTile(
                value: inStock,
                onChanged: (value) => inStock = value,
                title: const Text('Қоймада бар'),
              ),
              SwitchListTile(
                value: popular,
                onChanged: (value) => popular = value,
                title: const Text('Танымал'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Бас тарту')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: darkPink),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сақтау'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final updated = Product(
      id: product?.id ?? '',
      name: nameController.text.trim(),
      price: int.tryParse(priceController.text.trim()) ?? 0,
      imagePath: imageController.text.trim(),
      flowerType: flowerController.text.trim(),
      categoryId: categoryId,
      inStock: inStock,
      stockCount: int.tryParse(stockController.text.trim()) ?? 0,
      popular: popular,
    );

    try {
      if (product == null) {
        await ApiService.createProduct(updated);
      } else {
        await ApiService.updateProduct(updated);
      }
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _toggleStock(Product product) async {
    try {
      await ApiService.updateStock(product.id, !product.inStock, product.stockCount);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _deleteProduct(Product product) async {
    try {
      await ApiService.deleteProduct(product.id);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Өнімдер', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: darkPink,
        onPressed: () => _showEditor(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE60064)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        product.imagePath,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.local_florist, color: darkPink),
                      ),
                    ),
                    title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${product.formattedPrice} • Stock: ${product.stockCount}'),
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        IconButton(
                          icon: Icon(product.inStock ? Icons.check_circle : Icons.remove_circle, color: darkPink),
                          onPressed: () => _toggleStock(product),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.black54),
                          onPressed: () => _showEditor(product: product),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
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
