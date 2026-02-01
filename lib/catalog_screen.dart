import 'package:flutter/material.dart';
import 'add_to_cart_sheet.dart';
import 'category_detail_screen.dart';
import 'category.dart';
import 'filter_option_screen.dart';
import 'filter_options.dart';
import 'product.dart';
import 'main_wrapper.dart';
import 'services/api_service.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final Color darkPink = const Color.fromARGB(255, 230, 0, 100);
  final Color navBarPink = const Color.fromARGB(255, 255, 230, 235);

  List<Category> categories = [];
  String? _selectedOccasionId;
  String? _selectedRecipientId;
  List<Product> _filteredProducts = [];
  bool _loadingFilteredProducts = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await ApiService.fetchCategories();
      if (!mounted) return;
      setState(() {
        categories = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }
  Future<void> _loadFilteredProducts() async {
    if (_selectedOccasionId == null && _selectedRecipientId == null) {
      if (!mounted) return;
      setState(() {
        _filteredProducts = [];
        _loadingFilteredProducts = false;
      });
      return;
    }

    setState(() => _loadingFilteredProducts = true);
    try {
      final data = await ApiService.fetchProducts(
        occasion: _selectedOccasionId,
        recipient: _selectedRecipientId,
      );
      if (!mounted) return;
      setState(() {
        _filteredProducts = data;
        _loadingFilteredProducts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingFilteredProducts = false);
    }
  }
  bool _isFilterCategory(Category category) {
    final path = category.imagePath.toLowerCase();
    return path.contains('cat_5') || path.contains('cat_6');
  }

  Category? _findFilterCategory(String token) {
    for (final category in categories) {
      if (category.imagePath.toLowerCase().contains(token)) {
        return category;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final filterOne = _findFilterCategory('cat_5');
    final filterTwo = _findFilterCategory('cat_6');
    final iconCategories = categories.where((category) => !_isFilterCategory(category)).toList();
    final selectedOccasionLabel = labelForFilterOption(occasionFilterOptions, _selectedOccasionId);
    final selectedRecipientLabel = labelForFilterOption(recipientFilterOptions, _selectedRecipientId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox.shrink(),
        leadingWidth: 0,
        title: const Text(
          '\u041a\u0430\u0442\u0430\u043b\u043e\u0433',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE60064)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '\u0421\u04af\u0437\u0433\u0456\u043b\u0435\u0440',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _buildFilterCard(
                            label: selectedRecipientLabel ?? '\u041a\u0456\u043c\u0433\u0435',
                            title:
                                '\u0411\u0443\u043a\u0435\u0442 \u043a\u0456\u043c\u0433\u0435 \u0430\u0440\u043d\u0430\u043b\u0493\u0430\u043d?',
                            options: recipientFilterOptions,
                            selectedId: _selectedRecipientId,
                            category: filterOne,
                            onSelected: (value) => _selectedRecipientId = value,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _buildFilterCard(
                            label: selectedOccasionLabel ?? '\u0421\u0435\u0431\u0435\u043f',
                            title: '\u0421\u0435\u0431\u0435\u0431\u0456\u043d \u0442\u0430\u04a3\u0434\u0430\u04a3\u044b\u0437',
                            options: occasionFilterOptions,
                            selectedId: _selectedOccasionId,
                            category: filterTwo,
                            onSelected: (value) => _selectedOccasionId = value,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedOccasionId != null || _selectedRecipientId != null) ...[
                    const SizedBox(height: 20),
                    const Text(
                      '\u0421\u04af\u0437\u0433\u0456 \u043d\u04d9\u0442\u0438\u0436\u0435\u043b\u0435\u0440\u0456',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (_loadingFilteredProducts)
                      const Center(child: CircularProgressIndicator(color: Color(0xFFE60064)))
                    else if (_filteredProducts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('\u0421\u04d9\u0439\u043a\u0435\u0441 \u04e9\u043d\u0456\u043c \u0442\u0430\u0431\u044b\u043b\u043c\u0430\u0434\u044b'),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return InkWell(
                            onTap: () => showAddToCartSheet(context, product),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
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
                                        Text(
                                          product.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(product.formattedPrice,
                                            style: TextStyle(color: darkPink)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 20),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    '\u041a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u044f\u043b\u0430\u0440',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    itemCount: iconCategories.length,
                    itemBuilder: (context, index) {
                      final category = iconCategories[index];
                      return _buildCategoryIcon(category);
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterCard({
    required String label,
    required String title,
    required List<FilterOption> options,
    required String? selectedId,
    required void Function(String? value) onSelected,
    Category? category,
  }) {
    final isSelected = selectedId != null;
    return GestureDetector(
      onTap: () async {
        final selected = await Navigator.push<String?>(
          context,
          MaterialPageRoute(
            builder: (context) => FilterOptionScreen(
              title: title,
              options: options,
              selectedId: selectedId,
            ),
          ),
        );
        if (!mounted) return;
        setState(() => onSelected(selected));
        _loadFilteredProducts();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isSelected ? darkPink : navBarPink, width: 2),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: category == null
                    ? Container(color: navBarPink)
                    : SizedBox.expand(
                        child: Image.asset(
                          category.imagePath,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0.35, 0),
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.local_florist, size: 51, color: darkPink),
                        ),
                      ),
              ),
              const SizedBox.shrink(),
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(Icons.check_circle, color: darkPink, size: 22),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(Category category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryDetailScreen(
              categoryId: category.id,
              categoryName: category.name,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: navBarPink, width: 2),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  category.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.local_florist, size: 36, color: darkPink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



