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
  static const int _maxFlowerCount = 100;
  final Color darkPink = const Color(0xFFE60064);
  final Color lightPink = const Color(0xFFFFE6EB);
  final TextEditingController _descriptionController = TextEditingController();

  List<CustomBouquetItem> _items = [];
  final Map<String, int> _quantities = {};
  final Set<String> _expandedGroups = {'flowers'};
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

  int _selectedCountForGroup(String group) {
    return _itemsForGroup(
      group,
    ).fold<int>(0, (sum, item) => sum + (_quantities[item.id] ?? 0));
  }

  int get _selectedFlowerCount => _selectedCountForGroup('flowers');

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
    final maxQuantity = _maxQuantityForItem(item);
    final next = (current + delta).clamp(0, maxQuantity).toInt();
    setState(() {
      if (next == 0) {
        _quantities.remove(item.id);
      } else {
        _quantities[item.id] = next;
      }
    });
  }

  int _maxQuantityForItem(CustomBouquetItem item) {
    if (item.group != 'flowers') return item.stockCount;
    final current = _quantities[item.id] ?? 0;
    final otherFlowers = _selectedFlowerCount - current;
    final remainingForItem = _maxFlowerCount - otherFlowers;
    return math.min(item.stockCount, math.max(0, remainingForItem));
  }

  void _toggleWrappingItem(CustomBouquetItem item) {
    if (!item.available) return;
    final selected = (_quantities[item.id] ?? 0) > 0;
    setState(() {
      for (final wrapping in _itemsForGroup('wrapping')) {
        _quantities.remove(wrapping.id);
      }
      if (!selected) {
        _quantities[item.id] = 1;
      }
    });
  }

  void _toggleGroup(String group) {
    setState(() {
      if (_expandedGroups.contains(group)) {
        _expandedGroups.remove(group);
      } else {
        _expandedGroups.add(group);
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
      await ApiService.addCustomBouquetToCart(
        items: payload,
        description: _descriptionController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.addedToCart)));
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.addToCartFailed)));
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

  Widget _buildBouquetPreview() {
    final entries = _previewEntries();
    final t = context.t;

    return Container(
      height: 390,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8FA), Color(0xFFFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lightPink),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: lightPink.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_awesome, size: 16, color: darkPink),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      t.bouquetVisualization,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: darkPink,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
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
          ],
        ),
      ),
    );
  }

  List<_PreviewEntry> _previewEntries() {
    final byRole = <String, List<CustomBouquetItem>>{
      'wrap': [],
      'box': [],
      'green': [],
      'flower': [],
      'extra': [],
      'front': [],
    };

    for (final group in const ['wrapping', 'extras', 'flowers']) {
      for (final item in _itemsForGroup(group)) {
        final quantity = _quantities[item.id] ?? 0;
        for (var index = 0; index < quantity; index += 1) {
          final role = _previewRole(item);
          final roleItems = byRole[role];
          if (roleItems == null) continue;
          final roleLimit = role == 'flower' ? _maxFlowerCount : 10;
          if (roleItems.length >= roleLimit) break;
          roleItems.add(item);
        }
      }
    }

    final entries = <_PreviewEntry>[];
    for (final role in const [
      'wrap',
      'box',
      'green',
      'flower',
      'extra',
      'front',
    ]) {
      final items = byRole[role] ?? const <CustomBouquetItem>[];
      final indices = List<int>.generate(items.length, (index) => index);
      if (role == 'flower') {
        indices.sort(
          (a, b) => _flowerPaintRank(a).compareTo(_flowerPaintRank(b)),
        );
      }
      for (final index in indices) {
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
    if (image.contains('premium-box')) return 'box';
    if (image.contains('green-leaf')) return 'green';
    if (image.contains('satin-ribbon')) return 'front';
    if (item.group == 'flowers') return 'flower';
    if (item.group == 'wrapping') return 'wrap';
    return 'extra';
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

    switch (entry.role) {
      case 'wrap':
        final flowerCount = math.min(_selectedFlowerCount, 14);
        final stickerWidth = math.min(
          width * (0.60 + (flowerCount * 0.006)),
          244.0,
        );
        final centerOffset = (index - ((count - 1) / 2)) * 14.0;
        return _PreviewPlacement(
          left: (width / 2) + centerOffset - (stickerWidth / 2),
          top: height * 0.18 + (index.isEven ? 0 : 8),
          width: stickerWidth,
          angle: (index.isEven ? -0.06 : 0.07),
        );
      case 'box':
        final flowerCount = math.min(_selectedFlowerCount, 14);
        final stickerWidth = math.min(
          width * (0.50 + (flowerCount * 0.005)),
          204.0,
        );
        final centerOffset = (index - ((count - 1) / 2)) * 16.0;
        return _PreviewPlacement(
          left: (width / 2) + centerOffset - (stickerWidth / 2),
          top: height * 0.38 + (index.isEven ? 0 : 8),
          width: stickerWidth,
          angle: index.isEven ? -0.03 : 0.04,
        );
      case 'green':
        final stickerWidth = math.min(width * 0.21, 84.0);
        final direction = index.isEven ? -1.0 : 1.0;
        final tier = index ~/ 2;
        return _PreviewPlacement(
          left:
              (width * 0.5) +
              (direction * width * 0.12) +
              (tier * direction * 5) -
              (stickerWidth / 2),
          top: height * 0.16 - (tier * 5),
          width: stickerWidth,
          angle: direction * 0.48,
        );
      case 'flower':
        return _flowerPlacement(entry, width, height);
      case 'front':
        final stickerWidth = math.min(width * 0.31, 122.0);
        return _PreviewPlacement(
          left:
              (width / 2) -
              (stickerWidth / 2) +
              ((index - ((count - 1) / 2)) * 10),
          top: height * 0.68 + ((index % 2) * 5),
          width: stickerWidth,
          angle: index.isEven ? -0.04 : 0.05,
        );
      default:
        return _extraPlacement(entry, width, height);
    }
  }

  List<_FlowerSlot> get _firstFlowerOval => const [
    _FlowerSlot(x: 0, y: -0.04, angle: 0.03),
    _FlowerSlot(x: -0.105, y: -0.018, angle: -0.20),
    _FlowerSlot(x: 0.105, y: -0.018, angle: 0.20),
    _FlowerSlot(x: -0.14, y: 0.022, angle: -0.24),
    _FlowerSlot(x: 0.14, y: 0.022, angle: 0.24),
    _FlowerSlot(x: 0, y: 0.042, angle: -0.02),
  ];

  double _flowerPaintRank(int index) {
    if (index == 0) return 50;

    if (index <= _firstFlowerOval.length) {
      final y = _firstFlowerOval[index - 1].y;
      return y < 0 ? 20 + y : 70 + y;
    }

    final overflow = index - _firstFlowerOval.length - 1;
    const slotsPerRing = 10;
    final ring = (overflow ~/ slotsPerRing) + 1;
    final slot = overflow % slotsPerRing;
    final stagger = ring.isEven ? 0.18 : -0.10;
    final angle = (math.pi / 2) + stagger + (slot * 2 * math.pi / slotsPerRing);
    final y = math.sin(angle);
    return y < 0 ? 10 + ring + y : 80 + ring + y;
  }

  _PreviewPlacement _flowerPlacement(
    _PreviewEntry entry,
    double width,
    double height,
  ) {
    final index = entry.roleIndex;
    final count = entry.roleCount;
    final image = entry.item.displayImage.toLowerCase();
    final isTulip = image.contains('tulip');
    final angleOffset = isTulip ? -0.16 : 0.0;
    final baseWidth = math.min(width * 0.25, 98.0);
    final shrink = count <= 7 ? 0.0 : math.min(20.0, (count - 7) * 1.1);
    final stickerWidth =
        math.max(62.0, baseWidth - shrink) * (isTulip ? 0.76 : 1.0);

    if (index == 0) {
      return _PreviewPlacement(
        left: (width / 2) - (stickerWidth / 2),
        top: height * 0.27,
        width: stickerWidth,
        angle: angleOffset,
      );
    }

    if (index <= _firstFlowerOval.length) {
      final slot = _firstFlowerOval[index - 1];
      return _PreviewPlacement(
        left: (width * (0.5 + slot.x)) - (stickerWidth / 2),
        top: height * (0.27 + slot.y),
        width: stickerWidth,
        angle: slot.angle + angleOffset,
      );
    }

    final overflow = index - _firstFlowerOval.length - 1;
    const slotsPerRing = 10;
    final ring = (overflow ~/ slotsPerRing) + 1;
    final int slot = overflow % slotsPerRing;
    final stagger = ring.isEven ? 0.18 : -0.10;
    final angle = (math.pi / 2) + stagger + (slot * 2 * math.pi / slotsPerRing);
    final xRadius = math.min(0.15 + (ring * 0.022), 0.25);
    final yRadius = math.min(0.048 + (ring * 0.012), 0.09);
    final centerY = 0.35 + ((ring - 1) * 0.018);
    final x = math.cos(angle) * xRadius;
    final y = math.sin(angle) * yRadius;
    final topFactor = (centerY + y).clamp(0.24, 0.52).toDouble();
    final turn = (slot.isEven ? 0.18 : -0.18) + (ring * 0.02);

    return _PreviewPlacement(
      left: (width * (0.5 + x)) - (stickerWidth / 2),
      top: height * topFactor,
      width: stickerWidth,
      angle: turn + angleOffset,
    );
  }

  _PreviewPlacement _extraPlacement(
    _PreviewEntry entry,
    double width,
    double height,
  ) {
    final image = entry.item.displayImage.toLowerCase();
    final isBalloon = image.contains('balloon');
    final stickerWidth = isBalloon
        ? math.min(width * 0.22, 84.0)
        : math.min(width * 0.25, 98.0);
    final placements = [
      _PreviewPlacement(
        left: width * 0.70,
        top: height * (isBalloon ? 0.10 : 0.22),
        width: stickerWidth,
        angle: 0.16,
      ),
      _PreviewPlacement(
        left: width * 0.06,
        top: height * (isBalloon ? 0.12 : 0.23),
        width: stickerWidth,
        angle: -0.16,
      ),
      _PreviewPlacement(
        left: width * 0.16,
        top: height * 0.42,
        width: stickerWidth,
        angle: -0.08,
      ),
      _PreviewPlacement(
        left: width * 0.66,
        top: height * 0.42,
        width: stickerWidth,
        angle: 0.08,
      ),
    ];

    return placements[entry.roleIndex % placements.length];
  }

  Widget _buildGroup(AppText t, String group) {
    final items = _itemsForGroup(group);
    if (items.isEmpty) return const SizedBox.shrink();
    final expanded = _expandedGroups.contains(group);
    final selectedCount = _selectedCountForGroup(group);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6F8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: expanded ? darkPink : lightPink),
            ),
            child: Row(
              children: [
                Expanded(
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
                      if (group == 'flowers') ...[
                        const SizedBox(height: 3),
                        Text(
                          t.pick(
                            kz: 'Бір букетке $_maxFlowerCount гүлге дейін: $_selectedFlowerCount/$_maxFlowerCount',
                            ru: 'До $_maxFlowerCount цветов в букете: $_selectedFlowerCount/$_maxFlowerCount',
                            en: 'Up to $_maxFlowerCount flowers per bouquet: $_selectedFlowerCount/$_maxFlowerCount',
                          ),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (selectedCount > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$selectedCount',
                      style: TextStyle(
                        color: darkPink,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                  ),
                  onPressed: () => _toggleGroup(group),
                  icon: Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: darkPink,
                  ),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: items.map((item) => _buildItemRow(t, item)).toList(),
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
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
          item.group == 'wrapping'
              ? _checkmarkToggle(item, quantity > 0, disabled)
              : _quantityStepper(item, quantity),
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
            enabled: item.available && quantity < _maxQuantityForItem(item),
            onTap: () => _changeQuantity(item, 1),
          ),
        ],
      ),
    );
  }

  Widget _checkmarkToggle(
    CustomBouquetItem item,
    bool selected,
    bool disabled,
  ) {
    final enabled = item.available && !disabled;
    return InkWell(
      onTap: enabled ? () => _toggleWrappingItem(item) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selected ? darkPink : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? darkPink : (enabled ? lightPink : Colors.black12),
          ),
        ),
        child: Icon(
          Icons.check_rounded,
          size: 20,
          color: selected
              ? Colors.white
              : (enabled ? darkPink.withValues(alpha: 0.55) : Colors.black26),
        ),
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
                : const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
            label: Text(
              t.addToCart,
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

class _FlowerSlot {
  final double x;
  final double y;
  final double angle;

  const _FlowerSlot({required this.x, required this.y, required this.angle});
}
