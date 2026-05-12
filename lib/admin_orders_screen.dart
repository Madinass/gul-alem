import 'package:flutter/material.dart';
import 'app_language.dart';
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

  String _statusLabel(String status) {
    return context.t.statusLabel(status);
  }

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
        SnackBar(
          content: Text(context.t.errorWith(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(t.orders, style: const TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE60064)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final items = (order['items'] as List<dynamic>? ?? []);
                final total = (order['total'] ?? 0) is int
                    ? order['total']
                    : (order['total'] as num).toInt();
                final orderType = order['orderType']?.toString() ?? 'standard';
                final description = order['description']?.toString() ?? '';
                final user = order['user'] is Map<String, dynamic>
                    ? order['user'] as Map<String, dynamic>
                    : null;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.orderNumber(order['_id']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Chip(
                          label: Text(
                            orderType == 'custom'
                                ? t.customOrderLabel
                                : t.standardOrderLabel,
                          ),
                          backgroundColor: const Color(0xFFFFE6EB),
                        ),
                        if (user != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            [
                                  user['name']?.toString(),
                                  user['email']?.toString(),
                                ]
                                .whereType<String>()
                                .where((v) => v.isNotEmpty)
                                .join(' • '),
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(t.descriptionWith(description)),
                        ],
                        const SizedBox(height: 6),
                        Text(t.totalWith(t.priceValue(total))),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: items.map((item) {
                            final price = (item['price'] ?? 0) is int
                                ? item['price']
                                : (item['price'] as num).toInt();
                            return Chip(
                              label: Text(
                                '${t.itemQuantity(item['name'], item['quantity'])} • ${t.priceValue(price)}',
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(t.statusWith(_statusLabel(order['status']))),
                            DropdownButton<String>(
                              value: order['status'],
                              items: [
                                DropdownMenuItem(
                                  value: 'pending',
                                  child: Text(t.pending),
                                ),
                                DropdownMenuItem(
                                  value: 'processing',
                                  child: Text(t.processing),
                                ),
                                DropdownMenuItem(
                                  value: 'completed',
                                  child: Text(t.completed),
                                ),
                                DropdownMenuItem(
                                  value: 'cancelled',
                                  child: Text(t.cancelled),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  _updateStatus(order['_id'], value);
                                }
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
