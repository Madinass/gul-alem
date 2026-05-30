import 'product.dart';

class CustomCartItem {
  final String id;
  final String name;
  final String group;
  final String imagePath;
  final String imageUrl;
  final int price;
  final int quantity;

  const CustomCartItem({
    required this.id,
    required this.name,
    required this.group,
    required this.imagePath,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });

  factory CustomCartItem.fromJson(Map<String, dynamic> json) {
    return CustomCartItem(
      id: (json['customItemId'] ?? json['itemId'] ?? json['id'] ?? '')
          .toString(),
      name: (json['name'] ?? '').toString(),
      group: (json['group'] ?? 'extras').toString(),
      imagePath: (json['imagePath'] ?? json['imageUrl'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      price: _readInt(json['price']),
      quantity: _readInt(json['quantity'], 1),
    );
  }

  String get displayImage => imageUrl.isNotEmpty ? imageUrl : imagePath;

  int get lineTotal => price * quantity;
}

class CartItem {
  final String id;
  final String itemType;
  final Product product;
  final int quantity;
  final String description;
  final String cardMessage;
  final String customName;
  final List<CustomCartItem> customItems;

  CartItem({
    required this.id,
    required this.itemType,
    required this.product,
    required this.quantity,
    this.description = '',
    this.cardMessage = '',
    this.customName = '',
    this.customItems = const [],
  });

  bool get isCustom => itemType == 'custom';

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final itemType = json['itemType']?.toString() ?? 'product';
    final product = Product.fromJson(json['product'] ?? {});
    return CartItem(
      id: itemType == 'custom' ? (json['id']?.toString() ?? '') : product.id,
      itemType: itemType,
      product: product,
      quantity: _readInt(json['quantity'], 1),
      description: json['description']?.toString() ?? '',
      cardMessage: json['cardMessage']?.toString() ?? '',
      customName: json['customName']?.toString() ?? '',
      customItems: _readCustomItems(json['customItems']),
    );
  }

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      itemType: itemType,
      product: product,
      quantity: quantity ?? this.quantity,
      description: description,
      cardMessage: cardMessage,
      customName: customName,
      customItems: customItems,
    );
  }

  int get lineTotal => product.price * quantity;

  String get formattedLineTotal => Product.formatPrice(lineTotal);
}

List<CustomCartItem> _readCustomItems(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => CustomCartItem.fromJson(Map<String, dynamic>.from(item)))
      .where((item) => item.id.isNotEmpty && item.quantity > 0)
      .toList();
}

int _readInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
