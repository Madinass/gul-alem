int _readInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  final text = value?.toString() ?? '';
  return int.tryParse(text) ?? double.tryParse(text)?.toInt() ?? fallback;
}

class OrderCustomItem {
  final String customItemId;
  final String name;
  final String group;
  final String imagePath;
  final String imageUrl;
  final int price;
  final int quantity;

  const OrderCustomItem({
    required this.customItemId,
    required this.name,
    required this.group,
    required this.imagePath,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });

  factory OrderCustomItem.fromJson(Map<String, dynamic> json) {
    return OrderCustomItem(
      customItemId: json['customItemId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      group: json['group']?.toString() ?? '',
      imagePath: json['imagePath']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      price: _readInt(json['price']),
      quantity: _readInt(json['quantity'], 1),
    );
  }

  String get displayImage => imageUrl.isNotEmpty ? imageUrl : imagePath;
}

class OrderItem {
  final String productId;
  final String name;
  final String imagePath;
  final String imageUrl;
  final int price;
  final int quantity;
  final String description;
  final String cardMessage;
  final List<OrderCustomItem> customItems;

  OrderItem({
    required this.productId,
    required this.name,
    required this.imagePath,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    this.description = '',
    this.cardMessage = '',
    this.customItems = const [],
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final rawCustomItems = json['customItems'] as List<dynamic>? ?? [];
    return OrderItem(
      productId: json['productId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imagePath: json['imagePath']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      price: _readInt(json['price']),
      quantity: _readInt(json['quantity'], 1),
      description: json['description']?.toString() ?? '',
      cardMessage: json['cardMessage']?.toString() ?? '',
      customItems: rawCustomItems
          .map((item) => OrderCustomItem.fromJson(item ?? {}))
          .toList(),
    );
  }

  String get displayImage => imageUrl.isNotEmpty ? imageUrl : imagePath;

  bool get isCustomBouquet {
    final image = displayImage.toLowerCase();
    return customItems.isNotEmpty ||
        image == 'assets/custom_bouquet/custom_icon.png' ||
        image.endsWith('/custom_icon.png') ||
        image.contains('custom_icon');
  }
}

class OrderModel {
  final String id;
  final String orderType;
  final String description;
  final String cardMessage;
  final List<OrderItem> items;
  final List<OrderCustomItem> customItems;
  final int subtotal;
  final String deliveryMethod;
  final int deliveryPrice;
  final Map<String, dynamic>? pickupStore;
  final String? deliveryAddress;
  final int total;
  final String status;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.orderType,
    required this.description,
    required this.cardMessage,
    required this.items,
    required this.customItems,
    required this.subtotal,
    required this.deliveryMethod,
    required this.deliveryPrice,
    required this.pickupStore,
    required this.deliveryAddress,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] is List ? json['items'] as List : const [];
    final rawCustomItems = json['customItems'] is List
        ? json['customItems'] as List
        : const [];
    return OrderModel(
      id: json['_id']?.toString() ?? '',
      orderType: json['orderType']?.toString() ?? 'standard',
      description: json['description']?.toString() ?? '',
      cardMessage: json['cardMessage']?.toString() ?? '',
      items: rawItems.map((item) => OrderItem.fromJson(item ?? {})).toList(),
      customItems: rawCustomItems
          .map((item) => OrderCustomItem.fromJson(item ?? {}))
          .toList(),
      subtotal: _readInt(json['subtotal'] ?? json['total']),
      deliveryMethod: json['deliveryMethod']?.toString() ?? 'pickup',
      deliveryPrice: _readInt(json['deliveryPrice']),
      pickupStore: json['pickupStore'] is Map
          ? Map<String, dynamic>.from(json['pickupStore'] as Map)
          : null,
      deliveryAddress: json['deliveryAddress']?.toString(),
      total: _readInt(json['total']),
      status: json['status']?.toString() ?? 'pending',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  bool get hasFlower {
    return items.any((item) => _looksLikeFlower(item.name, item.imagePath)) ||
        customItems.any(
          (item) =>
              item.group == 'flowers' ||
              _looksLikeFlower(item.name, item.imagePath),
        );
  }

  bool get hasGreetingCard {
    return cardMessage.isNotEmpty ||
        items.any(
          (item) => _looksLikeGreetingCard(item.name, item.imagePath),
        ) ||
        customItems.any(
          (item) => _looksLikeGreetingCard(item.name, item.imagePath),
        );
  }
}

bool _looksLikeFlower(String name, String imagePath) {
  final value = '${name.toLowerCase()} ${imagePath.toLowerCase()}';
  return value.contains('flower') ||
      value.contains('bouquet') ||
      value.contains('rose') ||
      value.contains('tulip') ||
      value.contains('lily') ||
      value.contains('peony') ||
      value.contains('hydrangea') ||
      value.contains('chrysanthemum') ||
      value.contains('гүл') ||
      value.contains('цвет') ||
      value.contains('раушан') ||
      value.contains('қызғалдақ') ||
      value.contains('букет');
}

bool _looksLikeGreetingCard(String name, String imagePath) {
  final value = '${name.toLowerCase()} ${imagePath.toLowerCase()}';
  return value.contains('card') ||
      value.contains('greeting') ||
      value.contains('ашықхат') ||
      value.contains('открытка');
}
