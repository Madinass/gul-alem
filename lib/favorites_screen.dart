import 'package:flutter/material.dart';
import 'add_to_cart_sheet.dart';
import 'product.dart';
import 'services/api_service.dart';

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
    _favorites.sort((a, b) => _sort == FavoriteSort.priceAsc ? a.price.compareTo(b.price) : b.price.compareTo(a.price));
  }

  Future<void> _toggleFavorite(Product product) async {
    try {
      await ApiService.removeFavorite(product.id);
      if (!mounted) return;
      setState(() {
        _favorites.removeWhere((item) => item.id == product.id);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Таңдаулыдан өшіру сәтсіз')),
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
        title: const Text('Таңдаулылар', style: TextStyle(color: Colors.black)),
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
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: FavoriteSort.priceAsc,
                child: Text('Баға: өсуі бойынша'),
              ),
              PopupMenuItem(
                value: FavoriteSort.priceDesc,
                child: Text('Баға: төмендеуі бойынша'),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE60064)))
          : _favorites.isEmpty
              ? const Center(child: Text('Таңдаулы өнімдер жоқ'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final product = _favorites[index];
                    return InkWell(
                      onTap: () => showAddToCartSheet(context, product),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFE6EB)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                product.imagePath,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.pink[50],
                                  child: Icon(Icons.local_florist, color: darkPink),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Text(product.formattedPrice, style: TextStyle(color: darkPink)),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.favorite, color: darkPink),
                                  onPressed: () => _toggleFavorite(product),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add_circle, color: darkPink),
                                  onPressed: () async {
                                    try {
                                      await ApiService.addToCart(product.id, quantity: 1);
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Себетке қосылды')),
                                      );
                                    } catch (_) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Себетке қосу сәтсіз')),
                                      );
                                    }
                                  },
                                ),
                              ],
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
