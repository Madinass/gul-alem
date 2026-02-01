import 'package:flutter/material.dart';
import 'cart_item.dart';
import 'product.dart';
import 'services/api_service.dart';
import 'payment_method_form_screen.dart';

class CartPaymentScreen extends StatefulWidget {
  final List<CartItem> items;
  final int total;

  const CartPaymentScreen({super.key, required this.items, required this.total});

  @override
  State<CartPaymentScreen> createState() => _CartPaymentScreenState();
}

class _CartPaymentScreenState extends State<CartPaymentScreen> {
  final Color darkPink = const Color(0xFFE60064);
  bool _loading = true;
  List<dynamic> _methods = [];
  String? _selectedId;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    try {
      final data = await ApiService.fetchPaymentMethods();
      if (!mounted) return;
      setState(() {
        _methods = data;
        if (_methods.isNotEmpty) {
          _selectedId = _methods.first['id'];
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _addMethod() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const PaymentMethodFormScreen()),
    );
    if (created == true) {
      await _loadMethods();
    }
  }

  Future<void> _confirmPayment() async {
    if (_methods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Алдымен төлем әдісін қосыңыз')),
      );
      return;
    }
    if (_selectedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Төлем әдісін таңдаңыз')),
      );
      return;
    }
    setState(() => _processing = true);
    try {
      await ApiService.createOrder(widget.items);
      await ApiService.createNotification(
        title: 'Төлем сәтті өтті',
        message: 'Тапсырыс қабылданды',
        type: 'payment',
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Сәтті'),
          content: const Text('Тапсырыс сәтті жасалды'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Жабу'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Төлем жасау сәтсіз')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Төлем әдісі', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE60064)))
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _methods.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.credit_card, size: 60, color: Colors.black54),
                              const SizedBox(height: 16),
                              const Text('Төлем әдісі жоқ', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              const Text('Төлем әдісі жоқ па?', style: TextStyle(color: Colors.black54)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: darkPink,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _addMethod,
                                child: const Text('Қосу', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          )
                        : ListView.builder(
                            itemCount: _methods.length,
                            itemBuilder: (context, index) {
                              final method = _methods[index];
                              final id = method['id'];
                              final last4 = method['last4'] ?? '';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFFE6EB)),
                                ),
                                child: Row(
                                  children: [
                                    Radio<String>(
                                      value: id,
                                      groupValue: _selectedId,
                                      onChanged: (value) => setState(() => _selectedId = value),
                                      activeColor: darkPink,
                                    ),
                                    const Icon(Icons.credit_card, color: Colors.black54),
                                    const SizedBox(width: 12),
                                    Text('**** **** **** $last4'),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6F8),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Жалпы сома', style: TextStyle(color: Colors.black54)),
                            const SizedBox(height: 6),
                            Text(
                              Product.formatPrice(widget.total),
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkPink),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkPink,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _processing ? null : _confirmPayment,
                        child: _processing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Төлем жасау', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
