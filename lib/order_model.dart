int _readInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return fallback;
}

class OrderItem {
  final String name;
  final String imagePath;
  final int price;
  final int quantity;

  OrderItem({
    required this.name,
    required this.imagePath,
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] ?? '',
      imagePath: json['imagePath'] ?? '',
      price: _readInt(json['price']),
      quantity: _readInt(json['quantity'], 1),
    );
  }
}

class OrderModel {
  final String id;
  final String orderType;
  final String description;
  final List<OrderItem> items;
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
    required this.items,
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
    final rawItems = (json['items'] as List<dynamic>? ?? []);
    return OrderModel(
      id: json['_id']?.toString() ?? '',
      orderType: json['orderType']?.toString() ?? 'standard',
      description: json['description']?.toString() ?? '',
      items: rawItems.map((item) => OrderItem.fromJson(item ?? {})).toList(),
      subtotal: _readInt(json['subtotal'] ?? json['total']),
      deliveryMethod: json['deliveryMethod']?.toString() ?? 'pickup',
      deliveryPrice: _readInt(json['deliveryPrice']),
      pickupStore: json['pickupStore'] is Map
          ? Map<String, dynamic>.from(json['pickupStore'] as Map)
          : null,
      deliveryAddress: json['deliveryAddress']?.toString(),
      total: _readInt(json['total']),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
