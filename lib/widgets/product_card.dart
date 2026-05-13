import 'package:flutter/material.dart';

import '../app_language.dart';
import '../product.dart';
import 'product_image.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCartPressed;
  final VoidCallback? onFavoritePressed;
  final double? width;
  final EdgeInsetsGeometry margin;
  final Color accentColor;
  final Color borderColor;

  const ProductCard({
    super.key,
    required this.product,
    required this.isFavorite,
    this.onTap,
    this.onAddToCartPressed,
    this.onFavoritePressed,
    this.width,
    this.margin = EdgeInsets.zero,
    this.accentColor = const Color(0xFFE60064),
    this.borderColor = const Color(0xFFFFE6EB),
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final canAddToCart = product.inStock && onAddToCartPressed != null;

    return Container(
      width: width,
      margin: margin,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: ColoredBox(
                              color: const Color(0xFFFFF7FA),
                              child: ProductImage(
                                product: product,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                errorWidget: Icon(
                                  Icons.local_florist,
                                  color: accentColor,
                                  size: 48,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: _RoundIconButton(
                            icon: isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: accentColor,
                            tooltip: t.favorites,
                            onPressed: onFavoritePressed,
                          ),
                        ),
                        Positioned(
                          left: 6,
                          bottom: 6,
                          child: _StockBadge(
                            label: product.inStock ? t.inStock : t.outOfStock,
                            color: product.inStock
                                ? const Color(0xFF1F9D55)
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.productName(product),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF21171D),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.priceValue(product.price),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: canAddToCart ? onAddToCartPressed : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        disabledBackgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.grey.shade600,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_cart_outlined, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              product.inStock ? t.addToCart : t.outOfStock,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProductListCard extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCartPressed;
  final VoidCallback? onFavoritePressed;
  final Color accentColor;
  final Color borderColor;

  const ProductListCard({
    super.key,
    required this.product,
    required this.isFavorite,
    this.onTap,
    this.onAddToCartPressed,
    this.onFavoritePressed,
    this.accentColor = const Color(0xFFE60064),
    this.borderColor = const Color(0xFFFFE6EB),
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final canAddToCart = product.inStock && onAddToCartPressed != null;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ColoredBox(
                  color: const Color(0xFFFFF7FA),
                  child: ProductImage(
                    product: product,
                    width: 82,
                    height: 82,
                    fit: BoxFit.contain,
                    errorWidget: SizedBox(
                      width: 82,
                      height: 82,
                      child: Icon(Icons.local_florist, color: accentColor),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.priceValue(product.price),
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.inStock ? t.inStock : t.outOfStock,
                      style: TextStyle(
                        color: product.inStock
                            ? const Color(0xFF1F9D55)
                            : Colors.black45,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RoundIconButton(
                    icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: accentColor,
                    tooltip: t.favorites,
                    onPressed: onFavoritePressed,
                  ),
                  const SizedBox(height: 8),
                  _RoundIconButton(
                    icon: Icons.shopping_cart_outlined,
                    color: canAddToCart ? accentColor : Colors.grey,
                    tooltip: t.addToCart,
                    onPressed: canAddToCart ? onAddToCartPressed : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;

  const _RoundIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 34, height: 34),
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StockBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
