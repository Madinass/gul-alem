import 'package:flutter/material.dart';

import 'admin_statistics.dart';
import 'app_language.dart';
import 'services/api_service.dart';

class AdminStatisticsScreen extends StatefulWidget {
  final Future<AdminStatistics> Function() fetchStatistics;

  const AdminStatisticsScreen({
    super.key,
    Future<AdminStatistics> Function()? fetchStatistics,
  }) : fetchStatistics = fetchStatistics ?? ApiService.fetchAdminStatistics;

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  final Color darkPink = const Color(0xFFE60064);
  final Color lightPink = const Color(0xFFFFE6EB);

  AdminStatistics? _statistics;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final statistics = await widget.fetchStatistics();
      if (!mounted) return;
      setState(() {
        _statistics = statistics;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
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
        title: Text(
          t.adminStatistics,
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE60064)),
            )
          : _buildBody(t),
    );
  }

  Widget _buildBody(AppText t) {
    final error = _error;
    if (error != null) {
      return _messageState(Icons.error_outline_rounded, t.errorWith(error));
    }

    final statistics = _statistics;
    if (statistics == null || !statistics.hasData) {
      return RefreshIndicator(
        color: darkPink,
        onRefresh: _loadStatistics,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.28),
            _messageStateContent(Icons.insights_rounded, t.dataEmpty),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: darkPink,
      onRefresh: _loadStatistics,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummary(statistics, t),
          const SizedBox(height: 16),
          _buildProductSalesCard(
            title: t.topSellingProduct,
            product: statistics.topProduct,
            icon: Icons.leaderboard_rounded,
          ),
          const SizedBox(height: 12),
          _buildProductSalesCard(
            title: t.leastSellingProduct,
            product: statistics.leastProduct,
            icon: Icons.trending_down_rounded,
          ),
          const SizedBox(height: 16),
          _sectionTitle(t.unsoldProducts),
          const SizedBox(height: 10),
          _buildUnsoldProducts(statistics.unsoldProducts, t),
        ],
      ),
    );
  }

  Widget _buildSummary(AdminStatistics statistics, AppText t) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final tiles = [
          _summaryTile(
            icon: Icons.receipt_long_rounded,
            label: t.totalOrdersCount,
            value: statistics.totalOrders.toString(),
          ),
          _summaryTile(
            icon: Icons.payments_outlined,
            label: t.totalSalesAmount,
            value: t.priceValue(statistics.totalSales),
          ),
        ];

        if (compact) {
          return Column(
            children: [tiles[0], const SizedBox(height: 12), tiles[1]],
          );
        }

        return Row(
          children: [
            Expanded(child: tiles[0]),
            const SizedBox(width: 12),
            Expanded(child: tiles[1]),
          ],
        );
      },
    );
  }

  Widget _summaryTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: lightPink, shape: BoxShape.circle),
            child: Icon(icon, color: darkPink, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: darkPink,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSalesCard({
    required String title,
    required AdminProductSales? product,
    required IconData icon,
  }) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: darkPink, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (product == null)
            Text(t.dataEmpty, style: const TextStyle(color: Colors.black54))
          else
            _productSalesRow(product, t),
        ],
      ),
    );
  }

  Widget _buildUnsoldProducts(List<AdminProductSales> products, AppText t) {
    if (products.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: _panelDecoration(),
        child: Text(t.dataEmpty, style: const TextStyle(color: Colors.black54)),
      );
    }

    return Column(
      children: products
          .map(
            (product) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: _panelDecoration(),
              child: _productSalesRow(product, t, showSales: false),
            ),
          )
          .toList(),
    );
  }

  Widget _productSalesRow(
    AdminProductSales product,
    AppText t, {
    bool showSales = true,
  }) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _productImage(product),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.productNameText(product.name),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                showSales
                    ? '${t.soldCount(product.soldQuantity)} | ${t.priceValue(product.salesTotal)}'
                    : t.priceValue(product.price),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _productImage(AdminProductSales product) {
    final fallback = Container(
      width: 54,
      height: 54,
      color: const Color(0xFFFFF6F8),
      child: Icon(Icons.local_florist_rounded, color: darkPink),
    );
    final source = product.displayImage;
    if (source.isEmpty) return fallback;

    final uri = Uri.tryParse(source);
    final isNetwork =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    if (isNetwork) {
      return Image.network(
        source,
        width: 54,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    return Image.asset(
      source,
      width: 54,
      height: 54,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _messageState(IconData icon, String message) {
    return Center(child: _messageStateContent(icon, message));
  }

  Widget _messageStateContent(IconData icon, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: darkPink, size: 42),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: lightPink),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
