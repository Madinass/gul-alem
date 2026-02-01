import 'product.dart';

class CartItem {
  final Product product;
  final int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product'] ?? {}),
      quantity: (json['quantity'] ?? 1) is int ? json['quantity'] : (json['quantity'] as num).toInt(),
    );
  }

  int get lineTotal => product.price * quantity;

  String get formattedLineTotal => Product.formatPrice(lineTotal);
}
