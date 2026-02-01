import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_products_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_emails_screen.dart';
import 'login_screen.dart';
import 'order_model.dart';
import 'product.dart';
import 'services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _email = '';
  String _role = 'user';
  bool _loading = true;
  bool _paymentLoading = false;
  List<dynamic> _paymentMethods = [];
  bool _ordersLoading = false;
  List<OrderModel> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('auth_name') ?? '';
      _email = prefs.getString('auth_email') ?? '';
      _role = prefs.getString('auth_role') ?? 'user';
      _loading = false;
    });
    await _loadPaymentMethods();
    await _loadOrders();
  }

  Future<void> _logout() async {
    await ApiService.clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _paymentLoading = true;
    });
    try {
      final methods = await ApiService.fetchPaymentMethods();
      if (!mounted) return;
      setState(() {
        _paymentMethods = methods;
      });
    } catch (error) {
      if (!mounted) return;
      _showSnack('Төлем әдістерін жүктеу сәтсіз');
    } finally {
      if (!mounted) return;
      setState(() {
        _paymentLoading = false;
      });
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _ordersLoading = true);
    try {
      final data = await ApiService.fetchMyOrders();
      if (!mounted) return;
      setState(() {
        _orders = data;
      });
    } catch (_) {
      if (!mounted) return;
      _showSnack('Тапсырыстарды жүктеу сәтсіз');
    } finally {
      if (!mounted) return;
      setState(() => _ordersLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPaymentForm({String? methodId}) async {
    final isEdit = methodId != null;
    Map<String, dynamic>? existing;
    if (isEdit) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFE60064))),
      );
      try {
        existing = await ApiService.fetchPaymentMethod(methodId!);
      } catch (error) {
        if (mounted) _showSnack('Төлем әдісін жүктеу сәтсіз');
      } finally {
        if (mounted) Navigator.of(context).pop();
      }
      if (existing == null) return;
    }

    final nameController = TextEditingController(text: existing?['cardholderName'] ?? '');
    final numberController = TextEditingController(text: existing?['cardNumber'] ?? '');
    final expMonthController = TextEditingController(text: existing?['expMonth'] ?? '');
    final expYearController = TextEditingController(text: existing?['expYear'] ?? '');
    final cvvController = TextEditingController(text: existing?['cvv'] ?? '');

    final darkPink = const Color(0xFFE60064);
    final lightPink = const Color(0xFFFFE6EB);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final viewInsets = MediaQuery.of(context).viewInsets;
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? 'Картаны жаңарту' : 'Картаны қосу',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildTextField('Карта иесінің аты', nameController),
              const SizedBox(height: 12),
              _buildTextField('Карта нөмірі', numberController, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('Аяқталу айы', expMonthController, keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField('Аяқталу жылы', expYearController, keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField('CVV', cvvController, keyboardType: TextInputType.number, obscure: true),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkPink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final number = numberController.text.trim();
                    final expMonth = expMonthController.text.trim();
                    final expYear = expYearController.text.trim();
                    final cvv = cvvController.text.trim();
                    if (name.isEmpty || number.isEmpty || expMonth.isEmpty || expYear.isEmpty || cvv.isEmpty) {
                      _showSnack('Барлық өрістерді толтырыңыз');
                      return;
                    }
                    try {
                      if (isEdit) {
                        await ApiService.updatePaymentMethod(
                          id: methodId!,
                          cardholderName: name,
                          cardNumber: number,
                          expMonth: expMonth,
                          expYear: expYear,
                          cvv: cvv,
                        );
                      } else {
                        await ApiService.createPaymentMethod(
                          cardholderName: name,
                          cardNumber: number,
                          expMonth: expMonth,
                          expYear: expYear,
                          cvv: cvv,
                        );
                      }
                      if (!mounted) return;
                      Navigator.of(context).pop();
                      await _loadPaymentMethods();
                    } catch (error) {
                      if (!mounted) return;
                      _showSnack('Төлем әдісін сақтау сәтсіз');
                    }
                  },
                  child: Text(isEdit ? 'Жаңарту' : 'Сақтау',
                      style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: lightPink),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Бас тарту', style: TextStyle(color: Colors.black87)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, bool obscure = false}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFFFF6F8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildPaymentMethodsSection(Color darkPink, Color lightPink) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Төлем әдістері', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (_paymentLoading)
          const Center(child: CircularProgressIndicator(color: Color(0xFFE60064)))
        else if (_paymentMethods.isEmpty)
          const Text('Сақталған карталар жоқ', style: TextStyle(color: Colors.black54))
        else
          ..._paymentMethods.map((method) {
            final last4 = method['last4'] ?? '';
            final maskedNumber = last4.isEmpty ? '****' : '**** **** **** $last4';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: lightPink),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _openPaymentForm(methodId: method['id']),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(maskedNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          const Text('Аты: *****  Мерзімі: **/**  CVV: ***',
                              style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFFE60064)),
                    onPressed: () => _openPaymentForm(methodId: method['id']),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.black54),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Картаны өшіру'),
                          content: const Text('Осы төлем әдісін өшіресіз бе?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Бас тарту')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Өшіру')),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      try {
                        await ApiService.deletePaymentMethod(method['id']);
                        await _loadPaymentMethods();
                      } catch (error) {
                        _showSnack('Төлем әдісін өшіру сәтсіз');
                      }
                    },
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: darkPink,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _openPaymentForm(),
            child: const Text('Төлем әдісін қосу', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  String _orderStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Тапсырыс жасалды';
      case 'processing':
        return 'Тапсырыс өңделуде';
      case 'completed':
        return 'Тапсырыс расталды';
      case 'cancelled':
        return 'Тапсырыс бас тартылды';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  Widget _buildOrdersSection(Color darkPink, Color lightPink) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Тапсырыс тарихы', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (_ordersLoading)
          const Center(child: CircularProgressIndicator(color: Color(0xFFE60064)))
        else if (_orders.isEmpty)
          const Text('Тапсырыстар жоқ', style: TextStyle(color: Colors.black54))
        else
          ..._orders.map((order) {
            final count = order.items.fold<int>(0, (sum, item) => sum + item.quantity);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: lightPink),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Тапсырыс жасалды', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Күні: ${_formatDate(order.createdAt)}'),
                  const SizedBox(height: 6),
                  Text('Саны: $count  |  Жалпы: ${Product.formatPrice(order.total)}'),
                  const SizedBox(height: 6),
                  Text('Күйі: ${_orderStatusLabel(order.status)}',
                      style: TextStyle(color: darkPink, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color darkPink = const Color(0xFFE60064);
    final Color lightPink = const Color(0xFFFFE6EB);

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE60064)));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Жеке кабинет', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lightPink,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Color(0xFFE60064), size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_name.isEmpty ? 'Қонақ' : _name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_email.isEmpty ? 'Эл. пошта жоқ' : _email,
                            style: const TextStyle(color: Colors.black54)),
                        if (_role != 'user') ...[
                          const SizedBox(height: 4),
                          Text('Рөл: $_role', style: TextStyle(color: darkPink)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildPaymentMethodsSection(darkPink, lightPink),
            const SizedBox(height: 20),
            _buildOrdersSection(darkPink, lightPink),
            const SizedBox(height: 20),
            if (_role == 'admin' || _role == 'super_admin') ...[
              const Text('Әкімші бөлімі', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildActionButton(
                context,
                label: 'Өнімдерді басқару',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminProductsScreen()),
                ),
              ),
              const SizedBox(height: 10),
              _buildActionButton(
                context,
                label: 'Тапсырыстарды басқару',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminOrdersScreen()),
                ),
              ),
              if (_role == 'super_admin') ...[
                const SizedBox(height: 10),
                _buildActionButton(
                  context,
                  label: 'Әкімші эл. пошталары',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminEmailsScreen()),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkPink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _logout,
                child: const Text('Шығу', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFE6EB)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Icon(Icons.chevron_right, color: Color(0xFFE60064)),
          ],
        ),
      ),
    );
  }
}
