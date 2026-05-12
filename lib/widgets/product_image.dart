import 'package:flutter/material.dart';

import '../product.dart';

class ProductImage extends StatelessWidget {
  final Product product;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;

  const ProductImage({
    super.key,
    required this.product,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final source = product.displayImage;
    final fallback =
        errorWidget ??
        SizedBox(
          width: width,
          height: height,
          child: const Center(child: Icon(Icons.local_florist)),
        );

    if (source.isEmpty) return fallback;

    final uri = Uri.tryParse(source);
    final isNetwork =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

    if (isNetwork) {
      return Image.network(
        source,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    return Image.asset(
      source,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}
