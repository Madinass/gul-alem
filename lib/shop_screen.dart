import 'package:flutter/material.dart';
import 'add_to_cart_sheet.dart';
import 'app_language.dart';
import 'product.dart';
import 'services/api_service.dart';
import 'widgets/notification_badge_button.dart';
import 'widgets/product_card.dart';
import 'widgets/top_toast.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _loading = true;
  List<Product> products = [];
  Set<String> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadFavorites();
  }

  Future<void> _loadProducts() async {
    try {
      final data = await ApiService.fetchProducts();
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
    final t = context.t;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        "assets/icon_flower.png",
                        width: 40,
                        height: 40,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t.appName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const NotificationBadgeButton(size: 28),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.pink[50],
                  hintText: t.searchPlaceholder,
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE60064),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
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
                          onFavoritePressed: () => _toggleFavorite(product),
                          onAddToCartPressed: () => _addToCart(product),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.pink[50],
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: t.appName,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            label: t.catalog,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_border),
            label: t.favorites,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_cart),
            label: t.cart,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: t.profile,
          ),
        ],
      ),
    );
  }
}
