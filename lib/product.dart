import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final int price;
  final Color color;
  final String imagePath;
  final String flowerType;
  final String? categoryId;
  final bool inStock;
  final int stockCount;
  final bool popular;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imagePath,
    required this.flowerType,
    this.categoryId,
    this.inStock = true,
    this.stockCount = 0,
    this.popular = false,
    this.color = Colors.white,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0) is int ? json['price'] : (json['price'] as num).toInt(),
      imagePath: json['imagePath'] ?? '',
      flowerType: json['flowerType'] ?? '',
      categoryId: json['categoryId']?.toString(),
      inStock: json['inStock'] ?? true,
      stockCount: json['stockCount'] ?? 0,
      popular: json['popular'] ?? false,
    );
  }

  String get formattedPrice {
    final digits = price.toString();
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
}
