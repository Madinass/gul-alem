// lib/product.dart
import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final String price;
  final Color color;
  final String imagePath; // Сурет жолы міндетті

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.color,
    required this.imagePath,
  });
}