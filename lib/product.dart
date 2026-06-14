import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final String nameKz;
  final String nameRu;
  final String nameEn;
  final int price;
  final Color color;
  final String imagePath;
  final String imageUrl;
  final String flowerType;
  final String? categoryId;
  final bool inStock;
  final int stockCount;
  final bool popular;
  final List<String> occasionTags;
  final List<String> recipientTags;

  Product({
    required this.id,
    required this.name,
    this.nameKz = '',
    this.nameRu = '',
    this.nameEn = '',
    required this.price,
    required this.imagePath,
    this.imageUrl = '',
    required this.flowerType,
    this.categoryId,
    this.inStock = true,
    this.stockCount = 0,
    this.popular = false,
    this.occasionTags = const [],
    this.recipientTags = const [],
    this.color = Colors.white,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nameKz: json['nameKz']?.toString() ?? '',
      nameRu: json['nameRu']?.toString() ?? '',
      nameEn: json['nameEn']?.toString() ?? '',
      price: _readInt(json['price']),
      imagePath: (json['imagePath'] ?? json['imageUrl'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      flowerType: json['flowerType']?.toString() ?? '',
      categoryId: json['categoryId']?.toString(),
      inStock: _readBool(json['inStock'], true),
      stockCount: _readInt(json['stockCount']),
      popular: _readBool(json['popular']),
      occasionTags: _readStringList(json['occasionTags']),
      recipientTags: _readStringList(json['recipientTags']),
    );
  }

  String get formattedPrice => formatPrice(price);

  String get displayImage => imageUrl.isNotEmpty ? imageUrl : imagePath;

  static String formatPrice(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final indexFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write(' ');
      }
    }
    return '${buffer.toString()} тг';
  }

  static List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }

  static int _readInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    final text = value?.toString() ?? '';
    return int.tryParse(text) ?? double.tryParse(text)?.toInt() ?? fallback;
  }

  static bool _readBool(dynamic value, [bool fallback = false]) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
    return fallback;
  }
}
