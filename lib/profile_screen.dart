import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_language.dart';
import 'admin_products_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_emails_screen.dart';
import 'admin_custom_items_screen.dart';
import 'login_screen.dart';
import 'order_model.dart';
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
    if (!mounted) return;
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
      _showSnack(context.t.loadPaymentMethodsFailed);
    } finally {
      if (mounted) {
        setState(() {
          _paymentLoading = false;
        });
      }
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
      _showSnack(context.t.loadOrdersFailed);
    } finally {
      if (mounted) {
        setState(() => _ordersLoading = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPaymentForm({String? methodId}) async {
    final t = context.t;
    final isEdit = methodId != null;
    Map<String, dynamic>? existing;
    if (isEdit) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFE60064)),
        ),
      );
      try {
        existing = await ApiService.fetchPaymentMethod(methodId);
      } catch (error) {
        if (mounted) _showSnack(t.loadPaymentMethodFailed);
      } finally {
        if (mounted) Navigator.of(context).pop();
      }
      if (existing == null) return;
      if (!mounted) return;
    }

    final nameController = TextEditingController(
      text: existing?['cardholderName'] ?? '',
    );
    final numberController = TextEditingController(
      text: existing?['maskedCardNumber'] ?? '',
    );
    final expMonthController = TextEditingController(
      text: existing?['expMonth'] ?? '',
    );
    final expYearController = TextEditingController(
      text: existing?['expYear'] ?? '',
    );
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
      builder: (sheetContext) {
        final viewInsets = MediaQuery.of(sheetContext).viewInsets;
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
              Text(
                isEdit ? t.updateCard : t.addCard,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(t.cardholderName, nameController),
              const SizedBox(height: 12),
              if (isEdit)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    numberController.text.isEmpty
                        ? '****'
                        : numberController.text,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                )
              else
                _buildTextField(
                  t.cardNumber,
                  numberController,
                  keyboardType: TextInputType.number,
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      t.expMonth,
                      expMonthController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      t.expYear,
                      expYearController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              if (!isEdit) ...[
                const SizedBox(height: 12),
                _buildTextField(
                  'CVV',
                  cvvController,
                  keyboardType: TextInputType.number,
                  obscure: true,
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkPink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final number = numberController.text.trim();
                    final expMonth = expMonthController.text.trim();
                    final expYear = expYearController.text.trim();
                    final cvv = cvvController.text.trim();
                    if (name.isEmpty ||
                        expMonth.isEmpty ||
                        expYear.isEmpty ||
                        (!isEdit && (number.isEmpty || cvv.isEmpty))) {
                      _showSnack(t.fillAllFields);
                      return;
                    }
                    try {
                      if (isEdit) {
                        await ApiService.updatePaymentMethod(
                          id: methodId,
                          cardholderName: name,
                          expMonth: expMonth,
                          expYear: expYear,
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
                      if (!sheetContext.mounted) return;
                      Navigator.of(sheetContext).pop();
                      await _loadPaymentMethods();
                    } catch (error) {
                      if (!mounted) return;
                      _showSnack(t.savePaymentMethodFailed);
                    }
                  },
                  child: Text(
                    isEdit ? t.update : t.save,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
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
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(
                    t.cancel,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFFFF6F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsSection(Color darkPink, Color lightPink) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.paymentMethods,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (_paymentLoading)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFFE60064)),
          )
        else if (_paymentMethods.isEmpty)
          Text(t.savedCardsEmpty, style: const TextStyle(color: Colors.black54))
        else
          ..._paymentMethods.map((method) {
            final last4 = method['last4'] ?? '';
            final maskedNumber = last4.isEmpty
                ? '****'
                : '**** **** **** $last4';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: lightPink),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
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
                          Text(
                            maskedNumber,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t.cardMaskedDetails,
                            style: const TextStyle(color: Colors.black54),
                          ),
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
                          title: Text(t.deleteCardTitle),
                          content: Text(t.deleteCardQuestion),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(t.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(t.delete),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      try {
                        await ApiService.deletePaymentMethod(method['id']);
                        await _loadPaymentMethods();
                      } catch (error) {
                        _showSnack(t.deletePaymentMethodFailed);
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _openPaymentForm(),
            child: Text(
              t.addPaymentMethod,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  String _orderStatusLabel(String status) {
    return context.t.orderStatusLabel(status);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  Widget _buildOrdersSection(Color darkPink, Color lightPink) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.orderHistory,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (_ordersLoading)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFFE60064)),
          )
        else if (_orders.isEmpty)
          Text(t.ordersEmpty, style: const TextStyle(color: Colors.black54))
        else
          ..._orders.map((order) {
            final count = order.items.fold<int>(
              0,
              (sum, item) => sum + item.quantity,
            );
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: lightPink),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderType == 'custom'
                        ? t.customOrderLabel
                        : t.orderMade,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(t.dateWith(_formatDate(order.createdAt))),
                  const SizedBox(height: 6),
                  Text(t.quantityTotalWith(count, t.priceValue(order.total))),
                  if (order.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(t.descriptionWith(order.description)),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    order.deliveryMethod == 'courier'
                        ? 'Delivery method: Courier delivery'
                        : 'Delivery method: Pickup from store',
                  ),
                  if (order.deliveryMethod == 'pickup' &&
                      order.pickupStore != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                            order.pickupStore?['name']?.toString(),
                            order.pickupStore?['address']?.toString(),
                          ]
                          .whereType<String>()
                          .where((value) => value.isNotEmpty)
                          .join(' - '),
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                  if (order.deliveryMethod == 'courier' &&
                      (order.deliveryAddress ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Delivery address: ${order.deliveryAddress}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    t.statusWith(_orderStatusLabel(order.status)),
                    style: TextStyle(
                      color: darkPink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildLanguageSection(Color darkPink, Color lightPink) {
    final t = context.t;
    final languageController = AppLanguageScope.watch(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.settings,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: lightPink),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.language, color: darkPink),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.language,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Wrap(
                spacing: 6,
                children: AppLocale.values.map((locale) {
                  final selected = languageController.locale == locale;
                  return ChoiceChip(
                    label: Text(locale.shortLabel),
                    selected: selected,
                    onSelected: (_) {
                      languageController.setLocale(locale);
                    },
                    selectedColor: lightPink,
                    labelStyle: TextStyle(
                      color: selected ? darkPink : Colors.black54,
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(color: selected ? darkPink : lightPink),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final Color darkPink = const Color(0xFFE60064);
    final Color lightPink = const Color(0xFFFFE6EB);
    final isStaff =
        _role == 'worker' || _role == 'admin' || _role == 'super_admin';
    final canManageProducts = _role == 'admin' || _role == 'super_admin';

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE60064)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(t.profile, style: const TextStyle(color: Colors.black)),
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
                    child: Icon(
                      Icons.person,
                      color: Color(0xFFE60064),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name.isEmpty ? t.guest : _name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _email.isEmpty ? t.noEmail : _email,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        if (_role != 'user') ...[
                          const SizedBox(height: 4),
                          Text(
                            t.roleValue(_role),
                            style: TextStyle(color: darkPink),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildLanguageSection(darkPink, lightPink),
            const SizedBox(height: 20),
            _buildPaymentMethodsSection(darkPink, lightPink),
            const SizedBox(height: 20),
            _buildOrdersSection(darkPink, lightPink),
            const SizedBox(height: 20),
            if (isStaff) ...[
              Text(
                t.adminSection,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              if (canManageProducts) ...[
                _buildActionButton(
                  context,
                  label: t.manageProducts,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminProductsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              _buildActionButton(
                context,
                label: t.manageCustomItems,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminCustomItemsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildActionButton(
                context,
                label: t.manageOrders,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminOrdersScreen(),
                  ),
                ),
              ),
              if (_role == 'super_admin') ...[
                const SizedBox(height: 10),
                _buildActionButton(
                  context,
                  label: t.adminEmails,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminEmailsScreen(),
                    ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _logout,
                child: Text(
                  t.logout,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
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
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
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
