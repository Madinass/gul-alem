import 'package:flutter/material.dart';
import 'services/api_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final Color darkPink = const Color(0xFFE60064);
  bool _loading = true;
  List<dynamic> orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final data = await ApiService.fetchOrders();
      if (!mounted) return;
      setState(() {
        orders = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await ApiService.updateOrderStatus(id, status);
      await _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Тапсырыстар', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE60064)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final items = (order['items'] as List<dynamic>? ?? []);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order #${order['_id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Total: ${order['total']} тг'),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: items
                              .map((item) => Chip(
                                    label: Text('${item['name']} x${item['quantity']}'),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Status: ${order['status']}'),
                            DropdownButton<String>(
                              value: order['status'],
                              items: const [
                                DropdownMenuItem(value: 'pending', child: Text('pending')),
                                DropdownMenuItem(value: 'processing', child: Text('processing')),
                                DropdownMenuItem(value: 'completed', child: Text('completed')),
                                DropdownMenuItem(value: 'cancelled', child: Text('cancelled')),
                              ],
                              onChanged: (value) {
                                if (value != null) _updateStatus(order['_id'], value);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
