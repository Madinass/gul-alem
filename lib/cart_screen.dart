import 'package:flutter/material.dart';
import 'app_language.dart';
import 'cart_item.dart';
import 'services/api_service.dart';
import 'cart_payment_screen.dart';
import 'custom_bouquet_assets.dart';
import 'custom_bouquet_screen.dart';
import 'widgets/product_image.dart';

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

  bool _canIncreaseQuantity(CartItem item) {
    if (item.isCustom) return true;
    return item.product.inStock && item.quantity < item.product.stockCount;
  }

  Future<void> _updateQuantity(CartItem item, int quantity) async {
    final t = context.t;
    if (!item.isCustom &&
        quantity > 0 &&
        quantity > item.product.stockCount) {
      return;
    }
    try {
      await ApiService.updateCartItem(
        item.id,
        quantity: quantity,
        itemType: item.itemType,
      );
      if (!mounted) return;
      setState(() {
        if (quantity <= 0) {
          _items.removeWhere((element) => element.id == item.id);
        } else {
          final index = _items.indexWhere((element) => element.id == item.id);
          if (index != -1) {
            _items[index] = item.copyWith(quantity: quantity);
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.updateCartFailed)));
    }
  }

  Future<void> _editCustomBouquet(CartItem item) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CustomBouquetScreen(cartItem: item),
      ),
    );
    if (saved == true) {
      await _loadCart();
    }
  }

  Widget _imageFallback() {
    return Container(
      width: 64,
      height: 64,
      color: Colors.pink[50],
      child: Icon(Icons.local_florist, color: darkPink),
    );
  }

  Widget _buildCartImage(CartItem item) {
    if (item.isCustom) {
      return Image.asset(
        customBouquetIconAsset,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _imageFallback(),
      );
    }

    return ProductImage(
      product: item.product,
      width: 64,
      height: 64,
      fit: BoxFit.cover,
      errorWidget: _imageFallback(),
    );
  }

  String _cartItemTitle(AppText t, CartItem item) {
    if (!item.isCustom) return t.productName(item.product);

    final customName = item.customName.trim().isNotEmpty
        ? item.customName.trim()
        : item.product.name.trim();
    if (customName.isEmpty || customName == 'Custom bouquet') {
      return t.customBouquet;
    }
    return customName;
  }

  Widget _buildCustomDetails(AppText t, CartItem item) {
    final grouped = <String, List<CustomCartItem>>{};
    for (final customItem in item.customItems) {
      grouped.putIfAbsent(customItem.group, () => []).add(customItem);
    }

    final orderedGroups = [
      for (final group in const ['flowers', 'wrapping', 'extras'])
        if (grouped.containsKey(group)) group,
      for (final group in grouped.keys)
        if (!const ['flowers', 'wrapping', 'extras'].contains(group)) group,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in orderedGroups)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              '${t.customGroupLabel(group)}: ${grouped[group]!.map((item) => _formatCustomDetail(t, item)).join(', ')}',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
      ],
    );
  }

  String _formatCustomDetail(AppText t, CustomCartItem item) {
    return t.customItemQuantity(
      item.quantity,
      t.customItemName(item.imagePath, item.name),
    );
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
        title: Text(t.cart, style: const TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE60064)),
            )
          : _items.isEmpty
          ? Center(child: Text(t.cartEmpty))
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
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildCartImage(item),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _cartItemTitle(t, item),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (item.isCustom &&
                                      item.customItems.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    _buildCustomDetails(t, item),
                                  ],
                                  if (item.isCustom &&
                                      item.description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: item.quantity > 1
                                            ? () => _updateQuantity(
                                                item,
                                                item.quantity - 1,
                                              )
                                            : () => _updateQuantity(item, 0),
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      IconButton(
                                        onPressed: _canIncreaseQuantity(item)
                                            ? () => _updateQuantity(
                                                item,
                                                item.quantity + 1,
                                              )
                                            : null,
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  t.priceValue(item.lineTotal),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: darkPink,
                                  ),
                                ),
                                if (item.isCustom) ...[
                                  const SizedBox(height: 8),
                                  IconButton(
                                    tooltip: t.update,
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _editCustomBouquet(item),
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      color: darkPink,
                                    ),
                                  ),
                                ],
                              ],
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
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.totalAmount,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t.priceValue(_total),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: darkPink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkPink,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          if (_items.isEmpty) return;
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CartPaymentScreen(
                                items: _items,
                                total: _total,
                              ),
                            ),
                          );
                          await _loadCart();
                        },
                        child: Text(
                          t.continueAction,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
