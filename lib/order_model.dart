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
      price: (json['price'] ?? 0) is int ? json['price'] : (json['price'] as num).toInt(),
      quantity: (json['quantity'] ?? 1) is int ? json['quantity'] : (json['quantity'] as num).toInt(),
    );
  }
}

class OrderModel {
  final String id;
  final List<OrderItem> items;
  final int total;
  final String status;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>? ?? []);
    return OrderModel(
      id: json['_id']?.toString() ?? '',
      items: rawItems.map((item) => OrderItem.fromJson(item ?? {})).toList(),
      total: (json['total'] ?? 0) is int ? json['total'] : (json['total'] as num).toInt(),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
