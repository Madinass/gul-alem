import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../cart_item.dart';
import '../custom_bouquet_item.dart';
import '../product.dart';
import '../category.dart';
import '../notification_item.dart';
import '../order_model.dart';
import 'backend_config.dart' as backend_config;

class AuthException implements Exception {
  final String message;

  const AuthException([this.message = 'Authentication required']);

  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static final String baseUrl = backend_config.baseUrl;
  static const String _deliveryAddressPrefsPrefix =
      'remembered_delivery_address';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static String _deliveryAddressPrefsKey(SharedPreferences prefs) {
    final email = prefs.getString('auth_email') ?? '';
    if (email.isEmpty) return _deliveryAddressPrefsPrefix;
    return '$_deliveryAddressPrefsPrefix:$email';
  }

  static Future<String> _requireToken() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      await clearSession();
      throw const AuthException();
    }
    return token;
  }

  static Future<bool> _isSuccess(http.Response response) async {
    if (response.statusCode == 401) {
      await clearSession();
    }
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  static String _responseMessage(http.Response response, String fallback) {
    try {
      final data = jsonDecode(response.body);
      final message = data is Map<String, dynamic> ? data['message'] : null;
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    } catch (_) {}
    return fallback;
  }

  static String _normalizeExpiryMonth(String value) {
    final digits = value.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return value.trim();
    final month = int.tryParse(digits);
    if (month == null) return value.trim();
    return month.toString().padLeft(2, '0');
  }

  static String _normalizeExpiryYear(String value) {
    final digits = value.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.length == 2) return '20$digits';
    return digits.isEmpty ? value.trim() : digits;
  }

  static Future<void> storeSession({
    required String token,
    required String role,
    required String email,
    required String name,
  }) async {
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

  static Future<void> rememberDeliveryAddress(String address) async {
    final normalized = address.trim();
    if (normalized.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deliveryAddressPrefsKey(prefs), normalized);
  }

  static Future<String> fetchRememberedDeliveryAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_deliveryAddressPrefsKey(prefs))?.trim();
    if (saved != null && saved.isNotEmpty) return saved;

    try {
      final orders = await fetchMyOrders();
      for (final order in orders) {
        final address = order.deliveryAddress?.trim() ?? '';
        if (order.deliveryMethod == 'courier' && address.isNotEmpty) {
          await prefs.setString(_deliveryAddressPrefsKey(prefs), address);
          return address;
        }
      }
    } catch (_) {}

    return '';
  }

  static Future<bool> hasValidSession() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return false;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (await _isSuccess(response)) {
        final data = jsonDecode(response.body);
        await storeSession(
          token: token,
          role: data['role']?.toString() ?? 'user',
          email: data['email']?.toString() ?? '',
          name: data['name']?.toString() ?? '',
        );
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<Map<String, dynamic>> login(
    String login,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'login': login, 'password': password}),
    );
    if (await _isSuccess(response)) {
      return jsonDecode(response.body);
    }
    throw ApiException(_responseMessage(response, 'Кіру сәтсіз'));
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
    if (await _isSuccess(response)) {
      return jsonDecode(response.body);
    }
    throw ApiException(_responseMessage(response, 'Тіркелу сәтсіз'));
  }

  static Future<void> requestPasswordReset(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (!await _isSuccess(response)) {
      throw ApiException(_responseMessage(response, 'Reset code send failed'));
    }
  }

  static Future<String> verifyResetCode(String email, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-reset-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
    if (await _isSuccess(response)) {
      final data = jsonDecode(response.body);
      return data['resetToken'] ?? '';
    }
    throw ApiException(_responseMessage(response, 'Code verification failed'));
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
    if (!await _isSuccess(response)) {
      throw ApiException(_responseMessage(response, 'Password reset failed'));
    }
  }

  static Future<List<Category>> fetchCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));
    if (await _isSuccess(response)) {
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
    final uri = Uri.parse('$baseUrl/products').replace(
      queryParameters: {
        if (categoryId != null) 'categoryId': categoryId,
        if (popularOnly) 'popular': 'true',
        if (occasion != null) 'occasion': occasion,
        if (recipient != null) 'recipient': recipient,
      },
    );
    final response = await http.get(uri);
    if (await _isSuccess(response)) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Product.fromJson(item)).toList();
    }
    throw Exception('Өнімдерді жүктеу сәтсіз');
  }

  static Future<List<Product>> fetchRecommendations({int limit = 8}) async {
    final token = await _requireToken();
    final uri = Uri.parse(
      '$baseUrl/recommendations',
    ).replace(queryParameters: {'limit': limit.toString()});
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (await _isSuccess(response)) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Product.fromJson(item)).toList();
    }
    throw Exception('Ұсыныстарды жүктеу сәтсіз');
  }

  static Future<List<CustomBouquetItem>> fetchCustomBouquetItems() async {
    final response = await http.get(Uri.parse('$baseUrl/custom-items'));
    if (await _isSuccess(response)) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => CustomBouquetItem.fromJson(item)).toList();
    }
    throw Exception('Жеке букет бөліктерін жүктеу сәтсіз');
  }

  static Future<CustomBouquetItem> createCustomBouquetItem(
    CustomBouquetItem item,
  ) async {
    final token = await _requireToken();
    final response = await http.post(
      Uri.parse('$baseUrl/custom-items'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(item.toJson()),
    );
    if (await _isSuccess(response)) {
      return CustomBouquetItem.fromJson(jsonDecode(response.body));
    }
    throw Exception('Жеке букет бөлігін құру сәтсіз');
  }

  static Future<CustomBouquetItem> updateCustomBouquetItem(
    CustomBouquetItem item,
  ) async {
    final token = await _requireToken();
    final response = await http.put(
      Uri.parse('$baseUrl/custom-items/${item.id}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(item.toJson()),
    );
    if (await _isSuccess(response)) {
      return CustomBouquetItem.fromJson(jsonDecode(response.body));
    }
    throw Exception('Жеке букет бөлігін жаңарту сәтсіз');
  }

  static Future<void> deleteCustomBouquetItem(String id) async {
    final token = await _requireToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/custom-items/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (!await _isSuccess(response)) {
      throw Exception('Жеке букет бөлігін өшіру сәтсіз');
    }
  }

  static Future<List<Product>> searchProductsByPhoto(
    Uint8List imageBytes,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/vision/search'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'imageBase64': base64Encode(imageBytes)}),
    );
    if (await _isSuccess(response)) {
      final data = jsonDecode(response.body);
      final products = data is List ? data : data['products'];
      if (products is List) {
        return products.map((item) => Product.fromJson(item)).toList();
      }
      return [];
    }
    String? errorMessage;
    try {
      final data = jsonDecode(response.body);
      errorMessage = data['message']?.toString();
    } catch (_) {}
    if (errorMessage != null && errorMessage.isNotEmpty) {
      throw Exception(errorMessage);
    }
    throw Exception('Photo search failed');
  }

  static Future<List<dynamic>> fetchOrders() async {
    final token = await _requireToken();
    final response = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (await _isSuccess(response)) {
      return jsonDecode(response.body);
    }
    throw Exception('Тапсырыстарды жүктеу сәтсіз');
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    final token = await _requireToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': status}),
    );
    if (!await _isSuccess(response)) {
      throw Exception('Тапсырыс мәртебесін жаңарту сәтсіз');
    }
  }

  static Future<List<dynamic>> fetchAdmins() async {
    final token = await _requireToken();
    final response = await http.get(
      Uri.parse('$baseUrl/admins'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (await _isSuccess(response)) {
      return jsonDecode(response.body);
    }
    throw Exception('Әкімшілерді жүктеу сәтсіз');
  }

  static Future<void> addAdmin(String email, {String role = 'admin'}) async {
    final token = await _requireToken();
    final response = await http.post(
      Uri.parse('$baseUrl/admins'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email, 'role': role}),
    );
    if (!await _isSuccess(response)) {
      throw Exception('Әкімші қосу сәтсіз');
    }
  }

  static Future<void> removeAdmin(String email) async {
    final token = await _requireToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/admins/$email'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (!await _isSuccess(response)) {
      throw Exception('Әкімшіні жою сәтсіз');
    }
  }

  static Future<Product> createProduct(Product product) async {
    final token = await _requireToken();
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': product.name,
        'price': product.price,
        'imagePath': product.imagePath,
        'imageUrl': product.imageUrl,
        'flowerType': product.flowerType,
        'categoryId': product.categoryId,
        'inStock': product.inStock,
        'stockCount': product.stockCount,
        'popular': product.popular,
      }),
    );
    if (await _isSuccess(response)) {
      return Product.fromJson(jsonDecode(response.body));
    }
    throw Exception('Өнім құру сәтсіз');
  }

  static Future<Product> updateProduct(Product product) async {
    final token = await _requireToken();
    final response = await http.put(
      Uri.parse('$baseUrl/products/${product.id}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': product.name,
        'price': product.price,
        'imagePath': product.imagePath,
        'imageUrl': product.imageUrl,
        'flowerType': product.flowerType,
        'categoryId': product.categoryId,
        'inStock': product.inStock,
        'stockCount': product.stockCount,
        'popular': product.popular,
      }),
    );
    if (await _isSuccess(response)) {
      return Product.fromJson(jsonDecode(response.body));
    }
    throw Exception('Өнімді жаңарту сәтсіз');
  }

  static Future<void> updateStock(
    String productId,
    bool inStock,
    int stockCount,
  ) async {
    final token = await _requireToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/products/$productId/stock'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'inStock': inStock, 'stockCount': stockCount}),
    );
    if (!await _isSuccess(response)) {
      throw Exception('Қойма жаңарту сәтсіз');
    }
  }

  static Future<void> updatePopular(String productId, bool popular) async {
    final token = await _requireToken();
    final response = await http.put(
      Uri.parse('$baseUrl/products/$productId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'popular': popular}),
    );
    if (!await _isSuccess(response)) {
      throw Exception('Сұраныстағы күйін жаңарту сәтсіз');
    }
  }

  static Future<void> deleteProduct(String productId) async {
    final token = await _requireToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/products/$productId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (!await _isSuccess(response)) {
      throw Exception('Өнімді жою сәтсіз');
    }
  }

  static Future<List<dynamic>> fetchChatSessions() async {
    final token = await _requireToken();
    final response = await http.get(
      Uri.parse('$baseUrl/ai/chats'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (await _isSuccess(response)) {
      return jsonDecode(response.body);
    }
    throw Exception('Чат тарихын жүктеу сәтсіз');
  }

  static Future<Map<String, dynamic>> createChatSession({String? title}) async {
    final token = await _requireToken();
    final response = await http.post(
      Uri.parse('$baseUrl/ai/chats'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'title': title}),
    );
    if (await _isSuccess(response)) {
      return jsonDecode(response.body);
    }
    throw Exception('Жаңа чат құру сәтсіз');
  }

  static Future<void> deleteChatSession(String sessionId) async {
    final token = await _requireToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/ai/chats/$sessionId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (!await _isSuccess(response)) {
      throw Exception('Чатты өшіру сәтсіз');
    }
  }

  static Future<Map<String, dynamic>> fetchChatMessages(
    String sessionId,
  ) async {
    final token = await _requireToken();
    final response = await http.get(
      Uri.parse('$baseUrl/ai/chats/$sessionId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (await _isSuccess(response)) {
      return jsonDecode(response.body);
    }
    throw Exception('Чат хабарламаларын жүктеу сәтсіз');
  }

  static Future<Map<String, dynamic>> sendChatMessage(
    String message, {
    String? sessionId,
  }) async {
    final token = await _requireToken();
    final response = await http.post(
      Uri.parse('$baseUrl/ai/chat'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'message': message, 'sessionId': sessionId}),
    );
    if (await _isSuccess(response)) {
      return jsonDecode(response.body);
    }
    throw Exception('AI хабарламасын жіберу сәтсіз');
  }

  static Future<List<dynamic>> fetchPaymentMethods() async {
    final token = await _requireToken();
    final response = await http.get(
      Uri.parse('$baseUrl/payment-methods'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (await _isSuccess(response)) {
      return jsonDecode(response.body);
    }
    throw Exception('Төлем әдістерін жүктеу сәтсіз');
  }

  static Future<Map<String, dynamic>> fetchPaymentMethod(String id) async {
    final token = await _requireToken();
    final response = await http.get(
      Uri.parse('$baseUrl/payment-methods/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (await _isSuccess(response)) {
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
    final token = await _requireToken();
    final normalizedExpMonth = _normalizeExpiryMonth(expMonth);
    final normalizedExpYear = _normalizeExpiryYear(expYear);
    final response = await http.post(
      Uri.parse('$baseUrl/payment-methods'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'cardholderName': cardholderName,
        'cardNumber': cardNumber,
        'expMonth': normalizedExpMonth,
        'expYear': normalizedExpYear,
        'cvv': cvv,
      }),
    );
    if (!await _isSuccess(response)) {
      throw Exception('Төлем әдісін құру сәтсіз');
    }
  }

  static Future<void> updatePaymentMethod({
    required String id,
    required String cardholderName,
    required String expMonth,
    required String expYear,
    String? cardNumber,
    String? cvv,
  }) async {
    final token = await _requireToken();
    final normalizedExpMonth = _normalizeExpiryMonth(expMonth);
    final normalizedExpYear = _normalizeExpiryYear(expYear);
    final payload = {
      'cardholderName': cardholderName,
      'expMonth': normalizedExpMonth,
      'expYear': normalizedExpYear,
    };
    if (cardNumber != null && cardNumber.isNotEmpty) {
      payload['cardNumber'] = cardNumber;
    }
    if (cvv != null && cvv.isNotEmpty) {
      payload['cvv'] = cvv;
    }
    final response = await http.put(
      Uri.parse('$baseUrl/payment-methods/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );
    if (!await _isSuccess(response)) {
      throw Exception('Төлем әдісін жаңарту сәтсіз');
    }
  }

  static Future<void> deletePaymentMethod(String id) async {
    final token = await _requireToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/payment-methods/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (!await _isSuccess(response)) {
      throw Exception('Төлем әдісін жою сәтсіз');
    }
  }

  static Future<List<Product>> fetchFavorites() async {
    final token = await _requireToken();
    final response = await http.get(
      Uri.parse('$baseUrl/favorites'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (await _isSuccess(response)) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Product.fromJson(item)).toList();
    }
    throw Exception('Таңдаулыларды жүктеу сәтсіз');
  }

  static Future<void> addFavorite(String productId) async {
    final token = await _requireToken();
    final response = await http.post(
      Uri.parse('$baseUrl/favorites'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'productId': productId}),
    );
    if (!await _isSuccess(response)) {
      throw Exception('Таңдаулыға қосу сәтсіз');
    }
  }

  static Future<void> removeFavorite(String productId) async {
    final token = await _requireToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/favorites/$productId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (!await _isSuccess(response)) {
      throw Exception('Таңдаулыдан жою сәтсіз');
    }
  }

  static Future<List<CartItem>> fetchCartItems() async {
    final token = await _requireToken();
    final response = await http.get(
      Uri.parse('$baseUrl/cart'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (await _isSuccess(response)) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => CartItem.fromJson(item)).toList();
    }
    throw Exception('Себетті жүктеу сәтсіз');
  }

  static Future<void> addToCart(String productId, {int quantity = 1}) async {
    final token = await _requireToken();
    final response = await http.post(
      Uri.parse('$baseUrl/cart'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'productId': productId, 'quantity': quantity}),
    );
    if (!await _isSuccess(response)) {
      throw Exception('Себетке қосу сәтсіз');
    }
  }

  static Future<void> addCustomBouquetToCart({
    required List<Map<String, dynamic>> items,
    required String description,
    int quantity = 1,
    String? cartItemId,
  }) async {
    final token = await _requireToken();
    final response = await http.post(
      Uri.parse('$baseUrl/cart/custom'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'items': items,
        'description': description,
        'quantity': quantity,
        if (cartItemId != null && cartItemId.isNotEmpty)
          'cartItemId': cartItemId,
      }),
    );
    if (!await _isSuccess(response)) {
      throw Exception('Could not add custom bouquet to cart');
    }
  }

  static Future<void> updateCartItem(
    String itemId, {
    required int quantity,
    String itemType = 'product',
  }) async {
    final token = await _requireToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/cart/$itemId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'quantity': quantity, 'itemType': itemType}),
    );
    if (!await _isSuccess(response)) {
      throw Exception('Себетті жаңарту сәтсіз');
    }
  }

  static Future<void> removeFromCart(
    String itemId, {
    String itemType = 'product',
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse(
      '$baseUrl/cart/$itemId',
    ).replace(queryParameters: {'itemType': itemType});
    final response = await http.delete(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (!await _isSuccess(response)) {
      throw Exception('Себеттен жою сәтсіз');
    }
  }

  static Future<void> clearCart() async {
    final token = await _requireToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/cart'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (!await _isSuccess(response)) {
      throw Exception('Себетті тазалау сәтсіз');
    }
  }

  static Future<OrderModel> createOrder(
    List<CartItem> items, {
    required String deliveryMethod,
    required int deliveryPrice,
    Map<String, dynamic>? pickupStore,
    String? deliveryAddress,
    required String paymentMethodId,
  }) async {
    final token = await _requireToken();
    final payload = items
        .map(
          (item) => item.isCustom
              ? {'cartItemId': item.id, 'quantity': item.quantity}
              : {'productId': item.product.id, 'quantity': item.quantity},
        )
        .toList();
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'items': payload,
        'deliveryMethod': deliveryMethod,
        'deliveryPrice': deliveryPrice,
        'pickupStore': pickupStore,
        'deliveryAddress': deliveryAddress,
        'paymentMethodId': paymentMethodId,
      }),
    );
    if (await _isSuccess(response)) {
      return OrderModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Тапсырыс жасау сәтсіз');
  }

  static Future<OrderModel> createCustomBouquetOrder({
    required List<Map<String, dynamic>> items,
    required String description,
  }) async {
    final token = await _requireToken();
    final response = await http.post(
      Uri.parse('$baseUrl/orders/custom'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'items': items, 'description': description}),
    );
    if (await _isSuccess(response)) {
      return OrderModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Жеке букет тапсырысын жасау сәтсіз');
  }

  static Future<List<OrderModel>> fetchMyOrders() async {
    final token = await _requireToken();
    final response = await http.get(
      Uri.parse('$baseUrl/orders/my'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (await _isSuccess(response)) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => OrderModel.fromJson(item)).toList();
    }
    throw Exception('Менің тапсырыстарымды жүктеу сәтсіз');
  }

  static Future<List<NotificationItem>> fetchNotifications() async {
    final token = await _requireToken();
    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (await _isSuccess(response)) {
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
    final token = await _requireToken();
    final response = await http.post(
      Uri.parse('$baseUrl/notifications'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'title': title, 'message': message, 'type': type}),
    );
    if (!await _isSuccess(response)) {
      throw Exception('Хабарлама құру сәтсіз');
    }
  }

  static Future<void> markNotificationRead(String id) async {
    final token = await _requireToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/notifications/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (!await _isSuccess(response)) {
      throw Exception('Хабарламаны оқылғанға белгілеу сәтсіз');
    }
  }
}
