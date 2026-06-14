import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_language.dart';
import '../custom_bouquet_assets.dart';
import '../order_model.dart';

class OrderGalleryItem {
  final String name;
  final String nameKz;
  final String nameRu;
  final String nameEn;
  final String imagePath;
  final String imageUrl;
  final bool isCustomBouquet;
  final List<OrderCustomItem> customItems;

  const OrderGalleryItem({
    required this.name,
    this.nameKz = '',
    this.nameRu = '',
    this.nameEn = '',
    required this.imagePath,
    required this.imageUrl,
    required this.isCustomBouquet,
    required this.customItems,
  });

  String get displayImage => imageUrl.isNotEmpty ? imageUrl : imagePath;
}

class OrderItemsGallery extends StatelessWidget {
  final List<OrderGalleryItem> items;

  const OrderItemsGallery({super.key, required this.items});

  factory OrderItemsGallery.fromOrder(OrderModel order) {
    return OrderItemsGallery(items: buildItems(order));
  }

  static List<OrderGalleryItem> buildItems(OrderModel order) {
    if (order.items.isEmpty && order.customItems.isEmpty) return const [];

    final hasOnlyOldCustomComponents =
        order.orderType == 'custom' &&
        order.items.isNotEmpty &&
        order.customItems.isNotEmpty &&
        order.items.every((item) => item.productId.isEmpty) &&
        order.items.every((item) => !item.isCustomBouquet);
    if (hasOnlyOldCustomComponents) {
      return [
        OrderGalleryItem(
          name: _customBouquetName(order.items.first.name),
          imagePath: customBouquetIconAsset,
          imageUrl: '',
          isCustomBouquet: true,
          customItems: order.customItems,
        ),
      ];
    }

    final galleryItems = <OrderGalleryItem>[];
    var fallbackCustomItemsUsed = false;
    for (final item in order.items) {
      final isCustom = item.isCustomBouquet;
      final customItems = item.customItems.isNotEmpty
          ? item.customItems
          : isCustom && !fallbackCustomItemsUsed
          ? order.customItems
          : const <OrderCustomItem>[];
      if (customItems.isNotEmpty) fallbackCustomItemsUsed = true;

      galleryItems.add(
        OrderGalleryItem(
          name: item.name,
          nameKz: item.nameKz,
          nameRu: item.nameRu,
          nameEn: item.nameEn,
          imagePath: item.imagePath,
          imageUrl: item.imageUrl,
          isCustomBouquet: isCustom || customItems.isNotEmpty,
          customItems: customItems,
        ),
      );
    }

    if (!fallbackCustomItemsUsed && order.customItems.isNotEmpty) {
      galleryItems.add(
        OrderGalleryItem(
          name: '',
          imagePath: customBouquetIconAsset,
          imageUrl: '',
          isCustomBouquet: true,
          customItems: order.customItems,
        ),
      );
    }

    return galleryItems;
  }

  static String _customBouquetName(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Custom bouquet' : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 152,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => _OrderItemCard(item: items[index]),
      ),
    );
  }
}

class OrderCustomDetails extends StatelessWidget {
  final List<OrderCustomItem> items;

  const OrderCustomDetails({super.key, required this.items});

  factory OrderCustomDetails.fromOrder(OrderModel order) {
    return OrderCustomDetails(items: itemsFromOrder(order));
  }

  static List<OrderCustomItem> itemsFromOrder(OrderModel order) {
    final nestedItems = order.items
        .expand((item) => item.customItems)
        .toList(growable: false);
    return nestedItems.isNotEmpty ? nestedItems : order.customItems;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final t = context.t;
    final grouped = <String, List<OrderCustomItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.group, () => []).add(item);
    }

    final orderedGroups = [
      for (final group in const ['flowers', 'wrapping', 'extras'])
        if (grouped.containsKey(group)) group,
      for (final group in grouped.keys)
        if (!const ['flowers', 'wrapping', 'extras'].contains(group)) group,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in orderedGroups)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${t.customGroupLabel(group)}: ${grouped[group]!.map((item) => _customItemLabel(t, item)).join(', ')}',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
      ],
    );
  }

  String _customItemLabel(AppText t, OrderCustomItem item) {
    return t.customItemQuantity(
      item.quantity,
      t.customItemName(item.imagePath, item.name),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  final OrderGalleryItem item;

  const _OrderItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final title = item.isCustomBouquet
        ? _customTitle(t)
        : t.productNameFromValues(
            name: item.name,
            nameKz: item.nameKz,
            nameRu: item.nameRu,
            nameEn: item.nameEn,
          );

    return SizedBox(
      width: 118,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFE6EB)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: ColoredBox(
                    color: const Color(0xFFFFF7FA),
                    child: item.isCustomBouquet
                        ? CustomBouquetPreviewImage(items: item.customItems)
                        : _sourceImage(
                            item.displayImage,
                            fit: BoxFit.contain,
                            fallback: const Icon(
                              Icons.local_florist_rounded,
                              color: Color(0xFFE60064),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _customTitle(AppText t) {
    final name = item.name.trim();
    if (name.isEmpty || name == 'Custom bouquet') return t.customBouquet;
    return t.productNameText(name);
  }
}

class CustomBouquetPreviewImage extends StatelessWidget {
  final List<OrderCustomItem> items;

  const CustomBouquetPreviewImage({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final entries = _previewEntries(items);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        if (entries.isEmpty) {
          return const Center(
            child: Icon(Icons.local_florist_rounded, color: Color(0xFFE60064)),
          );
        }

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFBFC), Color(0xFFFFFFFF)],
            ),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              for (final entry in entries)
                _PreviewSticker(entry: entry, width: width, height: height),
            ],
          ),
        );
      },
    );
  }
}

class _PreviewSticker extends StatelessWidget {
  final _PreviewEntry entry;
  final double width;
  final double height;

  const _PreviewSticker({
    required this.entry,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final placement = _previewPlacement(entry, width, height);
    return Positioned(
      left: placement.left,
      top: placement.top,
      width: placement.width,
      child: Transform.rotate(
        angle: placement.angle,
        child: _sourceImage(
          entry.item.displayImage,
          fit: BoxFit.contain,
          fallback: Icon(
            _iconForGroup(entry.item.group),
            color: const Color(0xFFE60064),
            size: 22,
          ),
        ),
      ),
    );
  }
}

List<_PreviewEntry> _previewEntries(List<OrderCustomItem> items) {
  final byRole = <String, List<OrderCustomItem>>{
    'wrap': [],
    'box': [],
    'green': [],
    'flower': [],
    'extra': [],
    'front': [],
  };

  final ordered = List<OrderCustomItem>.from(items)
    ..sort((a, b) {
      final groupCompare = _groupOrder(a.group).compareTo(_groupOrder(b.group));
      if (groupCompare != 0) return groupCompare;
      return a.name.compareTo(b.name);
    });

  for (final item in ordered) {
    final role = _previewRole(item);
    final roleItems = byRole[role];
    if (roleItems == null) continue;
    final limit = role == 'flower' ? 100 : 10;
    final quantity = math.max(0, item.quantity);
    for (
      var index = 0;
      index < quantity && roleItems.length < limit;
      index += 1
    ) {
      roleItems.add(item);
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
    final roleItems = byRole[role] ?? const <OrderCustomItem>[];
    final indices = List<int>.generate(roleItems.length, (index) => index);
    if (role == 'flower') {
      indices.sort(
        (a, b) => _flowerPaintRank(a).compareTo(_flowerPaintRank(b)),
      );
    }
    for (final index in indices) {
      entries.add(
        _PreviewEntry(
          item: roleItems[index],
          role: role,
          roleIndex: index,
          roleCount: roleItems.length,
        ),
      );
    }
  }
  return entries;
}

int _groupOrder(String group) {
  switch (group) {
    case 'wrapping':
      return 0;
    case 'extras':
      return 1;
    case 'flowers':
      return 2;
    default:
      return 3;
  }
}

String _previewRole(OrderCustomItem item) {
  final image = item.displayImage.toLowerCase().replaceAll('_', '-');
  if (image.contains('kraft-wrap')) return 'wrap';
  if (image.contains('premium-box')) return 'box';
  if (image.contains('green-leaf')) return 'green';
  if (image.contains('satin-ribbon')) return 'front';
  if (item.group == 'flowers') return 'flower';
  if (item.group == 'wrapping') return 'wrap';
  return 'extra';
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
      final stickerWidth = math.min(width * 0.86, 96.0);
      final centerOffset = (index - ((count - 1) / 2)) * 7.0;
      return _PreviewPlacement(
        left: (width / 2) + centerOffset - (stickerWidth / 2),
        top: height * 0.20 + (index.isEven ? 0 : 3),
        width: stickerWidth,
        angle: index.isEven ? -0.05 : 0.06,
      );
    case 'box':
      final stickerWidth = math.min(width * 0.74, 82.0);
      final centerOffset = (index - ((count - 1) / 2)) * 8.0;
      return _PreviewPlacement(
        left: (width / 2) + centerOffset - (stickerWidth / 2),
        top: height * 0.42 + (index.isEven ? 0 : 3),
        width: stickerWidth,
        angle: index.isEven ? -0.02 : 0.03,
      );
    case 'green':
      final stickerWidth = math.min(width * 0.29, 32.0);
      final direction = index.isEven ? -1.0 : 1.0;
      final tier = index ~/ 2;
      return _PreviewPlacement(
        left:
            (width * 0.5) +
            (direction * width * 0.13) +
            (tier * direction * 3) -
            (stickerWidth / 2),
        top: height * 0.15 - (tier * 2),
        width: stickerWidth,
        angle: direction * 0.44,
      );
    case 'flower':
      return _flowerPlacement(entry, width, height);
    case 'front':
      final stickerWidth = math.min(width * 0.42, 46.0);
      return _PreviewPlacement(
        left:
            (width / 2) -
            (stickerWidth / 2) +
            ((index - ((count - 1) / 2)) * 5),
        top: height * 0.70 + ((index % 2) * 2),
        width: stickerWidth,
        angle: index.isEven ? -0.03 : 0.04,
      );
    default:
      return _extraPlacement(entry, width, height);
  }
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
  final baseWidth = math.min(width * 0.33, 36.0);
  final shrink = count <= 7 ? 0.0 : math.min(8.0, (count - 7) * 0.45);
  final stickerWidth =
      math.max(22.0, baseWidth - shrink) * (isTulip ? 0.78 : 1.0);
  final angleOffset = isTulip ? -0.14 : 0.0;

  if (index == 0) {
    return _PreviewPlacement(
      left: (width / 2) - (stickerWidth / 2),
      top: height * 0.28,
      width: stickerWidth,
      angle: angleOffset,
    );
  }

  if (index <= _firstFlowerOval.length) {
    final slot = _firstFlowerOval[index - 1];
    return _PreviewPlacement(
      left: (width * (0.5 + slot.x)) - (stickerWidth / 2),
      top: height * (0.28 + slot.y),
      width: stickerWidth,
      angle: slot.angle + angleOffset,
    );
  }

  final overflow = index - _firstFlowerOval.length - 1;
  const slotsPerRing = 10;
  final ring = (overflow ~/ slotsPerRing) + 1;
  final slot = overflow % slotsPerRing;
  final stagger = ring.isEven ? 0.18 : -0.10;
  final angle = (math.pi / 2) + stagger + (slot * 2 * math.pi / slotsPerRing);
  final xRadius = math.min(0.15 + (ring * 0.022), 0.25);
  final yRadius = math.min(0.050 + (ring * 0.012), 0.09);
  final centerY = 0.36 + ((ring - 1) * 0.018);
  final x = math.cos(angle) * xRadius;
  final y = math.sin(angle) * yRadius;
  final topFactor = (centerY + y).clamp(0.25, 0.52).toDouble();
  final turn = (slot.isEven ? 0.16 : -0.16) + (ring * 0.02);

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
      ? math.min(width * 0.28, 32.0)
      : math.min(width * 0.32, 36.0);
  final placements = [
    _PreviewPlacement(
      left: width * 0.68,
      top: height * (isBalloon ? 0.10 : 0.23),
      width: stickerWidth,
      angle: 0.14,
    ),
    _PreviewPlacement(
      left: width * 0.05,
      top: height * (isBalloon ? 0.12 : 0.24),
      width: stickerWidth,
      angle: -0.14,
    ),
    _PreviewPlacement(
      left: width * 0.15,
      top: height * 0.46,
      width: stickerWidth,
      angle: -0.07,
    ),
    _PreviewPlacement(
      left: width * 0.65,
      top: height * 0.46,
      width: stickerWidth,
      angle: 0.07,
    ),
  ];
  return placements[entry.roleIndex % placements.length];
}

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

Widget _sourceImage(
  String source, {
  required Widget fallback,
  BoxFit fit = BoxFit.contain,
}) {
  if (source.isEmpty) return fallback;
  final uri = Uri.tryParse(source);
  final isNetwork =
      uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  if (isNetwork) {
    return Image.network(
      source,
      fit: fit,
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
      errorBuilder: (_, __, ___) => fallback,
    );
  }
  return Image.asset(source, fit: fit, errorBuilder: (_, __, ___) => fallback);
}

IconData _iconForGroup(String group) {
  switch (group) {
    case 'flowers':
      return Icons.local_florist_rounded;
    case 'wrapping':
      return Icons.redeem_rounded;
    default:
      return Icons.auto_awesome_rounded;
  }
}

const List<_FlowerSlot> _firstFlowerOval = [
  _FlowerSlot(x: 0, y: -0.04, angle: 0.03),
  _FlowerSlot(x: -0.105, y: -0.018, angle: -0.20),
  _FlowerSlot(x: 0.105, y: -0.018, angle: 0.20),
  _FlowerSlot(x: -0.14, y: 0.022, angle: -0.24),
  _FlowerSlot(x: 0.14, y: 0.022, angle: 0.24),
  _FlowerSlot(x: 0, y: 0.042, angle: -0.02),
];

class _PreviewEntry {
  final OrderCustomItem item;
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
