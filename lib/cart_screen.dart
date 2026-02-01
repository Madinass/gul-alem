import 'package:flutter/material.dart';
import 'cart_item.dart';
import 'product.dart';
import 'services/api_service.dart';
import 'cart_payment_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Color darkPink = const Color(0xFFE60064);
  bool _loading = true;
  List<CartItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final data = await ApiService.fetchCartItems();
      if (!mounted) return;
      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  int get _total => _items.fold(0, (sum, item) => sum + item.lineTotal);

  Future<void> _updateQuantity(CartItem item, int quantity) async {
    try {
      await ApiService.updateCartItem(item.product.id, quantity: quantity);
      if (!mounted) return;
      setState(() {
        if (quantity <= 0) {
          _items.removeWhere((element) => element.product.id == item.product.id);
        } else {
          final index = _items.indexWhere((element) => element.product.id == item.product.id);
          if (index != -1) {
            _items[index] = CartItem(product: item.product, quantity: quantity);
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Себетті жаңарту сәтсіз')),
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
        title: const Text('Себет', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE60064)))
          : _items.isEmpty
              ? const Center(child: Text('Себет бос'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Container(
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
                                    item.product.imagePath,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 64,
                                      height: 64,
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
                                      Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: item.quantity > 1
                                                ? () => _updateQuantity(item, item.quantity - 1)
                                                : () => _updateQuantity(item, 0),
                                            icon: const Icon(Icons.remove_circle_outline),
                                          ),
                                          Text('${item.quantity}', style: const TextStyle(fontSize: 16)),
                                          IconButton(
                                            onPressed: () => _updateQuantity(item, item.quantity + 1),
                                            icon: const Icon(Icons.add_circle_outline),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  Product.formatPrice(item.lineTotal),
                                  style: TextStyle(fontWeight: FontWeight.bold, color: darkPink),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF6F8),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Жалпы сома', style: TextStyle(color: Colors.black54)),
                                const SizedBox(height: 6),
                                Text(
                                  Product.formatPrice(_total),
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkPink),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: darkPink,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () async {
                              if (_items.isEmpty) return;
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CartPaymentScreen(items: _items, total: _total),
                                ),
                              );
                              await _loadCart();
                            },
                            child: const Text('Жалғастыру', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
