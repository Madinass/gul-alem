import 'product.dart';

class CartItem {
  final String id;
  final String itemType;
  final Product product;
  final int quantity;
  final String description;

  CartItem({
    required this.id,
    required this.itemType,
    required this.product,
    required this.quantity,
    this.description = '',
  });

  bool get isCustom => itemType == 'custom';

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final itemType = json['itemType']?.toString() ?? 'product';
    final product = Product.fromJson(json['product'] ?? {});
    return CartItem(
      id: itemType == 'custom' ? (json['id']?.toString() ?? '') : product.id,
      itemType: itemType,
      product: product,
      quantity: (json['quantity'] ?? 1) is int
          ? json['quantity']
          : (json['quantity'] as num).toInt(),
      description: json['description']?.toString() ?? '',
    );
  }

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      itemType: itemType,
      product: product,
      quantity: quantity ?? this.quantity,
      description: description,
    );
  }

  int get lineTotal => product.price * quantity;

  String get formattedLineTotal => Product.formatPrice(lineTotal);
}
