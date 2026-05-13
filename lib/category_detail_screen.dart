import 'package:flutter/material.dart';
import 'add_to_cart_sheet.dart';
import 'app_language.dart';
import 'product.dart';
import 'services/api_service.dart';
import 'widgets/product_image.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFav ? t.removeFavoriteFailed : t.addFavoriteFailed),
        ),
      );
    }
  }

  Future<void> _addToCart(Product product) async {
    final t = context.t;
    try {
      await ApiService.addToCart(product.id, quantity: 1);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.addedToCart)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.addToCartFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
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
                          childAspectRatio: 0.75,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final isFav = _favoriteIds.contains(product.id);
                      return InkWell(
                        onTap: () => showAddToCartSheet(context, product),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: ProductImage(
                                        product: product,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        errorWidget: Icon(
                                          Icons.local_florist,
                                          size: 50,
                                          color: darkPink,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          t.productName(product),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          t.priceValue(product.price),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: darkPink),
                                        ),
                                        if (!product.inStock)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              t.outOfStock,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        IconButton(
                                          onPressed: () => _addToCart(product),
                                          icon: Icon(
                                            Icons.add_circle,
                                            color: darkPink,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  onPressed: () => _toggleFavorite(product),
                                  icon: Icon(
                                    isFav
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: darkPink,
                                  ),
                                ),
                              ),
                            ],
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
