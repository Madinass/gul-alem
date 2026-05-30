import 'package:flutter_test/flutter_test.dart';
import 'package:gul_alem/cart_item.dart';
import 'package:gul_alem/custom_bouquet_assets.dart';
import 'package:gul_alem/order_model.dart';
import 'package:gul_alem/product.dart';
import 'package:gul_alem/widgets/order_items_gallery.dart';

void main() {
  test('Product.fromJson accepts string-backed values from APIs', () {
    final product = Product.fromJson({
      'id': 12,
      'name': 123,
      'price': '15000',
      'imagePath': 'assets/product.png',
      'flowerType': 456,
      'inStock': 'false',
      'stockCount': '7',
      'popular': '1',
      'occasionTags': ['birthday'],
    });

    expect(product.id, '12');
    expect(product.name, '123');
    expect(product.price, 15000);
    expect(product.flowerType, '456');
    expect(product.inStock, isFalse);
    expect(product.stockCount, 7);
    expect(product.popular, isTrue);
    expect(product.occasionTags, ['birthday']);
  });

  test('CartItem.fromJson keeps product cart ids removable', () {
    final item = CartItem.fromJson({
      'id': 'cart-row-id',
      'itemType': 'product',
      'quantity': '2',
      'product': {
        'id': 'product-id',
        'name': 'Rose',
        'price': '3000',
        'imagePath': 'assets/rose.png',
        'flowerType': 'rose',
      },
    });

    expect(item.id, 'product-id');
    expect(item.itemType, 'product');
    expect(item.quantity, 2);
    expect(item.lineTotal, 6000);
  });

  test('custom cart line totals use the server custom total', () {
    final item = CartItem.fromJson({
      'id': 'custom-cart-id',
      'itemType': 'custom',
      'quantity': 3,
      'product': {
        'id': 'custom-cart-id',
        'name': 'Custom bouquet',
        'price': 5000,
        'imagePath': 'assets/custom.png',
        'flowerType': 'custom',
      },
      'customItems': [
        {
          'customItemId': 'rose-id',
          'name': 'Rose',
          'group': 'flowers',
          'price': '1000',
          'quantity': '5',
        },
      ],
    });

    expect(item.id, 'custom-cart-id');
    expect(item.isCustom, isTrue);
    expect(item.lineTotal, 15000);
    expect(item.customItems.single.lineTotal, 5000);
  });

  test('custom order lines keep card messages and bouquet details', () {
    final order = OrderModel.fromJson({
      '_id': 'order-id',
      'orderType': 'custom',
      'description': 'Pink style',
      'cardMessage': 'Happy birthday',
      'items': [
        {
          'name': 'Custom bouquet 1',
          'imagePath': customBouquetIconAsset,
          'price': 7000,
          'quantity': 1,
          'cardMessage': 'Happy birthday',
          'customItems': [
            {
              'customItemId': 'rose-id',
              'name': 'Red rose',
              'group': 'flowers',
              'imagePath': 'assets/custom_bouquet/custom_bouquet_red_rose.png',
              'price': 1000,
              'quantity': 7,
            },
          ],
        },
      ],
      'customItems': [
        {
          'customItemId': 'rose-id',
          'name': 'Red rose',
          'group': 'flowers',
          'imagePath': 'assets/custom_bouquet/custom_bouquet_red_rose.png',
          'price': 1000,
          'quantity': 7,
        },
      ],
      'total': 7000,
    });

    expect(order.cardMessage, 'Happy birthday');
    expect(order.items.single.cardMessage, 'Happy birthday');
    expect(order.items.single.customItems.single.quantity, 7);
    expect(OrderCustomDetails.itemsFromOrder(order), hasLength(1));

    final galleryItems = OrderItemsGallery.buildItems(order);
    expect(galleryItems, hasLength(1));
    expect(galleryItems.single.isCustomBouquet, isTrue);
    expect(galleryItems.single.customItems.single.name, 'Red rose');
  });

  test('OrderModel.fromJson accepts string-backed numeric values', () {
    final order = OrderModel.fromJson({
      '_id': 123,
      'status': 42,
      'items': [
        {'productId': 99, 'name': 'Rose', 'price': '3500', 'quantity': '2'},
      ],
      'subtotal': '7000',
      'deliveryPrice': '1000',
      'total': '8000',
      'createdAt': 123,
    });

    expect(order.id, '123');
    expect(order.status, '42');
    expect(order.items.single.productId, '99');
    expect(order.items.single.price, 3500);
    expect(order.items.single.quantity, 2);
    expect(order.subtotal, 7000);
    expect(order.deliveryPrice, 1000);
    expect(order.total, 8000);
  });
}
