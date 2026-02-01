class Category {
  final String id;
  final String name;
  final String imagePath;
  final int order;

  Category({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.order,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      imagePath: json['imagePath'] ?? '',
      order: json['order'] ?? 0,
    );
  }
}
