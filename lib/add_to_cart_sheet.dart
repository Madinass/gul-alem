import 'package:flutter/material.dart';
import 'app_language.dart';
import 'product.dart';
import 'services/api_service.dart';
import 'widgets/product_image.dart';
import 'widgets/top_toast.dart';

Future<void> showAddToCartSheet(BuildContext context, Product product) async {
  final darkPink = const Color(0xFFE60064);
  int quantity = 1;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final t = context.t;
          final canAddToCart = product.inStock && product.stockCount > 0;
          final stockLabel = canAddToCart
              ? t.availableCount(product.stockCount)
              : t.outOfStock;
          final total = product.price * quantity;
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.addToCart,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showImagePreview(
                        context,
                        product,
                        darkPink: darkPink,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ProductImage(
                          product: product,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorWidget: Container(
                            width: 70,
                            height: 70,
                            color: Colors.pink[50],
                            child: Icon(Icons.local_florist, color: darkPink),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.productName(product),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t.priceValue(product.price),
                            style: TextStyle(color: darkPink),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                canAddToCart
                                    ? Icons.check_circle_outline
                                    : Icons.info_outline,
                                size: 16,
                                color: canAddToCart ? darkPink : Colors.black45,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  stockLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: canAddToCart
                                        ? Colors.black54
                                        : Colors.black45,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t.quantity,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    _QuantityStepper(
                      quantity: quantity,
                      accentColor: darkPink,
                      onDecrease: quantity > 1
                          ? () => setState(() => quantity -= 1)
                          : null,
                      onIncrease: canAddToCart && quantity < product.stockCount
                          ? () => setState(() => quantity += 1)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t.totalPrice,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    Text(
                      t.priceValue(total),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: darkPink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkPink,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: canAddToCart
                        ? () async {
                            try {
                              await ApiService.addToCart(
                                product.id,
                                quantity: quantity,
                              );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                showTopToast(context, t.addedToCart);
                              }
                            } catch (_) {
                              if (context.mounted) {
                                showTopToast(context, t.addToCartFailed);
                              }
                            }
                          }
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t.confirm,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final Color accentColor;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const _QuantityStepper({
    required this.quantity,
    required this.accentColor,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE6EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepButton(
            icon: Icons.remove_rounded,
            onPressed: onDecrease,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12),
            ),
          ),
          SizedBox(
            width: 42,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          _stepButton(
            icon: Icons.add_rounded,
            onPressed: onIncrease,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required BorderRadius borderRadius,
  }) {
    final enabled = onPressed != null;
    return InkWell(
      onTap: onPressed,
      borderRadius: borderRadius,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(
          icon,
          color: enabled ? accentColor : Colors.black26,
          size: 22,
        ),
      ),
    );
  }
}

Future<void> _showImagePreview(
  BuildContext context,
  Product product, {
  required Color darkPink,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Material(
        color: Colors.black87,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 3,
                  child: ProductImage(
                    product: product,
                    fit: BoxFit.contain,
                    errorWidget: Icon(
                      Icons.local_florist,
                      size: 140,
                      color: darkPink,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  color: Colors.white,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
