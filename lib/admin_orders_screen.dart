import 'package:flutter/material.dart';

import 'app_language.dart';
import 'order_model.dart';
import 'services/api_service.dart';
import 'widgets/order_items_gallery.dart';
import 'widgets/top_toast.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final Color darkPink = const Color(0xFFE60064);
  bool _loading = true;
  List<dynamic> orders = [];
  static const List<String> _allowedStatuses = [
    'pending',
    'processing',
    'completed',
    'cancelled',
  ];

  String _safeStatus(dynamic value) {
    final status = value?.toString() ?? 'pending';
    return _allowedStatuses.contains(status) ? status : 'pending';
  }

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
      showTopToast(
        context,
        context.t.errorWith(e),
        backgroundColor: Colors.redAccent,
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
          ? Center(child: CircularProgressIndicator(color: darkPink))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final orderJson = orders[index] is Map
                    ? Map<String, dynamic>.from(orders[index] as Map)
                    : <String, dynamic>{};
                final order = OrderModel.fromJson(orderJson);
                final status = _safeStatus(order.status);
                final pickupStore = orderJson['pickupStore'] is Map
                    ? orderJson['pickupStore'] as Map
                    : null;
                final user = orderJson['user'] is Map<String, dynamic>
                    ? orderJson['user'] as Map<String, dynamic>
                    : null;
                final customDetailItems = OrderCustomDetails.itemsFromOrder(
                  order,
                );

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
                          t.orderNumber(order.id),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Chip(
                          label: Text(
                            order.orderType == 'custom'
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
                                .join(' - '),
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                        if (order.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(t.descriptionWith(order.description)),
                        ],
                        if (order.cardMessage.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(t.cardMessageWith(order.cardMessage)),
                        ],
                        if (customDetailItems.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          OrderCustomDetails(items: customDetailItems),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          order.deliveryMethod == 'courier'
                              ? t.deliveryMethodWith(t.courierDelivery)
                              : t.deliveryMethodWith(t.pickupFromStore),
                        ),
                        if (order.deliveryMethod == 'pickup' &&
                            pickupStore != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            [
                                  t.pickupStoreName(
                                    pickupStore['id'],
                                    pickupStore['name'],
                                  ),
                                  t.pickupStoreAddress(
                                    pickupStore['id'],
                                    pickupStore['address'],
                                  ),
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
                            t.deliveryAddressWith(order.deliveryAddress ?? ''),
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          t.deliveryFeeWith(t.priceValue(order.deliveryPrice)),
                        ),
                        const SizedBox(height: 6),
                        Text(t.totalWith(t.priceValue(order.total))),
                        if (order.items.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: order.items.map((item) {
                              return Chip(
                                label: Text(
                                  '${t.itemQuantity(item.name, item.quantity)} - ${t.priceValue(item.price)}',
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(t.statusWith(_statusLabel(status))),
                            DropdownButton<String>(
                              value: status,
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
                                  _updateStatus(order.id, value);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        OrderItemsGallery.fromOrder(order),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
