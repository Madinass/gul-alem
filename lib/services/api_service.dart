import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../cart_item.dart';
import '../product.dart';
import '../category.dart';
import '../notification_item.dart';
import '../order_model.dart';

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
    throw Exception('Кіру сәтсіз');
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
    throw Exception('Тіркелу сәтсіз');
  }

  static Future<void> requestPasswordReset(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Reset code send failed');
    }
  }

  static Future<String> verifyResetCode(String email, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-reset-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return data['resetToken'] ?? '';
    }
    throw Exception('Code verification failed');
  }

  static Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'resetToken': resetToken,
        'newPassword': newPassword,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Password reset failed');
    }
  }

  static Future<List<Category>> fetchCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Category.fromJson(item)).toList();
    }
    throw Exception('Санаттарды жүктеу сәтсіз');
  }

  static Future<List<Product>> fetchProducts({
    String? categoryId,
    bool popularOnly = false,
    String? occasion,
    String? recipient,
  }) async {
    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: {
      if (categoryId != null) 'categoryId': categoryId,
      if (popularOnly) 'popular': 'true',
      if (occasion != null) 'occasion': occasion,
      if (recipient != null) 'recipient': recipient,
    });
    final response = await http.get(uri);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Product.fromJson(item)).toList();
    }
    throw Exception('Өнімдерді жүктеу сәтсіз');
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
    throw Exception('Тапсырыстарды жүктеу сәтсіз');
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Тапсырыс мәртебесін жаңарту сәтсіз');
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
    throw Exception('Әкімшілерді жүктеу сәтсіз');
  }

  static Future<void> addAdmin(String email) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/admins'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Әкімші қосу сәтсіз');
    }
  }

  static Future<void> removeAdmin(String email) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/admins/$email'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Әкімшіні жою сәтсіз');
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
    throw Exception('Өнім құру сәтсіз');
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
    throw Exception('Өнімді жаңарту сәтсіз');
  }

  static Future<void> updateStock(String productId, bool inStock, int stockCount) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/products/$productId/stock'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'inStock': inStock, 'stockCount': stockCount}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Қойма жаңарту сәтсіз');
    }
  }

  static Future<void> updatePopular(String productId, bool popular) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/products/$productId'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'popular': popular}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Танымалдықты жаңарту сәтсіз');
    }
  }

  static Future<void> deleteProduct(String productId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/products/$productId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Өнімді жою сәтсіз');
    }
  }

  static Future<List<dynamic>> fetchChatSessions() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/ai/chats'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw Exception('Чат тарихын жүктеу сәтсіз');
  }

  static Future<Map<String, dynamic>> createChatSession({String? title}) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/ai/chats'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'title': title}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw Exception('Жаңа чат құру сәтсіз');
  }

  static Future<Map<String, dynamic>> fetchChatMessages(String sessionId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/ai/chats/$sessionId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw Exception('Чат хабарламаларын жүктеу сәтсіз');
  }

  static Future<Map<String, dynamic>> sendChatMessage(String message, {String? sessionId}) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/ai/chat'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'message': message, 'sessionId': sessionId}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw Exception('AI хабарламасын жіберу сәтсіз');
  }

  static Future<List<dynamic>> fetchPaymentMethods() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/payment-methods'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw Exception('Төлем әдістерін жүктеу сәтсіз');
  }

  static Future<Map<String, dynamic>> fetchPaymentMethod(String id) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/payment-methods/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw Exception('Төлем әдісін жүктеу сәтсіз');
  }

  static Future<void> createPaymentMethod({
    required String cardholderName,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvv,
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/payment-methods'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'cardholderName': cardholderName,
        'cardNumber': cardNumber,
        'expMonth': expMonth,
        'expYear': expYear,
        'cvv': cvv,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Төлем әдісін құру сәтсіз');
    }
  }

  static Future<void> updatePaymentMethod({
    required String id,
    required String cardholderName,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvv,
  }) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/payment-methods/$id'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'cardholderName': cardholderName,
        'cardNumber': cardNumber,
        'expMonth': expMonth,
        'expYear': expYear,
        'cvv': cvv,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Төлем әдісін жаңарту сәтсіз');
    }
  }

  static Future<void> deletePaymentMethod(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/payment-methods/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Төлем әдісін жою сәтсіз');
    }
  }

  static Future<List<Product>> fetchFavorites() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/favorites'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Product.fromJson(item)).toList();
    }
    throw Exception('Таңдаулыларды жүктеу сәтсіз');
  }

  static Future<void> addFavorite(String productId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/favorites'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'productId': productId}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Таңдаулыға қосу сәтсіз');
    }
  }

  static Future<void> removeFavorite(String productId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/favorites/$productId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Таңдаулыдан жою сәтсіз');
    }
  }

  static Future<List<CartItem>> fetchCartItems() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/cart'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => CartItem.fromJson(item)).toList();
    }
    throw Exception('Себетті жүктеу сәтсіз');
  }

  static Future<void> addToCart(String productId, {int quantity = 1}) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/cart'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'productId': productId, 'quantity': quantity}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Себетке қосу сәтсіз');
    }
  }

  static Future<void> updateCartItem(String productId, {required int quantity}) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/cart/$productId'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'quantity': quantity}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Себетті жаңарту сәтсіз');
    }
  }

  static Future<void> removeFromCart(String productId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/cart/$productId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Себеттен жою сәтсіз');
    }
  }

  static Future<void> clearCart() async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/cart'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Себетті тазалау сәтсіз');
    }
  }

  static Future<OrderModel> createOrder(List<CartItem> items) async {
    final token = await _getToken();
    final payload = items
        .map((item) => {
              'productId': item.product.id,
              'name': item.product.name,
              'imagePath': item.product.imagePath,
              'price': item.product.price,
              'quantity': item.quantity,
            })
        .toList();
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'items': payload}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return OrderModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Тапсырыс жасау сәтсіз');
  }

  static Future<List<OrderModel>> fetchMyOrders() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/orders/my'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => OrderModel.fromJson(item)).toList();
    }
    throw Exception('Менің тапсырыстарымды жүктеу сәтсіз');
  }

  static Future<List<NotificationItem>> fetchNotifications() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => NotificationItem.fromJson(item)).toList();
    }
    throw Exception('Хабарламаларды жүктеу сәтсіз');
  }

  static Future<void> createNotification({
    required String title,
    String message = '',
    String type = 'system',
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/notifications'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'message': message, 'type': type}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Хабарлама құру сәтсіз');
    }
  }

  static Future<void> markNotificationRead(String id) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/notifications/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Хабарламаны оқылғанға белгілеу сәтсіз');
    }
  }

}
