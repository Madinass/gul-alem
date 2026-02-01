import 'package:flutter/material.dart';
import 'product.dart'; // Product моделін алу үшін

class ProductDetailScreen extends StatefulWidget {
  final Product initialProduct;
  final List<Product> products;

  const ProductDetailScreen({
    super.key,
    required this.initialProduct,
    required this.products,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;

  final Color darkPink = const Color.fromARGB(255, 230, 0, 100);
  final Color accentPink = const Color.fromARGB(255, 238, 111, 151);
  final Color navBarPink = const Color.fromARGB(255, 255, 230, 235);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.products.indexOf(widget.initialProduct);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Әр өнім беті
  Widget _buildProductPage(Product product, Size screenSize) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Өнім суреті
          Container(
            width: screenSize.width * 0.8,
            height: screenSize.height * 0.4,
            decoration: BoxDecoration(
              color: product.color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Image.asset(
              product.imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.local_florist,
                color: darkPink.withOpacity(0.7),
                size: 100,
              ),
            ),
          ),
          const SizedBox(height: 25),
          // Өнім атауы
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          // Бағасы
          Text(
            product.formattedPrice,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: darkPink,
            ),
          ),
          const SizedBox(height: 20),
          // Өнім сипаттамасы
          const Text(
            'Бұл гүл – нәзіктіктің және сұлулықтың символы. '
            'Кез келген мерекеге немесе жақыныңызға сый ретінде мінсіз таңдау',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const Spacer(),
          // Себетке қосу батырмасы
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} себетке қосылды!'),
                  backgroundColor: darkPink,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            label: const Text(
              'Себетке қосу',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentPink,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Төменгі навигация жолағы
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: navBarPink,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      height: 70,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(icon: Icon(Icons.home, color: darkPink, size: 28), onPressed: () {}),
          IconButton(icon: Icon(Icons.favorite_border, color: darkPink, size: 28), onPressed: () {}),
          IconButton(icon: Icon(Icons.shopping_cart_outlined, color: darkPink, size: 28), onPressed: () {}),
          IconButton(icon: Icon(Icons.person_outline, color: darkPink, size: 28), onPressed: () {}),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            widget.products[_currentIndex].name,
            key: ValueKey(widget.products[_currentIndex].id),
            style: TextStyle(color: darkPink, fontWeight: FontWeight.bold),
          ),
        ),
        iconTheme: IconThemeData(color: darkPink),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.products.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final product = widget.products[index];
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 1.0;
              if (_pageController.position.haveDimensions) {
                value = _pageController.page! - index;
                value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
              }
              return Transform.scale(scale: value, child: child);
            },
            child: _buildProductPage(product, screenSize),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}
