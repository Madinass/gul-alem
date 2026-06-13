import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'app_language.dart';
import 'cart_item.dart';
import 'payment_method_form_screen.dart';
import 'pickup_stores.dart';
import 'services/api_service.dart';
import 'widgets/top_toast.dart';

enum DeliveryMethod { pickup, courier }

class CartPaymentScreen extends StatefulWidget {
  final List<CartItem> items;
  final int total;

  const CartPaymentScreen({
    super.key,
    required this.items,
    required this.total,
  });

  @override
  State<CartPaymentScreen> createState() => _CartPaymentScreenState();
}

class _CartPaymentScreenState extends State<CartPaymentScreen> {
  static const int _courierDeliveryPrice = 1000;
  static const LatLng _astanaCenter = LatLng(51.1282, 71.4307);

  final Color darkPink = const Color(0xFFE60064);
  final TextEditingController _deliveryAddressController =
      TextEditingController();

  bool _loading = true;
  List<dynamic> _methods = [];
  String? _selectedId;
  final Set<String> _deletingMethodIds = {};
  bool _processing = false;
  DeliveryMethod _deliveryMethod = DeliveryMethod.pickup;
  PickupStore? _selectedPickupStore;
  Position? _userPosition;
  bool _locationLoading = false;
  bool _locationRequested = false;

  int get _deliveryPrice {
    return _deliveryMethod == DeliveryMethod.courier
        ? _courierDeliveryPrice
        : 0;
  }

  int get _orderTotal => widget.total + _deliveryPrice;

  @override
  void initState() {
    super.initState();
    _loadRememberedDeliveryAddress();
    _loadMethods();
    _loadUserLocation();
  }

  @override
  void dispose() {
    _deliveryAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadMethods() async {
    try {
      final data = await ApiService.fetchPaymentMethods();
      if (!mounted) return;
      final currentSelectedId = _selectedId;
      String? methodId(dynamic method) => method['id']?.toString();
      setState(() {
        _methods = data;
        final hasCurrentSelection = _methods.any(
          (method) => methodId(method) == currentSelectedId,
        );
        _selectedId = hasCurrentSelection
            ? currentSelectedId
            : (_methods.isEmpty ? null : methodId(_methods.first));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteMethod(dynamic method) async {
    final t = context.t;
    final id = method['id']?.toString();
    if (id == null || id.isEmpty) return;

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
    if (!mounted) return;

    setState(() => _deletingMethodIds.add(id));
    try {
      await ApiService.deletePaymentMethod(id);
      await _loadMethods();
    } catch (_) {
      if (!mounted) return;
      showTopToast(context, t.deletePaymentMethodFailed);
    } finally {
      if (mounted) {
        setState(() => _deletingMethodIds.remove(id));
      }
    }
  }

  Future<void> _loadRememberedDeliveryAddress() async {
    final address = await ApiService.fetchRememberedDeliveryAddress();
    if (!mounted ||
        address.isEmpty ||
        _deliveryAddressController.text.trim().isNotEmpty) {
      return;
    }
    _deliveryAddressController.text = address;
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

  Future<void> _loadUserLocation() async {
    if (_locationRequested) return;
    _locationRequested = true;
    if (mounted) setState(() => _locationLoading = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      // Location is used only to calculate distance to pickup stores.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (!mounted) return;
      setState(() => _userPosition = position);
    } catch (_) {
      // Pickup selection still works when location is unavailable.
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  Future<void> _confirmPayment() async {
    final t = context.t;

    if (_deliveryMethod == DeliveryMethod.pickup &&
        _selectedPickupStore == null) {
      showTopToast(context, t.selectPickupStore);
      return;
    }

    final deliveryAddress = _deliveryAddressController.text.trim();
    if (_deliveryMethod == DeliveryMethod.courier && deliveryAddress.isEmpty) {
      showTopToast(context, t.enterDeliveryAddress);
      return;
    }

    if (_methods.isEmpty) {
      showTopToast(context, t.addPaymentMethodFirst);
      return;
    }
    final selectedPaymentMethodId = _selectedId;
    if (selectedPaymentMethodId == null || selectedPaymentMethodId.isEmpty) {
      showTopToast(context, t.choosePaymentMethod);
      return;
    }

    setState(() => _processing = true);
    try {
      await ApiService.createOrder(
        widget.items,
        deliveryMethod: _deliveryMethod == DeliveryMethod.pickup
            ? 'pickup'
            : 'courier',
        deliveryPrice: _deliveryPrice,
        pickupStore: _deliveryMethod == DeliveryMethod.pickup
            ? _selectedPickupStore?.toJson()
            : null,
        deliveryAddress: _deliveryMethod == DeliveryMethod.courier
            ? deliveryAddress
            : null,
        paymentMethodId: selectedPaymentMethodId,
      );
      if (_deliveryMethod == DeliveryMethod.courier) {
        await ApiService.rememberDeliveryAddress(deliveryAddress);
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t.success),
          content: Text(t.orderCreated),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.close),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      showTopToast(context, t.paymentFailed);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _selectDeliveryMethod(DeliveryMethod method) {
    setState(() => _deliveryMethod = method);
    if (method == DeliveryMethod.pickup) {
      _loadUserLocation();
    }
  }

  double? _distanceTo(PickupStore store) {
    final position = _userPosition;
    if (position == null) return null;

    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      store.location.latitude,
      store.location.longitude,
    );
  }

  List<PickupStore> _sortedPickupStores() {
    final stores = List<PickupStore>.of(pickupStores);
    if (_userPosition == null) return stores;
    stores.sort((a, b) => _distanceTo(a)!.compareTo(_distanceTo(b)!));
    return stores;
  }

  String _distanceLabel(AppText t, PickupStore store) {
    final distance = _distanceTo(store);
    if (distance == null) return '';
    if (distance < 1000) return t.distanceMeters(distance);
    return t.distanceKilometers(distance / 1000);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(t.checkout, style: const TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE60064)),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildDeliverySection(t),
                      const SizedBox(height: 16),
                      _buildPaymentSection(t),
                    ],
                  ),
                ),
                _buildSummary(t),
              ],
            ),
    );
  }

  Widget _buildDeliverySection(AppText t) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.deliveryMethod,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _deliveryOptionCard(
            method: DeliveryMethod.pickup,
            title: t.pickupFromStore,
            priceLabel: t.free,
            icon: Icons.storefront,
          ),
          const SizedBox(height: 10),
          _deliveryOptionCard(
            method: DeliveryMethod.courier,
            title: t.courierDelivery,
            priceLabel: t.priceValue(_courierDeliveryPrice),
            icon: Icons.local_shipping_outlined,
          ),
          const SizedBox(height: 16),
          if (_deliveryMethod == DeliveryMethod.pickup)
            _buildPickupSection(t)
          else
            _buildCourierSection(t),
        ],
      ),
    );
  }

  Widget _deliveryOptionCard({
    required DeliveryMethod method,
    required String title,
    required String priceLabel,
    required IconData icon,
  }) {
    final selected = _deliveryMethod == method;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _selectDeliveryMethod(method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF6F8) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? darkPink : const Color(0xFFFFE6EB),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? darkPink : Colors.black45,
            ),
            Icon(icon, color: selected ? darkPink : Colors.black54),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            Text(
              priceLabel,
              style: TextStyle(
                color: selected ? darkPink : Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupSection(AppText t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.selectStore,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 240,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _selectedPickupStore?.location ?? _astanaCenter,
                initialZoom: 12.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.gulalem.app',
                ),
                MarkerLayer(markers: _mapMarkers()),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_locationLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        ..._sortedPickupStores().map((store) => _pickupStoreTile(t, store)),
      ],
    );
  }

  List<Marker> _mapMarkers() {
    final markers = pickupStores.map((store) {
      final selected = _selectedPickupStore?.id == store.id;
      return Marker(
        point: store.location,
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () => setState(() => _selectedPickupStore = store),
          child: Icon(
            Icons.location_on,
            size: selected ? 42 : 36,
            color: selected ? darkPink : const Color(0xFF333333),
          ),
        ),
      );
    }).toList();

    final position = _userPosition;
    if (position != null) {
      markers.add(
        Marker(
          point: LatLng(position.latitude, position.longitude),
          width: 34,
          height: 34,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _pickupStoreTile(AppText t, PickupStore store) {
    final selected = _selectedPickupStore?.id == store.id;
    final distance = _distanceLabel(t, store);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selectedPickupStore = store),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF6F8) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? darkPink : const Color(0xFFFFE6EB),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.storefront, color: selected ? darkPink : Colors.black54),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.pickupStoreName(store.id, store.name),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.pickupStoreAddress(store.id, store.address),
                    style: const TextStyle(color: Colors.black54),
                  ),
                  if (distance.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      distance,
                      style: TextStyle(
                        color: darkPink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: darkPink),
          ],
        ),
      ),
    );
  }

  Widget _buildCourierSection(AppText t) {
    return TextField(
      controller: _deliveryAddressController,
      minLines: 1,
      maxLines: 3,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: t.deliveryAddress,
        prefixIcon: const Icon(Icons.location_on_outlined),
        filled: true,
        fillColor: const Color(0xFFFFF6F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPaymentSection(AppText t) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.paymentMethod,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _addMethod,
                icon: const Icon(Icons.add, size: 18),
                label: Text(t.add),
                style: TextButton.styleFrom(foregroundColor: darkPink),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_methods.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.credit_card, size: 42, color: Colors.black54),
                const SizedBox(height: 12),
                Text(
                  t.noPaymentMethods,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  t.noPaymentMethodsQuestion,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            )
          else
            ..._methods.map((method) => _paymentMethodTile(t, method)),
        ],
      ),
    );
  }

  Widget _paymentMethodTile(AppText t, dynamic method) {
    final id = method['id']?.toString() ?? '';
    final last4 = method['last4'] ?? '';
    final selected = _selectedId == id;
    final deleting = _deletingMethodIds.contains(id);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: deleting ? null : () => setState(() => _selectedId = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF6F8) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? darkPink : const Color(0xFFFFE6EB),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? darkPink : Colors.black45,
            ),
            const SizedBox(width: 12),
            const Icon(Icons.credit_card, color: Colors.black54),
            const SizedBox(width: 12),
            Expanded(child: Text(t.paymentCardEnding(last4))),
            const SizedBox(width: 8),
            if (deleting)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                tooltip: t.delete,
                icon: const Icon(Icons.delete_outline, color: Colors.black54),
                onPressed: () => _deleteMethod(method),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(AppText t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _summaryRow(t.subtotal, t.priceValue(widget.total)),
            const SizedBox(height: 6),
            _summaryRow(
              t.deliveryFee,
              _deliveryPrice == 0 ? t.free : t.priceValue(_deliveryPrice),
            ),
            const Divider(height: 18),
            _summaryRow(
              t.totalAmount,
              t.priceValue(_orderTotal),
              valueStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkPink,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkPink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _processing ? null : _confirmPayment,
                child: _processing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        t.placeOrder,
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE6EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
