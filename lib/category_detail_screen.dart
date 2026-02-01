import 'package:flutter/material.dart';
import 'product.dart';
import 'services/api_service.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryId;
  final int categoryIndex;
  final String categoryName;

  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
    required this.categoryIndex,
    required this.categoryName,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final Color darkPink = const Color.fromARGB(255, 230, 0, 100);
  List<Product> products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final data = await ApiService.fetchProducts(categoryId: widget.categoryId);
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
        title: Text('Категория ${widget.categoryIndex}', style: const TextStyle(color: Colors.black)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.auto_awesome, size: 80, color: darkPink),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              _categoryDescription(widget.categoryIndex),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE60064)))
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Container(
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
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  product.imagePath,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.local_florist, size: 50, color: darkPink),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(product.formattedPrice, style: TextStyle(color: darkPink)),
                                  if (!product.inStock)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text('Out of stock', style: TextStyle(color: Colors.red, fontSize: 12)),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _categoryDescription(int index) {
    switch (index) {
      case 1:
        return 'Гүлдер санаты — күнделікті қуаныш пен мерекеге сай әсем гүлдер.';
      case 2:
        return 'Букеттер санаты — үйлесімі мінсіз, дайын композициялар.';
      case 3:
        return 'Раушан санаты — махаббат пен ілтипаттың классикалық таңдауы.';
      case 4:
        return 'Қызғалдақ санаты — көктемнің шуақты көңіл-күйін сыйлайды.';
      case 5:
        return 'Балаларға арналған — жұмсақ реңк, көңілді пішіндер.';
      case 6:
        return 'Ұсыныс жасауға — әсерлі әрі ұмытылмас букеттер.';
      case 7:
        return 'Сыйлыққа — кез келген жағдайға сай композициялар.';
      case 8:
        return 'Жеуге болатын — тәтті сыйлық пен әдемі безендіру.';
      case 9:
        return 'Шарлар — мерекені жарқыратып, көңіл күйді көтереді.';
      default:
        return 'Бұл санатта таңдаулы өнімдер жинақталған.';
    }
  }
}
