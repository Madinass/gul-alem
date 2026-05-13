import 'package:flutter/material.dart';
import 'add_to_cart_sheet.dart';
import 'app_language.dart';
import 'product.dart';
import 'services/api_service.dart';
import 'widgets/product_card.dart';

enum FavoriteSort { priceAsc, priceDesc }

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final Color darkPink = const Color(0xFFE60064);
  bool _loading = true;
  List<Product> _favorites = [];
  FavoriteSort _sort = FavoriteSort.priceAsc;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final data = await ApiService.fetchFavorites();
      if (!mounted) return;
      setState(() {
        _favorites = data;
        _sortFavorites();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _sortFavorites() {
    _favorites.sort(
      (a, b) => _sort == FavoriteSort.priceAsc
          ? a.price.compareTo(b.price)
          : b.price.compareTo(a.price),
    );
  }

  Future<void> _toggleFavorite(Product product) async {
    final t = context.t;
    try {
      await ApiService.removeFavorite(product.id);
      if (!mounted) return;
      setState(() {
        _favorites.removeWhere((item) => item.id == product.id);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.removeFavoriteFailed)));
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(t.favorites, style: const TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          PopupMenuButton<FavoriteSort>(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onSelected: (value) {
              setState(() {
                _sort = value;
                _sortFavorites();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: FavoriteSort.priceAsc,
                child: Text(t.priceAsc),
              ),
              PopupMenuItem(
                value: FavoriteSort.priceDesc,
                child: Text(t.priceDesc),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE60064)),
            )
          : _favorites.isEmpty
          ? Center(child: Text(t.favoritesEmpty))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final product = _favorites[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ProductListCard(
                    product: product,
                    isFavorite: true,
                    onTap: () => showAddToCartSheet(context, product),
                    onFavoritePressed: () => _toggleFavorite(product),
                    onAddToCartPressed: () => _addToCart(product),
                    accentColor: darkPink,
                    borderColor: const Color(0xFFFFE6EB),
                  ),
                );
              },
            ),
    );
  }
}
