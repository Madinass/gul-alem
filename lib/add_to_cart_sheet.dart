import 'package:flutter/material.dart';
import 'app_language.dart';
import 'product.dart';
import 'services/api_service.dart';
import 'widgets/product_image.dart';

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
                    Row(
                      children: [
                        IconButton(
                          onPressed: quantity > 1
                              ? () => setState(() => quantity -= 1)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('$quantity', style: const TextStyle(fontSize: 16)),
                        IconButton(
                          onPressed:
                              canAddToCart && quantity < product.stockCount
                              ? () => setState(() => quantity += 1)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(t.addedToCart)),
                                );
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(t.addToCartFailed)),
                                );
                              }
                            }
                          }
                        : null,
                    child: Text(
                      t.confirm,
                      style: const TextStyle(color: Colors.white),
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
