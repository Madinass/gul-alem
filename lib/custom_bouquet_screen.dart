import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_language.dart';
import 'custom_bouquet_item.dart';
import 'services/api_service.dart';

class CustomBouquetScreen extends StatefulWidget {
  const CustomBouquetScreen({super.key});

  @override
  State<CustomBouquetScreen> createState() => _CustomBouquetScreenState();
}

class _CustomBouquetScreenState extends State<CustomBouquetScreen> {
  final Color darkPink = const Color(0xFFE60064);
  final Color lightPink = const Color(0xFFFFE6EB);
  final TextEditingController _descriptionController = TextEditingController();

  List<CustomBouquetItem> _items = [];
  final Map<String, int> _quantities = {};
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final items = await ApiService.fetchCustomBouquetItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  int get _total {
    return _items.fold<int>(0, (sum, item) {
      final quantity = _quantities[item.id] ?? 0;
      return sum + item.price * quantity;
    });
  }

  int get _selectedCount {
    return _quantities.values.fold<int>(0, (sum, quantity) => sum + quantity);
  }

  List<CustomBouquetItem> _itemsForGroup(String group) {
    return _items.where((item) => item.group == group).toList()..sort((a, b) {
      final orderCompare = a.order.compareTo(b.order);
      if (orderCompare != 0) return orderCompare;
      return a.name.compareTo(b.name);
    });
  }

  void _changeQuantity(CustomBouquetItem item, int delta) {
    if (!item.available) return;
    final current = _quantities[item.id] ?? 0;
    final next = (current + delta).clamp(0, item.stockCount).toInt();
    setState(() {
      if (next == 0) {
        _quantities.remove(item.id);
      } else {
        _quantities[item.id] = next;
      }
    });
  }

  Future<void> _submit() async {
    final t = context.t;
    if (_selectedCount == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.chooseAtLeastOneCustomItem)));
      return;
    }
    setState(() => _submitting = true);
    try {
      final payload = _quantities.entries
          .where((entry) => entry.value > 0)
          .map((entry) => {'itemId': entry.key, 'quantity': entry.value})
          .toList();
      await ApiService.createCustomBouquetOrder(
        items: payload,
        description: _descriptionController.text.trim(),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t.success),
          content: Text(t.customBouquetCreated),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.customBouquetFailed)));
    } finally {
      if (mounted) setState(() => _submitting = false);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t.customBouquet,
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE60064)),
            )
          : RefreshIndicator(
              color: darkPink,
              onRefresh: _loadItems,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(t),
                    const SizedBox(height: 14),
                    _buildBouquetPreview(),
                    const SizedBox(height: 18),
                    Text(
                      t.bouquetOptions,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final group in const ['flowers', 'wrapping', 'extras'])
                      _buildGroup(t, group),
                    const SizedBox(height: 10),
                    Text(
                      t.bouquetDescription,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: t.bouquetDescriptionHint,
                        filled: true,
                        fillColor: const Color(0xFFFFF6F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _loading ? null : _buildBottomBar(t),
    );
  }

  Widget _buildHero(AppText t) {
    return Container(
      height: 178,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        image: DecorationImage(
          image: const AssetImage('assets/cat_10.png'),
          fit: BoxFit.cover,
          alignment: const Alignment(0.1, 0),
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.24),
            BlendMode.darken,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              t.customBouquetCtaTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.customBouquetSubtitle,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBouquetPreview() {
    final entries = _previewEntries();

    return Container(
      height: 252,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lightPink),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: width * 0.24,
                  right: width * 0.24,
                  bottom: 18,
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                if (entries.isEmpty)
                  Center(
                    child: Icon(
                      Icons.local_florist,
                      color: darkPink.withValues(alpha: 0.34),
                      size: 58,
                    ),
                  )
                else
                  for (final entry in entries)
                    _buildPreviewSticker(entry, width, height),
              ],
            );
          },
        ),
      ),
    );
  }

  List<_PreviewEntry> _previewEntries() {
    final byRole = <String, List<CustomBouquetItem>>{
      'wrap': [],
      'green': [],
      'flower': [],
      'balloon': [],
      'side': [],
      'front': [],
    };

    for (final group in const ['wrapping', 'extras', 'flowers']) {
      for (final item in _itemsForGroup(group)) {
        final quantity = _quantities[item.id] ?? 0;
        for (var index = 0; index < quantity; index += 1) {
          final total = byRole.values.fold<int>(
            0,
            (sum, roleItems) => sum + roleItems.length,
          );
          if (total >= 40) break;
          byRole[_previewRole(item)]?.add(item);
        }
      }
    }

    final entries = <_PreviewEntry>[];
    for (final role in const [
      'wrap',
      'green',
      'flower',
      'balloon',
      'side',
      'front',
    ]) {
      final items = byRole[role] ?? const <CustomBouquetItem>[];
      for (var index = 0; index < items.length; index += 1) {
        entries.add(
          _PreviewEntry(
            item: items[index],
            role: role,
            roleIndex: index,
            roleCount: items.length,
          ),
        );
      }
    }
    return entries;
  }

  String _previewRole(CustomBouquetItem item) {
    final image = item.displayImage.toLowerCase().replaceAll('_', '-');
    if (image.contains('kraft-wrap')) return 'wrap';
    if (image.contains('green-leaf')) return 'green';
    if (image.contains('satin-ribbon')) return 'front';
    if (image.contains('balloon')) return 'balloon';
    if (image.contains('card') || image.contains('premium-box')) return 'side';
    if (item.group == 'flowers') return 'flower';
    if (item.group == 'wrapping') return 'wrap';
    return 'side';
  }

  Widget _buildPreviewSticker(
    _PreviewEntry entry,
    double width,
    double height,
  ) {
    final placement = _previewPlacement(entry, width, height);
    return Positioned(
      left: placement.left,
      top: placement.top,
      width: placement.width,
      child: Transform.rotate(
        angle: placement.angle,
        child: _sourceImage(
          entry.item.displayImage,
          fallback: Icon(_iconForGroup(entry.item.group), color: darkPink),
        ),
      ),
    );
  }

  _PreviewPlacement _previewPlacement(
    _PreviewEntry entry,
    double width,
    double height,
  ) {
    final index = entry.roleIndex;
    final count = entry.roleCount;
    final progress = count <= 1 ? 0.5 : index / (count - 1);

    switch (entry.role) {
      case 'wrap':
        final stickerWidth = math.min(width * 0.34, 136.0);
        final centerOffset = (index - ((count - 1) / 2)) * 18.0;
        return _PreviewPlacement(
          left: (width / 2) + centerOffset - (stickerWidth / 2),
          top: height * 0.31 + (index.isEven ? 0 : 6),
          width: stickerWidth,
          angle: (index.isEven ? -0.06 : 0.07),
        );
      case 'green':
        final stickerWidth = math.min(width * 0.22, 86.0);
        final direction = index.isEven ? -1.0 : 1.0;
        final tier = index ~/ 2;
        return _PreviewPlacement(
          left:
              (width * 0.5) +
              (direction * width * 0.15) +
              (tier * direction * 7) -
              (stickerWidth / 2),
          top: height * 0.15 + (tier * 7),
          width: stickerWidth,
          angle: direction * 0.48,
        );
      case 'flower':
        final spread = math.min(width * 0.40, 150.0);
        final stickerWidth = count <= 4
            ? math.min(width * 0.25, 98.0)
            : math.max(54.0, math.min(86.0, width / (count + 1.5)));
        return _PreviewPlacement(
          left:
              (width * 0.5) + ((progress - 0.5) * spread) - (stickerWidth / 2),
          top: height * 0.27 - ((index % 3) * 5),
          width: stickerWidth,
          angle: -0.36 + (progress * 0.72),
        );
      case 'balloon':
        final stickerWidth = math.min(width * 0.22, 84.0);
        return _PreviewPlacement(
          left: width * 0.08 + (index * 10),
          top: height * 0.12 + ((index % 2) * 12),
          width: stickerWidth,
          angle: -0.16 + (index % 3) * 0.08,
        );
      case 'front':
        final stickerWidth = math.min(width * 0.31, 122.0);
        return _PreviewPlacement(
          left:
              (width / 2) -
              (stickerWidth / 2) +
              ((index - ((count - 1) / 2)) * 10),
          top: height * 0.62 + ((index % 2) * 5),
          width: stickerWidth,
          angle: index.isEven ? -0.04 : 0.05,
        );
      default:
        final stickerWidth = math.min(width * 0.24, 100.0);
        final rightSide = index.isOdd;
        final tier = index ~/ 2;
        return _PreviewPlacement(
          left: rightSide
              ? width * 0.72 - (tier * 8)
              : width * 0.08 + (tier * 8),
          top: height * 0.22 + (tier * 12),
          width: stickerWidth,
          angle: rightSide ? 0.18 : -0.18,
        );
    }
  }

  Widget _buildGroup(AppText t, String group) {
    final items = _itemsForGroup(group);
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.customGroupLabel(group),
            style: TextStyle(
              color: darkPink,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map((item) => _buildItemRow(t, item)),
        ],
      ),
    );
  }

  Widget _buildItemRow(AppText t, CustomBouquetItem item) {
    final quantity = _quantities[item.id] ?? 0;
    final disabled = !item.available;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: disabled ? const Color(0xFFF7F7F7) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: quantity > 0 ? darkPink : lightPink),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: lightPink,
              borderRadius: BorderRadius.circular(12),
            ),
            child: item.displayImage.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.all(4),
                    child: _sourceImage(
                      item.displayImage,
                      fallback: Icon(
                        _iconForGroup(item.group),
                        color: darkPink,
                      ),
                    ),
                  )
                : Icon(_iconForGroup(item.group), color: darkPink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: disabled ? Colors.black45 : Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _priceTag(t.priceValue(item.price)),
                    Text(
                      item.available
                          ? t.availableCount(item.stockCount)
                          : t.outOfStock,
                      style: TextStyle(
                        color: item.available ? Colors.black54 : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _quantityStepper(item, quantity),
        ],
      ),
    );
  }

  Widget _priceTag(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: darkPink,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _quantityStepper(CustomBouquetItem item, int quantity) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightPink),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepButton(
            icon: Icons.remove,
            enabled: quantity > 0,
            onTap: () => _changeQuantity(item, -1),
          ),
          SizedBox(
            width: 30,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          _stepButton(
            icon: Icons.add,
            enabled: item.available && quantity < item.stockCount,
            onTap: () => _changeQuantity(item, 1),
          ),
        ],
      ),
    );
  }

  Widget _stepButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, size: 18, color: enabled ? darkPink : Colors.black26),
      ),
    );
  }

  Widget _buildBottomBar(AppText t) {
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
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t.selectedItems}: $_selectedCount',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 5),
                Text(
                  t.priceValue(_total),
                  style: TextStyle(
                    color: darkPink,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: darkPink,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            label: Text(
              t.submitCustomBouquet,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceImage(String source, {required Widget fallback}) {
    if (source.isEmpty) return fallback;

    final uri = Uri.tryParse(source);
    final isNetwork =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

    if (isNetwork) {
      return Image.network(
        source,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    return Image.asset(
      source,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  IconData _iconForGroup(String group) {
    switch (group) {
      case 'flowers':
        return Icons.local_florist;
      case 'wrapping':
        return Icons.redeem;
      default:
        return Icons.add_circle_outline;
    }
  }
}

class _PreviewEntry {
  final CustomBouquetItem item;
  final String role;
  final int roleIndex;
  final int roleCount;

  const _PreviewEntry({
    required this.item,
    required this.role,
    required this.roleIndex,
    required this.roleCount,
  });
}

class _PreviewPlacement {
  final double left;
  final double top;
  final double width;
  final double angle;

  const _PreviewPlacement({
    required this.left,
    required this.top,
    required this.width,
    required this.angle,
  });
}
