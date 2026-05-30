int _readInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _readBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return fallback;
}

class AdminProductSales {
  final String id;
  final String name;
  final String imagePath;
  final String imageUrl;
  final int price;
  final int soldQuantity;
  final int salesTotal;

  const AdminProductSales({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.imageUrl,
    required this.price,
    required this.soldQuantity,
    required this.salesTotal,
  });

  factory AdminProductSales.fromJson(Map<String, dynamic> json) {
    return AdminProductSales(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imagePath: json['imagePath']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      price: _readInt(json['price']),
      soldQuantity: _readInt(json['soldQuantity']),
      salesTotal: _readInt(json['salesTotal']),
    );
  }

  String get displayImage => imageUrl.isNotEmpty ? imageUrl : imagePath;
}

class AdminStatistics {
  final bool hasData;
  final int totalOrders;
  final int totalSales;
  final AdminProductSales? topProduct;
  final AdminProductSales? leastProduct;
  final List<AdminProductSales> unsoldProducts;

  const AdminStatistics({
    required this.hasData,
    required this.totalOrders,
    required this.totalSales,
    required this.topProduct,
    required this.leastProduct,
    required this.unsoldProducts,
  });

  factory AdminStatistics.fromJson(Map<String, dynamic> json) {
    final unsold = json['unsoldProducts'];
    return AdminStatistics(
      hasData: _readBool(json['hasData']),
      totalOrders: _readInt(json['totalOrders']),
      totalSales: _readInt(json['totalSales']),
      topProduct: _readProduct(json['topProduct']),
      leastProduct: _readProduct(json['leastProduct']),
      unsoldProducts: unsold is List
          ? unsold
                .whereType<Map>()
                .map(
                  (item) => AdminProductSales.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }

  static AdminProductSales? _readProduct(dynamic value) {
    if (value is! Map) return null;
    return AdminProductSales.fromJson(Map<String, dynamic>.from(value));
  }
}
