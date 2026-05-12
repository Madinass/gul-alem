class CustomBouquetItem {
  final String id;
  final String name;
  final String group;
  final int price;
  final int stockCount;
  final bool inStock;
  final int order;
  final String imagePath;
  final String imageUrl;

  const CustomBouquetItem({
    required this.id,
    required this.name,
    required this.group,
    required this.price,
    required this.stockCount,
    required this.inStock,
    required this.order,
    this.imagePath = '',
    this.imageUrl = '',
  });

  factory CustomBouquetItem.fromJson(Map<String, dynamic> json) {
    return CustomBouquetItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      group: (json['group'] ?? 'extras').toString(),
      price: _readInt(json['price']),
      stockCount: _readInt(json['stockCount']),
      inStock: json['inStock'] ?? true,
      order: _readInt(json['order']),
      imagePath: (json['imagePath'] ?? json['imageUrl'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
    );
  }

  bool get available => inStock && stockCount > 0;

  String get displayImage => imageUrl.isNotEmpty ? imageUrl : imagePath;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'group': group,
      'price': price,
      'stockCount': stockCount,
      'inStock': inStock,
      'order': order,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
    };
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
