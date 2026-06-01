import 'package:flutter/material.dart';
import 'add_to_cart_sheet.dart';
import 'product.dart';
import 'services/api_service.dart';

class PopularItemsScreen extends StatefulWidget {
  const PopularItemsScreen({super.key});

  @override
  State<PopularItemsScreen> createState() => _PopularItemsScreenState();
}

class _PopularItemsScreenState extends State<PopularItemsScreen> {
  final Color darkPink = const Color(0xFFE60064);
  final Color lightPink = const Color(0xFFFFE6EB);
  List<Product> popularProducts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPopular();
  }

  Future<void> _loadPopular() async {
    try {
      final data = await ApiService.fetchProducts(popularOnly: true);
      if (!mounted) return;
      setState(() {
        popularProducts = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _addToCart(Product product) async {
    try {
      await ApiService.addToCart(product.id, quantity: 1);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Себетке қосылды')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Себетке қосу сәтсіз')));
    }
  }

  String _descriptionFor(Product product) {
    final seed = '${product.flowerType} ${product.name}'.toLowerCase();
    if (seed.contains('rose') ||
        seed.contains('роза') ||
        seed.contains('раушан')) {
      return 'Раушан гүлдері — махаббат пен құрметтің белгісі. Сыйлыққа тамаша таңдау.';
    }
    if (seed.contains('tulip') || seed.contains('тюльпан')) {
      return 'Тюльпан — көктемнің нәзік символы. Жылы көңіл күй сыйлайды.';
    }
    if (seed.contains('lily') || seed.contains('лилия')) {
      return 'Лалагүлдер хош иісімен және салтанатымен ерекшеленеді.';
    }
    if (seed.contains('chrysanthem') || seed.contains('хризантема')) {
      return 'Хризантемалар ұзақ сақталады және күтімі жеңіл.';
    }
    if (seed.contains('peony') || seed.contains('пион')) {
      return 'Пион — сән-салтанаттың символы. Ерекше сәттерге лайық.';
    }
    return 'Бұл букет кез келген мерекеге жарасады және қуаныш сыйлайды.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Танымал гүлдер',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE60064)),
            )
          : popularProducts.isEmpty
          ? const Center(child: Text('Танымал өнімдер табылмады'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: popularProducts.length,
              itemBuilder: (context, index) {
                final product = popularProducts[index];
                return InkWell(
                  onTap: () => showAddToCartSheet(context, product),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: lightPink),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            product.imagePath,
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.local_florist,
                              color: lightPink,
                              size: 50,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.formattedPrice,
                                style: TextStyle(
                                  color: darkPink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _descriptionFor(product),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              if (!product.inStock)
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Қоймада жоқ',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _addToCart(product),
                          icon: Icon(Icons.add_circle, color: darkPink),
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
