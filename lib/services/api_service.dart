import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../product.dart';
import '../category.dart';

class ApiService {
  // for android: http://10.0.2.2:3000
  static const String baseUrl = 'http://127.0.0.1:3000';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> storeSession({required String token, required String role, required String email, required String name}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_role', role);
    await prefs.setString('auth_email', email);
    await prefs.setString('auth_name', name);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_role');
    await prefs.remove('auth_email');
    await prefs.remove('auth_name');
  }

  static Future<Map<String, dynamic>> login(String login, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'login': login, 'password': password}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw Exception('Login failed');
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
      }),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw Exception('Registration failed');
  }

  static Future<List<Category>> fetchCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Category.fromJson(item)).toList();
    }
    throw Exception('Failed to load categories');
  }

  static Future<List<Product>> fetchProducts({String? categoryId, bool popularOnly = false}) async {
    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: {
      if (categoryId != null) 'categoryId': categoryId,
      if (popularOnly) 'popular': 'true',
    });
    final response = await http.get(uri);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Product.fromJson(item)).toList();
    }
    throw Exception('Failed to load products');
  }

  static Future<List<dynamic>> fetchOrders() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load orders');
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to update order');
    }
  }

  static Future<List<dynamic>> fetchAdmins() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/admins'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load admins');
  }

  static Future<void> addAdmin(String email) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/admins'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to add admin');
    }
  }

  static Future<void> removeAdmin(String email) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/admins/$email'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to remove admin');
    }
  }

  static Future<Product> createProduct(Product product) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': product.name,
        'price': product.price,
        'imagePath': product.imagePath,
        'flowerType': product.flowerType,
        'categoryId': product.categoryId,
        'inStock': product.inStock,
        'stockCount': product.stockCount,
        'popular': product.popular,
      }),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Product.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create product');
  }

  static Future<Product> updateProduct(Product product) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/products/${product.id}'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': product.name,
        'price': product.price,
        'imagePath': product.imagePath,
        'flowerType': product.flowerType,
        'categoryId': product.categoryId,
        'inStock': product.inStock,
        'stockCount': product.stockCount,
        'popular': product.popular,
      }),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Product.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update product');
  }

  static Future<void> updateStock(String productId, bool inStock, int stockCount) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/products/$productId/stock'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'inStock': inStock, 'stockCount': stockCount}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to update stock');
    }
  }

  static Future<void> deleteProduct(String productId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/products/$productId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete product');
    }
  }

  static Future<String> sendChatMessage(String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return data['message'] ?? '';
    }
    throw Exception('AI request failed');
  }
}
