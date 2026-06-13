import 'package:flutter/material.dart';
import 'add_to_cart_sheet.dart';
import 'app_language.dart';
import 'product.dart';
import 'services/api_service.dart';
import 'widgets/product_card.dart';
import 'widgets/top_toast.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final String? occasionFilter;
  final String? recipientFilter;

  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.occasionFilter,
    this.recipientFilter,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final Color darkPink = const Color.fromARGB(255, 230, 0, 100);
  List<Product> products = [];
  bool _loading = true;
  Set<String> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadFavorites();
  }

  Future<void> _loadProducts() async {
    try {
      final data = await ApiService.fetchProducts(
        categoryId: widget.categoryId,
        occasion: widget.occasionFilter,
        recipient: widget.recipientFilter,
      );
      if (!mounted) return;
      setState(() {
        products = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await ApiService.fetchFavorites();
      if (!mounted) return;
      setState(() {
        _favoriteIds = favorites.map((item) => item.id).toSet();
      });
    } catch (_) {}
  }

  Future<void> _toggleFavorite(Product product) async {
    final t = context.t;
    final isFav = _favoriteIds.contains(product.id);
    try {
      if (isFav) {
        await ApiService.removeFavorite(product.id);
      } else {
        await ApiService.addFavorite(product.id);
      }
      if (!mounted) return;
      setState(() {
        if (isFav) {
          _favoriteIds.remove(product.id);
        } else {
          _favoriteIds.add(product.id);
        }
      });
    } catch (_) {
      if (!mounted) return;
      showTopToast(
        context,
        isFav ? t.removeFavoriteFailed : t.addFavoriteFailed,
      );
    }
  }

  Future<void> _addToCart(Product product) async {
    final t = context.t;
    try {
      await ApiService.addToCart(product.id, quantity: 1);
      if (!mounted) return;
      showTopToast(context, t.addedToCart);
    } catch (_) {
      if (!mounted) return;
      showTopToast(context, t.addToCartFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE60064)),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 276,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final isFav = _favoriteIds.contains(product.id);
                      return ProductCard(
                        product: product,
                        isFavorite: isFav,
                        onTap: () => showAddToCartSheet(context, product),
                        onAddToCartPressed: () => _addToCart(product),
                        onFavoritePressed: () => _toggleFavorite(product),
                        accentColor: darkPink,
                        borderColor: const Color(0xFFFFE6EB),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
