import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'category.dart';
import 'product.dart';

enum AppLocale { kz, ru, en }

extension AppLocaleData on AppLocale {
  String get code {
    switch (this) {
      case AppLocale.kz:
        return 'kz';
      case AppLocale.ru:
        return 'ru';
      case AppLocale.en:
        return 'en';
    }
  }

  String get shortLabel => code.toUpperCase();

  Locale get flutterLocale {
    switch (this) {
      case AppLocale.kz:
        return const Locale('kk');
      case AppLocale.ru:
        return const Locale('ru');
      case AppLocale.en:
        return const Locale('en');
    }
  }

  static AppLocale fromCode(String? code) {
    switch (code) {
      case 'ru':
        return AppLocale.ru;
      case 'en':
        return AppLocale.en;
      case 'kz':
      default:
        return AppLocale.kz;
    }
  }
}

class AppLanguageController extends ChangeNotifier {
  static const _prefsKey = 'app_language';

  AppLocale _locale = AppLocale.kz;

  AppLocale get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = AppLocaleData.fromCode(prefs.getString(_prefsKey));
  }

  Future<void> setLocale(AppLocale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.code);
  }
}

class AppLanguageScope extends InheritedNotifier<AppLanguageController> {
  const AppLanguageScope({
    super.key,
    required AppLanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLanguageController watch(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    assert(scope != null, 'AppLanguageScope not found');
    return scope!.notifier!;
  }

  static AppLanguageController read(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<AppLanguageScope>();
    final scope = element?.widget as AppLanguageScope?;
    assert(scope != null, 'AppLanguageScope not found');
    return scope!.notifier!;
  }
}

extension AppLanguageContext on BuildContext {
  AppText get t => AppText(AppLanguageScope.watch(this).locale);
}

class AppText {
  const AppText(this.locale);

  final AppLocale locale;

  String pick({required String kz, required String ru, required String en}) {
    switch (locale) {
      case AppLocale.kz:
        return kz;
      case AppLocale.ru:
        return ru;
      case AppLocale.en:
        return en;
    }
  }

  String get appName => 'Gul alem';
  String get next => pick(kz: 'Ары қарай', ru: 'Далее', en: 'Next');
  String get settings => pick(kz: 'Баптаулар', ru: 'Настройки', en: 'Settings');
  String get language => pick(kz: 'Тіл', ru: 'Язык', en: 'Language');
  String get kazakh => pick(kz: 'Қазақша', ru: 'Казахский', en: 'Kazakh');
  String get russian => pick(kz: 'Орысша', ru: 'Русский', en: 'Russian');
  String get english => pick(kz: 'Ағылшынша', ru: 'Английский', en: 'English');
  String get cancel => pick(kz: 'Бас тарту', ru: 'Отмена', en: 'Cancel');
  String get save => pick(kz: 'Сақтау', ru: 'Сохранить', en: 'Save');
  String get update => pick(kz: 'Жаңарту', ru: 'Обновить', en: 'Update');
  String get delete => pick(kz: 'Өшіру', ru: 'Удалить', en: 'Delete');
  String get close => pick(kz: 'Жабу', ru: 'Закрыть', en: 'Close');
  String get add => pick(kz: 'Қосу', ru: 'Добавить', en: 'Add');
  String get success => pick(kz: 'Сәтті', ru: 'Успешно', en: 'Success');
  String get error => pick(kz: 'Қате', ru: 'Ошибка', en: 'Error');
  String get loadingFailed => pick(
    kz: 'Жүктеу сәтсіз',
    ru: 'Не удалось загрузить',
    en: 'Loading failed',
  );
  String get fillAllFields => pick(
    kz: 'Барлық өрістерді толтырыңыз',
    ru: 'Заполните все поля',
    en: 'Fill in all fields',
  );

  String get addToCart =>
      pick(kz: 'Себетке қосу', ru: 'В корзину', en: 'Add to cart');
  String get addedToCart => pick(
    kz: 'Себетке қосылды',
    ru: 'Добавлено в корзину',
    en: 'Added to cart',
  );
  String get addToCartFailed => pick(
    kz: 'Себетке қосу сәтсіз',
    ru: 'Не удалось добавить в корзину',
    en: 'Could not add to cart',
  );
  String get updateCartFailed => pick(
    kz: 'Себетті жаңарту сәтсіз',
    ru: 'Не удалось обновить корзину',
    en: 'Could not update cart',
  );
  String get cart => pick(kz: 'Себет', ru: 'Корзина', en: 'Cart');
  String get cartEmpty =>
      pick(kz: 'Себет бос', ru: 'Корзина пуста', en: 'Cart is empty');
  String get quantity => pick(kz: 'Саны', ru: 'Количество', en: 'Quantity');
  String get totalPrice =>
      pick(kz: 'Жалпы баға', ru: 'Итоговая цена', en: 'Total price');
  String get totalAmount => pick(kz: 'Жалпы сома', ru: 'Итого', en: 'Total');
  String get continueAction =>
      pick(kz: 'Жалғастыру', ru: 'Продолжить', en: 'Continue');
  String get confirm => pick(kz: 'Растау', ru: 'Подтвердить', en: 'Confirm');
  String get outOfStock =>
      pick(kz: 'Қоймада жоқ', ru: 'Нет в наличии', en: 'Out of stock');
  String get inStock =>
      pick(kz: 'Қоймада бар', ru: 'В наличии', en: 'In stock');
  String get stock => pick(kz: 'Қойма', ru: 'Склад', en: 'Stock');

  String get searchFlowers => pick(
    kz: 'Гүлдерді іздеу...',
    ru: 'Поиск цветов...',
    en: 'Search flowers...',
  );
  String get searchPlaceholder =>
      pick(kz: 'Іздеу...', ru: 'Поиск...', en: 'Search...');
  String get noSearchResults => pick(
    kz: 'Іздеу нәтижесі табылмады',
    ru: 'Ничего не найдено',
    en: 'No search results',
  );
  String get searchResults => pick(
    kz: 'Іздеу нәтижелері',
    ru: 'Результаты поиска',
    en: 'Search results',
  );
  String get searchByPhoto =>
      pick(kz: 'Суретпен іздеу', ru: 'Поиск по фото', en: 'Search by photo');
  String get choosePhotoSource =>
      pick(kz: 'Суретті таңдаңыз', ru: 'Выберите фото', en: 'Choose photo');
  String get camera => pick(kz: 'Камера', ru: 'Камера', en: 'Camera');
  String get gallery => pick(kz: 'Галерея', ru: 'Галерея', en: 'Gallery');
  String get photoSearchResults => pick(
    kz: 'Сурет бойынша табылған өнімдер',
    ru: 'Найдено по фото',
    en: 'Found by photo',
  );
  String get photoSearchNoResults => pick(
    kz: 'Суретке сәйкес өнім табылмады',
    ru: 'По фото ничего не найдено',
    en: 'No photo matches found',
  );
  String get photoSearchFailed => pick(
    kz: 'Суретпен іздеу орындалмады',
    ru: 'Не удалось выполнить поиск по фото',
    en: 'Photo search failed',
  );
  String get photoSearchLoading => pick(
    kz: 'Сурет талданып жатыр...',
    ru: 'Анализируем фото...',
    en: 'Analyzing photo...',
  );
  String get clearPhotoSearch => pick(
    kz: 'Суретпен іздеуді тазалау',
    ru: 'Очистить поиск по фото',
    en: 'Clear photo search',
  );
  String get popularFlowers =>
      pick(kz: 'Сұраныстағы гүлдер', ru: 'Популярные цветы', en: 'Popular flowers');
  String get recommendedForYou => pick(
    kz: 'Сізге арналған ұсыныстар',
    ru: 'Рекомендации для вас',
    en: 'Recommended for you',
  );
  String get more => pick(kz: 'Толығырақ', ru: 'Подробнее', en: 'More');
  String get productsNotFound => pick(
    kz: 'Өнімдер табылмады',
    ru: 'Товары не найдены',
    en: 'No products found',
  );
  String get aboutUs => pick(kz: 'Біз жайлы', ru: 'О нас', en: 'About us');
  String get freshFlowers =>
      pick(kz: 'Жаңа гүлдер', ru: 'Свежие цветы', en: 'Fresh flowers');
  String get fastDelivery =>
      pick(kz: 'Жылдам жеткізу', ru: 'Быстрая доставка', en: 'Fast delivery');
  String get qualityGuarantee => pick(
    kz: 'Сапа кепілдігі',
    ru: 'Гарантия качества',
    en: 'Quality guarantee',
  );

  String get catalog => pick(kz: 'Каталог', ru: 'Каталог', en: 'Catalog');
  String get filters => pick(kz: 'Сүзгілер', ru: 'Фильтры', en: 'Filters');
  String get forWhom => pick(kz: 'Кімге', ru: 'Кому', en: 'For whom');
  String get occasion => pick(kz: 'Себеп', ru: 'Повод', en: 'Occasion');
  String get chooseRecipientTitle => pick(
    kz: 'Букет кімге арналған?',
    ru: 'Для кого букет?',
    en: 'Who is the bouquet for?',
  );
  String get chooseOccasionTitle => pick(
    kz: 'Себебін таңдаңыз',
    ru: 'Выберите повод',
    en: 'Choose an occasion',
  );
  String get filterResults => pick(
    kz: 'Сүзгі нәтижелері',
    ru: 'Результаты фильтра',
    en: 'Filter results',
  );
  String get noMatchingProducts => pick(
    kz: 'Сәйкес өнім табылмады',
    ru: 'Подходящих товаров не найдено',
    en: 'No matching products found',
  );
  String get categories =>
      pick(kz: 'Категориялар', ru: 'Категории', en: 'Categories');
  String get customBouquet =>
      pick(kz: 'Өз букетің', ru: 'Свой букет', en: 'DIY bouquet');
  String get customBouquetCtaTitle => pick(
    kz: 'Өз букетіңді құрастыр',
    ru: 'Соберите свой букет',
    en: 'Create your own bouquet',
  );
  String get customBouquetCtaSubtitle => pick(
    kz: 'Гүл, орама және қосымша таңдаңыз',
    ru: 'Выберите цветы, упаковку и детали',
    en: 'Choose flowers, wrapping, and extras',
  );
  String get customBouquetSubtitle => pick(
    kz: 'Әр бөлікті таңдап, бағасын бірден көріңіз.',
    ru: 'Выбирайте детали и сразу видите цену.',
    en: 'Pick each item and see the price instantly.',
  );
  String get bouquetVisualization => pick(
    kz: 'Букеттің көрінісі',
    ru: 'Визуализация букета',
    en: 'Bouquet preview',
  );
  String get bouquetOptions =>
      pick(kz: 'Бөліктер', ru: 'Детали', en: 'Options');
  String get bouquetDescription =>
      pick(kz: 'Сипаттама', ru: 'Описание', en: 'Description');
  String get bouquetDescriptionHint => pick(
    kz: 'Түстер, стиль немесе тілек жазыңыз',
    ru: 'Укажите цвета, стиль или пожелания',
    en: 'Add colors, style, or notes',
  );
  String get submitCustomBouquet =>
      pick(kz: 'Тапсырыс жіберу', ru: 'Отправить заказ', en: 'Send order');
  String get customBouquetCreated => pick(
    kz: 'Жеке букет тапсырысы жіберілді',
    ru: 'Заказ на свой букет отправлен',
    en: 'Custom bouquet order sent',
  );
  String get customBouquetFailed => pick(
    kz: 'Жеке букет тапсырысы жіберілмеді',
    ru: 'Не удалось отправить заказ',
    en: 'Could not send custom order',
  );
  String get chooseAtLeastOneCustomItem => pick(
    kz: 'Кемінде бір бөлікті таңдаңыз',
    ru: 'Выберите хотя бы одну деталь',
    en: 'Choose at least one item',
  );
  String get selectedItems =>
      pick(kz: 'Таңдалғандар', ru: 'Выбрано', en: 'Selected');
  String availableCount(int count) =>
      pick(kz: 'Қоймада: $count', ru: 'На складе: $count', en: 'Stock: $count');
  String customGroupLabel(String group) {
    switch (group) {
      case 'flowers':
        return pick(kz: 'Гүлдер', ru: 'Цветы', en: 'Flowers');
      case 'wrapping':
        return pick(kz: 'Орама', ru: 'Упаковка', en: 'Wrapping');
      case 'extras':
        return pick(kz: 'Қосымша', ru: 'Дополн.', en: 'Extras');
      default:
        return group;
    }
  }

  String get favorites =>
      pick(kz: 'Таңдаулылар', ru: 'Избранное', en: 'Favorites');
  String get favoritesEmpty => pick(
    kz: 'Таңдаулы өнімдер жоқ',
    ru: 'В избранном пока пусто',
    en: 'No favorite products',
  );
  String get removeFavoriteFailed => pick(
    kz: 'Таңдаулыдан өшіру сәтсіз',
    ru: 'Не удалось удалить из избранного',
    en: 'Could not remove from favorites',
  );
  String get addFavoriteFailed => pick(
    kz: 'Таңдаулыға қосу сәтсіз',
    ru: 'Не удалось добавить в избранное',
    en: 'Could not add to favorites',
  );
  String get priceAsc => pick(
    kz: 'Баға: өсуі бойынша',
    ru: 'Цена: по возрастанию',
    en: 'Price: low to high',
  );
  String get priceDesc => pick(
    kz: 'Баға: төмендеуі бойынша',
    ru: 'Цена: по убыванию',
    en: 'Price: high to low',
  );

  String get paymentMethod =>
      pick(kz: 'Төлем әдісі', ru: 'Способ оплаты', en: 'Payment method');
  String get paymentMethods =>
      pick(kz: 'Төлем әдістері', ru: 'Способы оплаты', en: 'Payment methods');
  String get addPaymentMethod => pick(
    kz: 'Төлем әдісін қосу',
    ru: 'Добавить способ оплаты',
    en: 'Add payment method',
  );
  String get noPaymentMethods => pick(
    kz: 'Төлем әдісі жоқ',
    ru: 'Нет способа оплаты',
    en: 'No payment method',
  );
  String get noPaymentMethodsQuestion => pick(
    kz: 'Төлем әдісі жоқ па?',
    ru: 'Добавить карту?',
    en: 'Need to add one?',
  );
  String get addPaymentMethodFirst => pick(
    kz: 'Алдымен төлем әдісін қосыңыз',
    ru: 'Сначала добавьте способ оплаты',
    en: 'Add a payment method first',
  );
  String get choosePaymentMethod => pick(
    kz: 'Төлем әдісін таңдаңыз',
    ru: 'Выберите способ оплаты',
    en: 'Choose a payment method',
  );
  String get paymentSuccessTitle => pick(
    kz: 'Төлем сәтті өтті',
    ru: 'Оплата прошла успешно',
    en: 'Payment successful',
  );
  String get pay => pick(kz: 'Төлем жасау', ru: 'Оплатить', en: 'Pay');
  String get orderAccepted =>
      pick(kz: 'Тапсырыс қабылданды', ru: 'Заказ принят', en: 'Order accepted');
  String get orderCreated => pick(
    kz: 'Тапсырыс сәтті жасалды',
    ru: 'Заказ успешно создан',
    en: 'Order created',
  );
  String get paymentFailed => pick(
    kz: 'Төлем жасау сәтсіз',
    ru: 'Оплата не прошла',
    en: 'Payment failed',
  );
  String get checkout =>
      pick(kz: 'Тапсырысты рәсімдеу', ru: 'Оформление заказа', en: 'Checkout');
  String get deliveryMethod =>
      pick(kz: 'Жеткізу әдісі', ru: 'Способ доставки', en: 'Delivery method');
  String get pickupFromStore => pick(
    kz: 'Дүкеннен алу',
    ru: 'Самовывоз из магазина',
    en: 'Pickup from store',
  );
  String get courierDelivery => pick(
    kz: 'Курьермен жеткізу',
    ru: 'Курьерская доставка',
    en: 'Courier delivery',
  );
  String get free => pick(kz: 'Тегін', ru: 'Бесплатно', en: 'Free');
  String get selectStore => pick(
    kz: 'Дүкенді таңдаңыз',
    ru: 'Выберите магазин',
    en: 'Select a store',
  );
  String get selectPickupStore => pick(
    kz: 'Алып кету дүкенін таңдаңыз.',
    ru: 'Выберите магазин для самовывоза.',
    en: 'Please select a pickup store.',
  );
  String get enterDeliveryAddress => pick(
    kz: 'Жеткізу мекенжайын енгізіңіз.',
    ru: 'Введите адрес доставки.',
    en: 'Please enter the delivery address.',
  );
  String get deliveryAddress => pick(
    kz: 'Жеткізу мекенжайы',
    ru: 'Адрес доставки',
    en: 'Delivery address',
  );
  String get subtotal =>
      pick(kz: 'Аралық сома', ru: 'Промежуточный итог', en: 'Subtotal');
  String get deliveryFee =>
      pick(kz: 'Жеткізу ақысы', ru: 'Стоимость доставки', en: 'Delivery fee');
  String get placeOrder =>
      pick(kz: 'Тапсырыс беру', ru: 'Оформить заказ', en: 'Place order');
  String get savePaymentMethodFailed => pick(
    kz: 'Төлем әдісін сақтау сәтсіз',
    ru: 'Не удалось сохранить способ оплаты',
    en: 'Could not save payment method',
  );
  String get loadPaymentMethodsFailed => pick(
    kz: 'Төлем әдістерін жүктеу сәтсіз',
    ru: 'Не удалось загрузить способы оплаты',
    en: 'Could not load payment methods',
  );
  String get loadPaymentMethodFailed => pick(
    kz: 'Төлем әдісін жүктеу сәтсіз',
    ru: 'Не удалось загрузить способ оплаты',
    en: 'Could not load payment method',
  );
  String get deletePaymentMethodFailed => pick(
    kz: 'Төлем әдісін өшіру сәтсіз',
    ru: 'Не удалось удалить способ оплаты',
    en: 'Could not delete payment method',
  );
  String get savedCardsEmpty => pick(
    kz: 'Сақталған карталар жоқ',
    ru: 'Сохраненных карт нет',
    en: 'No saved cards',
  );
  String get addCard =>
      pick(kz: 'Картаны қосу', ru: 'Добавить карту', en: 'Add card');
  String get updateCard =>
      pick(kz: 'Картаны жаңарту', ru: 'Обновить карту', en: 'Update card');
  String get cardholderName => pick(
    kz: 'Карта иесінің аты',
    ru: 'Имя владельца карты',
    en: 'Cardholder name',
  );
  String get cardholderNameHint =>
      pick(kz: 'КАРТА ИЕСІ', ru: 'ИМЯ ВЛАДЕЛЬЦА', en: 'CARDHOLDER NAME');
  String get cardNumber =>
      pick(kz: 'Карта нөмірі', ru: 'Номер карты', en: 'Card number');
  String get expiryDate =>
      pick(kz: 'Жарамдылық мерзімі', ru: 'Срок действия', en: 'Expiry date');
  String get cvv => pick(kz: 'CVV', ru: 'CVV', en: 'CVV');
  String get invalidCardholderName => pick(
    kz: 'Карта иесінің атын енгізіңіз',
    ru: 'Введите имя владельца карты',
    en: 'Enter the cardholder name',
  );
  String get invalidCardNumber => pick(
    kz: 'Карта нөмірі 16 саннан тұруы керек',
    ru: 'Номер карты должен содержать 16 цифр',
    en: 'Card number must contain 16 digits',
  );
  String get invalidExpiryDate => pick(
    kz: 'Жарамды мерзімді АА/ЖЖ форматында енгізіңіз',
    ru: 'Введите действительный срок в формате ММ/ГГ',
    en: 'Enter a valid expiry date in MM/YY format',
  );
  String get invalidCvv => pick(
    kz: 'CVV 3 немесе 4 саннан тұруы керек',
    ru: 'CVV должен содержать 3 или 4 цифры',
    en: 'CVV must contain 3 or 4 digits',
  );
  String get expMonth =>
      pick(kz: 'Аяқталу айы', ru: 'Месяц', en: 'Expiry month');
  String get expYear => pick(kz: 'Аяқталу жылы', ru: 'Год', en: 'Expiry year');
  String get cardMaskedDetails => pick(
    kz: 'Аты: *****  Мерзімі: **/**  CVV: ***',
    ru: 'Имя: *****  Срок: **/**  CVV: ***',
    en: 'Name: *****  Expiry: **/**  CVV: ***',
  );
  String get deleteCardTitle =>
      pick(kz: 'Картаны өшіру', ru: 'Удалить карту', en: 'Delete card');
  String get deleteCardQuestion => pick(
    kz: 'Осы төлем әдісін өшіресіз бе?',
    ru: 'Удалить этот способ оплаты?',
    en: 'Delete this payment method?',
  );

  String get profile =>
      pick(kz: 'Жеке кабинет', ru: 'Личный кабинет', en: 'Profile');
  String get guest => pick(kz: 'Қонақ', ru: 'Гость', en: 'Guest');
  String get noEmail =>
      pick(kz: 'Эл. пошта жоқ', ru: 'Нет эл. почты', en: 'No email');
  String get role => pick(kz: 'Рөл', ru: 'Роль', en: 'Role');
  String get logout => pick(kz: 'Шығу', ru: 'Выйти', en: 'Log out');
  String get adminSection => pick(
    kz: 'Әкімші бөлімі',
    ru: 'Раздел администратора',
    en: 'Admin section',
  );
  String get manageProducts => pick(
    kz: 'Өнімдерді басқару',
    ru: 'Управление товарами',
    en: 'Manage products',
  );
  String get manageOrders => pick(
    kz: 'Тапсырыстарды басқару',
    ru: 'Управление заказами',
    en: 'Manage orders',
  );
  String get manageCustomItems => pick(
    kz: 'Жеке букет бөліктері',
    ru: 'Детали своего букета',
    en: 'Custom bouquet items',
  );
  String get adminEmails =>
      pick(kz: 'Қызметкерлер', ru: 'Сотрудники', en: 'Staff access');
  String get orderHistory =>
      pick(kz: 'Тапсырыс тарихы', ru: 'История заказов', en: 'Order history');
  String get ordersEmpty =>
      pick(kz: 'Тапсырыстар жоқ', ru: 'Заказов нет', en: 'No orders');
  String get loadOrdersFailed => pick(
    kz: 'Тапсырыстарды жүктеу сәтсіз',
    ru: 'Не удалось загрузить заказы',
    en: 'Could not load orders',
  );

  String get adminAdd =>
      pick(kz: 'Қызметкер қосу', ru: 'Добавить сотрудника', en: 'Add staff');
  String get admins => pick(kz: 'Қызметкерлер', ru: 'Сотрудники', en: 'Staff');
  String get email => pick(kz: 'Эл. пошта', ru: 'Эл. почта', en: 'Email');
  String get roleAdmin => pick(kz: 'Әкімші', ru: 'Администратор', en: 'Admin');
  String get roleWorker => pick(kz: 'Қызметкер', ru: 'Сотрудник', en: 'Worker');
  String get roleSuperAdmin =>
      pick(kz: 'Бас әкімші', ru: 'Главный администратор', en: 'Super admin');
  String get products => pick(kz: 'Өнімдер', ru: 'Товары', en: 'Products');
  String get newProduct =>
      pick(kz: 'Жаңа өнім', ru: 'Новый товар', en: 'New product');
  String get editProduct =>
      pick(kz: 'Өнімді өңдеу', ru: 'Редактировать товар', en: 'Edit product');
  String get name => pick(kz: 'Атауы', ru: 'Название', en: 'Name');
  String get price => pick(kz: 'Бағасы', ru: 'Цена', en: 'Price');
  String get imagePath =>
      pick(kz: 'Сурет жолы', ru: 'Путь к изображению', en: 'Image path');
  String get chooseImage =>
      pick(kz: 'Сурет таңдау', ru: 'Выбрать изображение', en: 'Choose image');
  String get flowerType =>
      pick(kz: 'Гүл түрі', ru: 'Тип цветка', en: 'Flower type');
  String get stockCount =>
      pick(kz: 'Қойма саны', ru: 'Количество на складе', en: 'Stock count');
  String get category => pick(kz: 'Санат', ru: 'Категория', en: 'Category');
  String get popular => pick(kz: 'Сұраныста', ru: 'Популярный', en: 'Popular');
  String get sortOrder => pick(kz: 'Реті', ru: 'Порядок', en: 'Order');
  String get customItems => pick(
    kz: 'Жеке букет бөліктері',
    ru: 'Детали своего букета',
    en: 'Custom items',
  );
  String get newCustomItem =>
      pick(kz: 'Жаңа бөлік', ru: 'Новая деталь', en: 'New item');
  String get editCustomItem =>
      pick(kz: 'Бөлікті өңдеу', ru: 'Редактировать деталь', en: 'Edit item');
  String get itemGroup => pick(kz: 'Тобы', ru: 'Группа', en: 'Group');
  String get orders => pick(kz: 'Тапсырыстар', ru: 'Заказы', en: 'Orders');
  String get pending => pick(kz: 'Күтуде', ru: 'Ожидает', en: 'Pending');
  String get processing =>
      pick(kz: 'Өңделуде', ru: 'В обработке', en: 'Processing');
  String get completed =>
      pick(kz: 'Расталды', ru: 'Подтвержден', en: 'Completed');
  String get cancelled =>
      pick(kz: 'Бас тартылды', ru: 'Отменен', en: 'Cancelled');
  String get status => pick(kz: 'Күйі', ru: 'Статус', en: 'Status');
  String get orderMade =>
      pick(kz: 'Тапсырыс жасалды', ru: 'Заказ создан', en: 'Order placed');
  String get orderProcessing => pick(
    kz: 'Тапсырыс өңделуде',
    ru: 'Заказ обрабатывается',
    en: 'Order is processing',
  );
  String get orderCompleted => pick(
    kz: 'Тапсырыс расталды',
    ru: 'Заказ подтвержден',
    en: 'Order completed',
  );
  String get orderCancelled => pick(
    kz: 'Тапсырыс бас тартылды',
    ru: 'Заказ отменен',
    en: 'Order cancelled',
  );
  String get date => pick(kz: 'Күні', ru: 'Дата', en: 'Date');

  String get aiAdvisor =>
      pick(kz: 'ЖИ кеңесші', ru: 'ИИ-консультант', en: 'AI advisor');
  String get askAiAdvisor => pick(
    kz: 'ЖИ кеңесшіден сұрау',
    ru: 'Спросить ИИ-консультанта',
    en: 'Ask AI advisor',
  );
  String get aiAdvisorSubtitle => pick(
    kz: 'Сізге таңдауға көмектесемін',
    ru: 'Помогу выбрать',
    en: 'I can help you choose',
  );
  String get newChat => pick(kz: 'Жаңа чат', ru: 'Новый чат', en: 'New chat');
  String get noChatsYet =>
      pick(kz: 'Әзірге чат жоқ', ru: 'Чатов пока нет', en: 'No chats yet');
  String get askQuestionHint => pick(
    kz: 'Сұрағыңызды қойыңыз...',
    ru: 'Задайте вопрос...',
    en: 'Ask a question...',
  );
  String get chatGreeting => pick(
    kz: 'Сәлем! Гүлдер туралы қандай сұрағыңыз бар?',
    ru: 'Здравствуйте! Какой у вас вопрос о цветах?',
    en: 'Hi! What would you like to ask about flowers?',
  );
  String get aiError => pick(
    kz: 'Қате болды. Интернетті немесе API кілтін тексеріңіз.',
    ru: 'Произошла ошибка. Проверьте интернет или API-ключ.',
    en: 'Something went wrong. Check the internet connection or API key.',
  );

  String get notifications =>
      pick(kz: 'Хабарламалар', ru: 'Уведомления', en: 'Notifications');
  String get noNewNotifications => pick(
    kz: 'Жаңа хабарламалар жоқ',
    ru: 'Новых уведомлений нет',
    en: 'No new notifications',
  );
  String get notificationsWillAppear => pick(
    kz: 'Хабарламалар осы жерде көрсетіледі.',
    ru: 'Уведомления будут показаны здесь.',
    en: 'Notifications will appear here.',
  );

  String get loginSubtitle => pick(
    kz: 'Кіріп, жақыныңызды қуантыңыз!',
    ru: 'Войдите и порадуйте близких!',
    en: 'Sign in and make someone happy!',
  );
  String get loginRequired => pick(
    kz: 'Телефон нөмірін немесе эл. поштаны жазыңыз',
    ru: 'Введите телефон или эл. почту',
    en: 'Enter phone number or email',
  );
  String get passwordTooShort => pick(
    kz: 'Құпиясөз тым қысқа',
    ru: 'Пароль слишком короткий',
    en: 'Password is too short',
  );
  String get welcome =>
      pick(kz: 'Қош келдіңіз!', ru: 'Добро пожаловать!', en: 'Welcome!');
  String get loginFailed => pick(
    kz: 'Телефон немесе құпиясөз қате!',
    ru: 'Неверный телефон или пароль!',
    en: 'Phone or password is incorrect!',
  );
  String get phoneOrEmail => pick(
    kz: 'Телефон нөмірі немесе эл. пошта',
    ru: 'Телефон или эл. почта',
    en: 'Phone number or email',
  );
  String get password => pick(kz: 'Құпиясөз', ru: 'Пароль', en: 'Password');
  String get forgotPassword => pick(
    kz: 'Құпиясөзді ұмыттыңыз ба?',
    ru: 'Забыли пароль?',
    en: 'Forgot password?',
  );
  String get login => pick(kz: 'Кіру', ru: 'Войти', en: 'Log in');
  String get register => pick(kz: 'Тіркелу', ru: 'Регистрация', en: 'Register');
  String get registerSubtitle => pick(
    kz: 'Тіркеліп, жақыныңызды қуантыңыз!',
    ru: 'Зарегистрируйтесь и порадуйте близких!',
    en: 'Register and make someone happy!',
  );
  String get fullName =>
      pick(kz: 'Аты-жөніңіз', ru: 'Ваше имя', en: 'Full name');
  String get phoneNumber =>
      pick(kz: 'Телефон нөмірі', ru: 'Телефон', en: 'Phone number');
  String get invalidFullName => pick(
    kz: 'Атыңызды кемінде 2 әріппен енгізіңіз.',
    ru: 'Введите имя минимум из 2 букв.',
    en: 'Enter a name with at least 2 letters.',
  );
  String get invalidPhone => pick(
    kz: 'Телефон нөмірін 10-11 цифрмен енгізіңіз.',
    ru: 'Введите телефон из 10-11 цифр.',
    en: 'Enter a phone number with 10-11 digits.',
  );
  String get confirmPassword => pick(
    kz: 'Құпия сөзді қайталау',
    ru: 'Повторите пароль',
    en: 'Confirm password',
  );
  String get alreadyRegistered => pick(
    kz: 'Тіркелгенсіз бе?',
    ru: 'Уже зарегистрированы?',
    en: 'Already registered?',
  );
  String get registerAction => pick(
    kz: 'Тіркелуден өту',
    ru: 'Зарегистрироваться',
    en: 'Create account',
  );
  String get registrationSuccess => pick(
    kz: 'Тіркелу сәтті өтті!',
    ru: 'Регистрация прошла успешно!',
    en: 'Registration successful!',
  );
  String get serverConnectionError => pick(
    kz: 'Серверге қосылу қатесі',
    ru: 'Ошибка подключения к серверу',
    en: 'Server connection error',
  );
  String get passwordLengthRule => pick(
    kz: 'Құпия сөз 8-64 таңба аралығында болуы керек.',
    ru: 'Пароль должен быть от 8 до 64 символов.',
    en: 'Password must be 8-64 characters long.',
  );
  String get passwordNumberRule => pick(
    kz: 'Құпия сөзде кемінде бір сан болуы керек.',
    ru: 'Пароль должен содержать хотя бы одну цифру.',
    en: 'Password must contain at least one number.',
  );
  String get passwordSpecialRule => pick(
    kz: 'Құпия сөзде кемінде бір арнайы таңба болуы керек.',
    ru: 'Пароль должен содержать хотя бы один специальный символ.',
    en: 'Password must contain at least one special character.',
  );
  String get passwordsDoNotMatch => pick(
    kz: 'Құпия сөздер сәйкес келмейді!',
    ru: 'Пароли не совпадают!',
    en: 'Passwords do not match!',
  );

  String get forgotEmailTitle =>
      pick(kz: 'Email енгізу', ru: 'Введите email', en: 'Enter email');
  String get verifyCodeTitle =>
      pick(kz: 'Кодты тексеру', ru: 'Проверка кода', en: 'Verify code');
  String get newPasswordTitle =>
      pick(kz: 'Жаңа құпиясөз', ru: 'Новый пароль', en: 'New password');
  String get invalidEmail => pick(
    kz: 'Дұрыс email енгізіңіз.',
    ru: 'Введите корректный email.',
    en: 'Enter a valid email.',
  );
  String get codeLengthError => pick(
    kz: 'Код 6 таңбадан тұруы керек.',
    ru: 'Код должен состоять из 6 символов.',
    en: 'Code must be 6 characters long.',
  );
  String get wrongCode => pick(
    kz: 'Код қате. Қайта көріңіз.',
    ru: 'Неверный код. Попробуйте снова.',
    en: 'Wrong code. Try again.',
  );
  String get newPasswordRequired => pick(
    kz: 'Жаңа құпиясөзді енгізіп, растаңыз.',
    ru: 'Введите новый пароль и подтвердите его.',
    en: 'Enter and confirm the new password.',
  );
  String get passwordResetExpired => pick(
    kz: 'Қалпына келтіру мерзімі өтті. Жаңа код сұраңыз.',
    ru: 'Срок восстановления истек. Запросите новый код.',
    en: 'Password reset expired. Request a new code.',
  );
  String get genericTryAgain => pick(
    kz: 'Қате пайда болды. Қайта көріңіз.',
    ru: 'Произошла ошибка. Попробуйте снова.',
    en: 'Something went wrong. Try again.',
  );
  String get enterEmailForReset => pick(
    kz: 'Қалпына келтіру кодын алу үшін email енгізіңіз.',
    ru: 'Введите email, чтобы получить код восстановления.',
    en: 'Enter your email to receive a reset code.',
  );
  String get emailAddress =>
      pick(kz: 'Email адресі', ru: 'Email адрес', en: 'Email address');
  String get sendCode =>
      pick(kz: 'Код жіберу', ru: 'Отправить код', en: 'Send code');
  String codeSentTo(String email) => pick(
    kz: '$email адресіне келген 6 таңбалы кодты енгізіңіз.',
    ru: 'Введите 6-значный код, отправленный на $email.',
    en: 'Enter the 6-character code sent to $email.',
  );
  String get code => pick(kz: 'Код', ru: 'Код', en: 'Code');
  String get verifyCode =>
      pick(kz: 'Кодты растау', ru: 'Подтвердить код', en: 'Verify code');
  String get newPasswordHelp => pick(
    kz: 'Жаңа құпиясөзді енгізіп, растаңыз (8-64 таңба, 1 сан және арнайы таңба).',
    ru: 'Введите и подтвердите новый пароль (8-64 символа, 1 цифра и специальный символ).',
    en: 'Enter and confirm a new password (8-64 characters, 1 number, and a special character).',
  );
  String get changePassword => pick(
    kz: 'Құпиясөзді өзгерту',
    ru: 'Изменить пароль',
    en: 'Change password',
  );
  String get passwordChanged => pick(
    kz: 'Құпиясөз сәтті өзгертілді!',
    ru: 'Пароль успешно изменен!',
    en: 'Password changed successfully!',
  );
  String get loginWithNewPassword => pick(
    kz: 'Енді жаңа құпиясөзбен кіре аласыз.',
    ru: 'Теперь можно войти с новым паролем.',
    en: 'You can now log in with the new password.',
  );
  String get goToLogin =>
      pick(kz: 'Кіру бетіне', ru: 'К странице входа', en: 'Go to login');

  String get productDescription => pick(
    kz: 'Бұл гүл – нәзіктіктің және сұлулықтың символы. Кез келген мерекеге немесе жақыныңызға сый ретінде мінсіз таңдау',
    ru: 'Этот цветок - символ нежности и красоты. Отличный выбор для любого праздника или подарка близкому человеку.',
    en: 'This flower is a symbol of tenderness and beauty. A perfect choice for any celebration or as a gift for someone close.',
  );

  String errorWith(Object errorValue) =>
      '$error: ${localizedErrorMessage(errorValue)}';
  String roleValue(String roleValue) => '$role: ${roleLabel(roleValue)}';
  String roleLabel(String roleValue) {
    switch (roleValue) {
      case 'worker':
        return roleWorker;
      case 'admin':
        return roleAdmin;
      case 'super_admin':
        return roleSuperAdmin;
      default:
        return roleValue;
    }
  }

  String orderNumber(Object id) =>
      pick(kz: 'Тапсырыс №$id', ru: 'Заказ №$id', en: 'Order #$id');
  String get customOrderLabel =>
      pick(kz: 'Жеке букет', ru: 'Свой букет', en: 'Custom bouquet');
  String get standardOrderLabel =>
      pick(kz: 'Дайын өнім', ru: 'Готовый товар', en: 'Standard order');
  String totalWith(String amount) =>
      pick(kz: 'Жалпы: $amount', ru: 'Итого: $amount', en: 'Total: $amount');
  String descriptionWith(String value) => pick(
    kz: 'Сипаттама: $value',
    ru: 'Описание: $value',
    en: 'Description: $value',
  );
  String statusWith(String value) => '$status: $value';
  String dateWith(String value) => '$date: $value';
  String quantityTotalWith(int count, String total) => pick(
    kz: 'Саны: $count  |  Жалпы: $total',
    ru: 'Количество: $count  |  Итого: $total',
    en: 'Qty: $count  |  Total: $total',
  );
  String itemQuantity(Object name, Object quantityValue) => pick(
    kz: '${productNameText(name)} - $quantityValue дана',
    ru: '${productNameText(name)} - $quantityValue шт.',
    en: '${productNameText(name)} - $quantityValue pcs',
  );
  String productAdded(String productName) => pick(
    kz: '$productName себетке қосылды!',
    ru: '$productName добавлен в корзину!',
    en: '$productName added to cart!',
  );
  String serverConnectionErrorWith(Object errorValue) =>
      '$serverConnectionError: ${localizedErrorMessage(errorValue)}';

  String deliveryMethodLabel(String value) {
    switch (value) {
      case 'pickup':
        return pickupFromStore;
      case 'courier':
        return courierDelivery;
      default:
        return value;
    }
  }

  String deliveryMethodWith(String value) => pick(
    kz: '$deliveryMethod: $value',
    ru: '$deliveryMethod: $value',
    en: '$deliveryMethod: $value',
  );

  String deliveryAddressWith(String value) => pick(
    kz: '$deliveryAddress: $value',
    ru: '$deliveryAddress: $value',
    en: '$deliveryAddress: $value',
  );

  String deliveryFeeWith(String amount) => pick(
    kz: '$deliveryFee: $amount',
    ru: '$deliveryFee: $amount',
    en: '$deliveryFee: $amount',
  );

  String paymentCardEnding(Object last4) => pick(
    kz: '**** **** **** $last4',
    ru: '**** **** **** $last4',
    en: '**** **** **** $last4',
  );

  String distanceMeters(num value) => pick(
    kz: '${value.round()} м',
    ru: '${value.round()} м',
    en: '${value.round()} m',
  );

  String distanceKilometers(num value) {
    final formatted = value.toStringAsFixed(1);
    return pick(kz: '$formatted км', ru: '$formatted км', en: '$formatted km');
  }

  String customItemName(String imagePath, Object? name) {
    final map = _customItemNames[imagePath];
    if (map != null) return pick(kz: map.kz, ru: map.ru, en: map.en);
    return customItemNameText(name);
  }

  String customItemNameText(Object? name) {
    final value = name?.toString() ?? '';
    return _translateLocaleValue(value, _customItemNames.values);
  }

  String customItemQuantity(int quantity, String name) => pick(
    kz: '$name - $quantity дана',
    ru: '$name - $quantity шт.',
    en: '$quantity x $name',
  );

  String pickupStoreName(Object? id, Object? fallback) {
    final key = id?.toString() ?? '';
    final map = _pickupStoreNames[key];
    if (map != null) return pick(kz: map.kz, ru: map.ru, en: map.en);
    return fallback?.toString() ?? '';
  }

  String pickupStoreAddress(Object? id, Object? fallback) {
    final key = id?.toString() ?? '';
    final map = _pickupStoreAddresses[key];
    if (map != null) return pick(kz: map.kz, ru: map.ru, en: map.en);
    return fallback?.toString() ?? '';
  }

  String notificationText(String value) {
    final normalized = value.trim();
    final orderSummary = RegExp(
      r'^Тапсырыс №(.+) \| Клиент: (.*) \| Саны: ([0-9]+) \| Жалпы: ([0-9]+)$',
    ).firstMatch(normalized);
    if (orderSummary != null) {
      final id = orderSummary.group(1)!;
      final customer = orderSummary.group(2)!;
      final count = orderSummary.group(3)!;
      final total = _notificationAmount(orderSummary.group(4)!);
      return pick(
        kz: 'Тапсырыс №$id | Клиент: $customer | Саны: $count | Жалпы: $total',
        ru: 'Заказ №$id | Клиент: $customer | Количество: $count | Итого: $total',
        en: 'Order #$id | Customer: $customer | Qty: $count | Total: $total',
      );
    }

    final orderAccepted = RegExp(
      r'^Тапсырыс №(.+) қабылданды$',
    ).firstMatch(normalized);
    if (orderAccepted != null) {
      final id = orderAccepted.group(1)!;
      return pick(
        kz: 'Тапсырыс №$id қабылданды',
        ru: 'Заказ №$id принят',
        en: 'Order #$id accepted',
      );
    }

    final orderOnly = RegExp(r'^Тапсырыс №(.+)$').firstMatch(normalized);
    if (orderOnly != null) return orderNumber(orderOnly.group(1)!);

    return _translateLocaleValue(normalized, _notificationTexts);
  }

  String _notificationAmount(String value) {
    final amount = int.tryParse(value);
    return amount == null ? value : priceValue(amount);
  }

  String localizedErrorMessage(Object errorValue) {
    final raw = errorValue.toString();
    final message = raw
        .replaceFirst(RegExp(r'^(Exception|ApiException):\s*'), '')
        .trim();
    if (message.startsWith('Image upload failed')) {
      return pick(
        kz: 'Суретті жүктеу сәтсіз',
        ru: 'Не удалось загрузить изображение',
        en: 'Image upload failed',
      );
    }
    final localized = _translateLocaleValue(message, _apiErrorTexts);
    return localized == message && message.isNotEmpty ? message : localized;
  }

  String statusLabel(String statusValue) {
    switch (statusValue) {
      case 'pending':
        return pending;
      case 'processing':
        return processing;
      case 'completed':
        return completed;
      case 'cancelled':
        return cancelled;
      default:
        return statusValue;
    }
  }

  String orderStatusLabel(String statusValue) {
    switch (statusValue) {
      case 'pending':
        return orderMade;
      case 'processing':
        return orderProcessing;
      case 'completed':
        return orderCompleted;
      case 'cancelled':
        return orderCancelled;
      default:
        return statusValue;
    }
  }

  String filterOption(String id) {
    final map = _filterOptions[id];
    return map == null ? id : pick(kz: map.kz, ru: map.ru, en: map.en);
  }

  String productName(Product product) {
    final key = product.imagePath;
    final map = _productNames[key];
    if (map != null) return pick(kz: map.kz, ru: map.ru, en: map.en);
    return product.name;
  }

  String productNameText(Object? name) {
    final value = name?.toString() ?? '';
    final productName = _translateLocaleValue(value, _productNames.values);
    if (productName != value) return productName;
    return customItemNameText(value);
  }

  String categoryName(Category category) {
    final key = category.imagePath;
    final map = _categoryNames[key];
    if (map != null) return pick(kz: map.kz, ru: map.ru, en: map.en);
    return category.name;
  }

  String priceValue(int value) {
    final formatted = Product.formatPrice(value).replaceAll(' тг', '');
    return locale == AppLocale.en ? '$formatted KZT' : '$formatted тг';
  }

  String _translateLocaleValue(String value, Iterable<_LocaleValue> values) {
    final normalized = value.trim();
    for (final item in values) {
      if (normalized == item.kz ||
          normalized == item.ru ||
          normalized == item.en) {
        return pick(kz: item.kz, ru: item.ru, en: item.en);
      }
    }
    return value;
  }
}

class _LocaleValue {
  const _LocaleValue({required this.kz, required this.ru, required this.en});

  final String kz;
  final String ru;
  final String en;
}

const List<_LocaleValue> _notificationTexts = [
  _LocaleValue(
    kz: 'Төлем сәтті өтті',
    ru: 'Оплата прошла успешно',
    en: 'Payment successful',
  ),
  _LocaleValue(kz: 'Тапсырыс жасалды', ru: 'Заказ создан', en: 'Order placed'),
  _LocaleValue(
    kz: 'Тапсырыс қабылданды',
    ru: 'Заказ принят',
    en: 'Order accepted',
  ),
  _LocaleValue(
    kz: 'Тапсырыс сәтті жасалды',
    ru: 'Заказ успешно создан',
    en: 'Order created',
  ),
  _LocaleValue(kz: 'Жаңа тапсырыс', ru: 'Новый заказ', en: 'New order'),
  _LocaleValue(
    kz: 'Жеке букет тапсырысы',
    ru: 'Заказ своего букета',
    en: 'Custom bouquet order',
  ),
  _LocaleValue(
    kz: 'Жаңа жеке букет',
    ru: 'Новый свой букет',
    en: 'New custom bouquet',
  ),
  _LocaleValue(
    kz: 'Тапсырыс күту режимінде',
    ru: 'Заказ ожидает обработки',
    en: 'Order is pending',
  ),
  _LocaleValue(
    kz: 'Тапсырыс өңделуде',
    ru: 'Заказ обрабатывается',
    en: 'Order is processing',
  ),
  _LocaleValue(
    kz: 'Тапсырыс расталды',
    ru: 'Заказ подтвержден',
    en: 'Order confirmed',
  ),
  _LocaleValue(
    kz: 'Тапсырыс бас тартылды',
    ru: 'Заказ отменен',
    en: 'Order cancelled',
  ),
  _LocaleValue(
    kz: 'Тапсырыс мәртебесі өзгерді',
    ru: 'Статус заказа изменен',
    en: 'Order status changed',
  ),
];

const List<_LocaleValue> _apiErrorTexts = [
  _LocaleValue(
    kz: 'Кіру қажет',
    ru: 'Требуется вход',
    en: 'Authentication required',
  ),
  _LocaleValue(kz: 'Кіру сәтсіз', ru: 'Не удалось войти', en: 'Login failed'),
  _LocaleValue(
    kz: 'Тіркелу сәтсіз',
    ru: 'Не удалось зарегистрироваться',
    en: 'Registration failed',
  ),
  _LocaleValue(
    kz: 'Бұл пайдаланушы бұрыннан бар',
    ru: 'Пользователь уже существует',
    en: 'User already exists',
  ),
  _LocaleValue(
    kz: 'Аты-жөні дұрыс емес',
    ru: 'Некорректное имя',
    en: 'Invalid full name',
  ),
  _LocaleValue(
    kz: 'Телефон нөмірі дұрыс емес',
    ru: 'Некорректный телефон',
    en: 'Invalid phone number',
  ),
  _LocaleValue(
    kz: 'Email дұрыс емес',
    ru: 'Некорректный email',
    en: 'Invalid email',
  ),
  _LocaleValue(
    kz: 'Құпиясөз талаптарға сәйкес емес',
    ru: 'Пароль не соответствует требованиям',
    en: 'Password does not meet requirements',
  ),
  _LocaleValue(
    kz: 'Қажетті өрістер толтырылмады',
    ru: 'Заполнены не все обязательные поля',
    en: 'Missing required fields',
  ),
  _LocaleValue(
    kz: 'Қалпына келтіру кодын жіберу сәтсіз',
    ru: 'Не удалось отправить код восстановления',
    en: 'Reset code send failed',
  ),
  _LocaleValue(
    kz: 'Қалпына келтіру кодын жіберу сәтсіз',
    ru: 'Не удалось отправить код восстановления',
    en: 'Failed to send reset code',
  ),
  _LocaleValue(
    kz: 'Кодты тексеру сәтсіз',
    ru: 'Не удалось проверить код',
    en: 'Code verification failed',
  ),
  _LocaleValue(
    kz: 'Құпиясөзді қалпына келтіру сәтсіз',
    ru: 'Не удалось восстановить пароль',
    en: 'Password reset failed',
  ),
  _LocaleValue(
    kz: 'Санаттарды жүктеу сәтсіз',
    ru: 'Не удалось загрузить категории',
    en: 'Could not load categories',
  ),
  _LocaleValue(
    kz: 'Өнімдерді жүктеу сәтсіз',
    ru: 'Не удалось загрузить товары',
    en: 'Could not load products',
  ),
  _LocaleValue(
    kz: 'Ұсыныстарды жүктеу сәтсіз',
    ru: 'Не удалось загрузить рекомендации',
    en: 'Could not load recommendations',
  ),
  _LocaleValue(
    kz: 'Жеке букет бөліктерін жүктеу сәтсіз',
    ru: 'Не удалось загрузить детали своего букета',
    en: 'Could not load custom bouquet items',
  ),
  _LocaleValue(
    kz: 'Жеке букет бөлігін құру сәтсіз',
    ru: 'Не удалось создать деталь своего букета',
    en: 'Could not create custom bouquet item',
  ),
  _LocaleValue(
    kz: 'Жеке букет бөлігін жаңарту сәтсіз',
    ru: 'Не удалось обновить деталь своего букета',
    en: 'Could not update custom bouquet item',
  ),
  _LocaleValue(
    kz: 'Жеке букет бөлігін өшіру сәтсіз',
    ru: 'Не удалось удалить деталь своего букета',
    en: 'Could not delete custom bouquet item',
  ),
  _LocaleValue(
    kz: 'Суретпен іздеу орындалмады',
    ru: 'Не удалось выполнить поиск по фото',
    en: 'Photo search failed',
  ),
  _LocaleValue(
    kz: 'Тапсырыстарды жүктеу сәтсіз',
    ru: 'Не удалось загрузить заказы',
    en: 'Could not load orders',
  ),
  _LocaleValue(
    kz: 'Тапсырыс мәртебесін жаңарту сәтсіз',
    ru: 'Не удалось обновить статус заказа',
    en: 'Could not update order status',
  ),
  _LocaleValue(
    kz: 'Әкімшілерді жүктеу сәтсіз',
    ru: 'Не удалось загрузить сотрудников',
    en: 'Could not load staff',
  ),
  _LocaleValue(
    kz: 'Әкімші қосу сәтсіз',
    ru: 'Не удалось добавить сотрудника',
    en: 'Could not add staff',
  ),
  _LocaleValue(
    kz: 'Әкімшіні жою сәтсіз',
    ru: 'Не удалось удалить сотрудника',
    en: 'Could not remove staff',
  ),
  _LocaleValue(
    kz: 'Өнім құру сәтсіз',
    ru: 'Не удалось создать товар',
    en: 'Could not create product',
  ),
  _LocaleValue(
    kz: 'Өнімді жаңарту сәтсіз',
    ru: 'Не удалось обновить товар',
    en: 'Could not update product',
  ),
  _LocaleValue(
    kz: 'Қойма жаңарту сәтсіз',
    ru: 'Не удалось обновить склад',
    en: 'Could not update stock',
  ),
  _LocaleValue(
    kz: 'Сұраныстағы күйін жаңарту сәтсіз',
    ru: 'Не удалось обновить популярность',
    en: 'Could not update popularity',
  ),
  _LocaleValue(
    kz: 'Өнімді жою сәтсіз',
    ru: 'Не удалось удалить товар',
    en: 'Could not delete product',
  ),
  _LocaleValue(
    kz: 'Чат тарихын жүктеу сәтсіз',
    ru: 'Не удалось загрузить историю чатов',
    en: 'Could not load chat history',
  ),
  _LocaleValue(
    kz: 'Жаңа чат құру сәтсіз',
    ru: 'Не удалось создать новый чат',
    en: 'Could not create new chat',
  ),
  _LocaleValue(
    kz: 'Чатты өшіру сәтсіз',
    ru: 'Не удалось удалить чат',
    en: 'Could not delete chat',
  ),
  _LocaleValue(
    kz: 'Чат хабарламаларын жүктеу сәтсіз',
    ru: 'Не удалось загрузить сообщения чата',
    en: 'Could not load chat messages',
  ),
  _LocaleValue(
    kz: 'AI хабарламасын жіберу сәтсіз',
    ru: 'Не удалось отправить сообщение AI',
    en: 'Could not send AI message',
  ),
  _LocaleValue(
    kz: 'Төлем әдістерін жүктеу сәтсіз',
    ru: 'Не удалось загрузить способы оплаты',
    en: 'Could not load payment methods',
  ),
  _LocaleValue(
    kz: 'Төлем әдісін жүктеу сәтсіз',
    ru: 'Не удалось загрузить способ оплаты',
    en: 'Could not load payment method',
  ),
  _LocaleValue(
    kz: 'Төлем әдісін құру сәтсіз',
    ru: 'Не удалось создать способ оплаты',
    en: 'Could not create payment method',
  ),
  _LocaleValue(
    kz: 'Төлем әдісін жаңарту сәтсіз',
    ru: 'Не удалось обновить способ оплаты',
    en: 'Could not update payment method',
  ),
  _LocaleValue(
    kz: 'Төлем әдісін жою сәтсіз',
    ru: 'Не удалось удалить способ оплаты',
    en: 'Could not delete payment method',
  ),
  _LocaleValue(
    kz: 'Таңдаулыларды жүктеу сәтсіз',
    ru: 'Не удалось загрузить избранное',
    en: 'Could not load favorites',
  ),
  _LocaleValue(
    kz: 'Таңдаулыға қосу сәтсіз',
    ru: 'Не удалось добавить в избранное',
    en: 'Could not add to favorites',
  ),
  _LocaleValue(
    kz: 'Таңдаулыдан жою сәтсіз',
    ru: 'Не удалось удалить из избранного',
    en: 'Could not remove from favorites',
  ),
  _LocaleValue(
    kz: 'Себетті жүктеу сәтсіз',
    ru: 'Не удалось загрузить корзину',
    en: 'Could not load cart',
  ),
  _LocaleValue(
    kz: 'Себетке қосу сәтсіз',
    ru: 'Не удалось добавить в корзину',
    en: 'Could not add to cart',
  ),
  _LocaleValue(
    kz: 'Себетті жаңарту сәтсіз',
    ru: 'Не удалось обновить корзину',
    en: 'Could not update cart',
  ),
  _LocaleValue(
    kz: 'Себеттен жою сәтсіз',
    ru: 'Не удалось удалить из корзины',
    en: 'Could not remove from cart',
  ),
  _LocaleValue(
    kz: 'Себетті тазалау сәтсіз',
    ru: 'Не удалось очистить корзину',
    en: 'Could not clear cart',
  ),
  _LocaleValue(
    kz: 'Жеке букетті себетке қосу сәтсіз',
    ru: 'Не удалось добавить свой букет в корзину',
    en: 'Could not add custom bouquet to cart',
  ),
  _LocaleValue(
    kz: 'Тапсырыс жасау сәтсіз',
    ru: 'Не удалось создать заказ',
    en: 'Could not create order',
  ),
  _LocaleValue(
    kz: 'Жеке букет тапсырысын жасау сәтсіз',
    ru: 'Не удалось создать заказ своего букета',
    en: 'Could not create custom bouquet order',
  ),
  _LocaleValue(
    kz: 'Менің тапсырыстарымды жүктеу сәтсіз',
    ru: 'Не удалось загрузить мои заказы',
    en: 'Could not load my orders',
  ),
  _LocaleValue(
    kz: 'Хабарламаларды жүктеу сәтсіз',
    ru: 'Не удалось загрузить уведомления',
    en: 'Could not load notifications',
  ),
  _LocaleValue(
    kz: 'Хабарлама құру сәтсіз',
    ru: 'Не удалось создать уведомление',
    en: 'Could not create notification',
  ),
  _LocaleValue(
    kz: 'Хабарламаны оқылғанға белгілеу сәтсіз',
    ru: 'Не удалось отметить уведомление прочитанным',
    en: 'Could not mark notification as read',
  ),
];

const Map<String, _LocaleValue> _customItemNames = {
  'assets/custom_bouquet/custom_bouquet_red_rose.png': _LocaleValue(
    kz: 'Қызыл раушан',
    ru: 'Красная роза',
    en: 'Red rose',
  ),
  'assets/custom_bouquet/custom_bouquet_white_rose.png': _LocaleValue(
    kz: 'Ақ раушан',
    ru: 'Белая роза',
    en: 'White rose',
  ),
  'assets/custom_bouquet/custom_bouquet_tulip.png': _LocaleValue(
    kz: 'Қызғалдақ',
    ru: 'Тюльпан',
    en: 'Tulip',
  ),
  'assets/custom_bouquet/custom_bouquet_hydrangea.png': _LocaleValue(
    kz: 'Гортензия',
    ru: 'Гортензия',
    en: 'Hydrangea',
  ),
  'assets/custom_bouquet/custom_bouquet_kraft_wrap.png': _LocaleValue(
    kz: 'Крафт қағазы',
    ru: 'Крафт-бумага',
    en: 'Kraft paper',
  ),
  'assets/custom_bouquet/custom_bouquet_satin_ribbon.png': _LocaleValue(
    kz: 'Атлас таспа',
    ru: 'Атласная лента',
    en: 'Satin ribbon',
  ),
  'assets/custom_bouquet/custom_bouquet_premium_box.png': _LocaleValue(
    kz: 'Премиум қорап',
    ru: 'Премиум-коробка',
    en: 'Premium box',
  ),
  'assets/custom_bouquet/custom_bouquet_green_leaf.png': _LocaleValue(
    kz: 'Жасыл жапырақ',
    ru: 'Зеленый лист',
    en: 'Green leaf',
  ),
  'assets/custom_bouquet/custom_bouquet_card.png': _LocaleValue(
    kz: 'Ашықхат',
    ru: 'Открытка',
    en: 'Greeting card',
  ),
  'assets/custom_bouquet/custom_bouquet_balloon.png': _LocaleValue(
    kz: 'Шар',
    ru: 'Шар',
    en: 'Balloon',
  ),
};

const Map<String, _LocaleValue> _pickupStoreNames = {
  'kyz-zhibek': _LocaleValue(
    kz: 'Gul Alem - Қыз Жібек',
    ru: 'Gul Alem - Кыз Жибек',
    en: 'Gul Alem - Kyz Zhibek',
  ),
  'kerey-zhanibek-khandar': _LocaleValue(
    kz: 'Gul Alem - Керей, Жәнібек хандар',
    ru: 'Gul Alem - Керей, Жанибек хандар',
    en: 'Gul Alem - Kerey Zhanibek Khandar',
  ),
  'dinmukhamed-konayev': _LocaleValue(
    kz: 'Gul Alem - Дінмұхамед Қонаев',
    ru: 'Gul Alem - Динмухамед Кунаев',
    en: 'Gul Alem - Dinmukhamed Konayev',
  ),
};

const Map<String, _LocaleValue> _pickupStoreAddresses = {
  'kyz-zhibek': _LocaleValue(
    kz: 'Қыз Жібек көшесі 36, Астана',
    ru: 'улица Кыз Жибек, 36, Астана',
    en: 'Kyz Zhibek Street 36, Astana',
  ),
  'kerey-zhanibek-khandar': _LocaleValue(
    kz: 'Керей, Жәнібек хандар көшесі 17, Астана',
    ru: 'улица Керей, Жанибек хандар, 17, Астана',
    en: 'Kerey Zhanibek Khandar Street 17, Astana',
  ),
  'dinmukhamed-konayev': _LocaleValue(
    kz: 'Дінмұхамед Қонаев көшесі 14, Астана',
    ru: 'улица Динмухамеда Кунаева, 14, Астана',
    en: 'Dinmukhamed Konayev Street 14, Astana',
  ),
};

const Map<String, _LocaleValue> _filterOptions = {
  'birthday': _LocaleValue(
    kz: 'Туған күн',
    ru: 'День рождения',
    en: 'Birthday',
  ),
  'love': _LocaleValue(
    kz: 'Махаббат / романтика',
    ru: 'Любовь / романтика',
    en: 'Love / romance',
  ),
  'wedding': _LocaleValue(kz: 'Үйлену тойы', ru: 'Свадьба', en: 'Wedding'),
  'congrats': _LocaleValue(
    kz: 'Құттықтау',
    ru: 'Поздравление',
    en: 'Congratulations',
  ),
  'no_reason': _LocaleValue(
    kz: 'Себепсіз',
    ru: 'Без повода',
    en: 'No occasion',
  ),
  'girl': _LocaleValue(kz: 'Қызға', ru: 'Девушке', en: 'For a girl'),
  'mom': _LocaleValue(kz: 'Анаға', ru: 'Маме', en: 'For mom'),
  'friend': _LocaleValue(kz: 'Құрбыға', ru: 'Подруге', en: 'For a friend'),
  'colleague': _LocaleValue(
    kz: 'Әріптеске',
    ru: 'Коллеге',
    en: 'For a colleague',
  ),
  'universal': _LocaleValue(
    kz: 'Әмбебап',
    ru: 'Универсальный',
    en: 'Universal',
  ),
};

const Map<String, _LocaleValue> _categoryNames = {
  'assets/cat_1.png': _LocaleValue(kz: 'Гүлдер', ru: 'Цветы', en: 'Flowers'),
  'assets/cat_2.png': _LocaleValue(
    kz: 'Букеттер',
    ru: 'Букеты',
    en: 'Bouquets',
  ),
  'assets/cat_3.png': _LocaleValue(kz: 'Раушан', ru: 'Розы', en: 'Roses'),
  'assets/cat_4.png': _LocaleValue(
    kz: 'Қызғалдақ',
    ru: 'Тюльпаны',
    en: 'Tulips',
  ),
  'assets/cat_5.png': _LocaleValue(
    kz: 'Аралас букеттер',
    ru: 'Смешанные букеты',
    en: 'Mixed bouquets',
  ),
  'assets/cat_6.png': _LocaleValue(
    kz: 'Тәтті букеттер',
    ru: 'Сладкие букеты',
    en: 'Sweet bouquets',
  ),
  'assets/cat_7.png': _LocaleValue(kz: 'Сыйлық', ru: 'Подарки', en: 'Gifts'),
  'assets/cat_8.png': _LocaleValue(
    kz: 'Жеуге жарамды',
    ru: 'Съедобные',
    en: 'Edible gifts',
  ),
  'assets/cat_9.png': _LocaleValue(kz: 'Шарлар', ru: 'Шары', en: 'Balloons'),
  'assets/cat_10.png': _LocaleValue(kz: 'Өзім', ru: 'Свой', en: 'DIY'),
};

const Map<String, _LocaleValue> _productNames = {
  'assets/flower_rose_red.png': _LocaleValue(
    kz: 'Қызыл раушан',
    ru: 'Красная роза',
    en: 'Red rose',
  ),
  'assets/flower_rose_white.png': _LocaleValue(
    kz: 'Ақ раушан',
    ru: 'Белая роза',
    en: 'White rose',
  ),
  'assets/flower_peony_pink.png': _LocaleValue(
    kz: 'Қызғылт пион',
    ru: 'Розовый пион',
    en: 'Pink peony',
  ),
  'assets/flower_peony_white.png': _LocaleValue(
    kz: 'Ақ пион',
    ru: 'Белый пион',
    en: 'White peony',
  ),
  'assets/flower_lily.png': _LocaleValue(kz: 'Лилия', ru: 'Лилия', en: 'Lily'),
  'assets/flower_hydrangea.png': _LocaleValue(
    kz: 'Гортензия',
    ru: 'Гортензия',
    en: 'Hydrangea',
  ),
  'assets/flower_chrysanthemum.png': _LocaleValue(
    kz: 'Хризантема',
    ru: 'Хризантема',
    en: 'Chrysanthemum',
  ),
  'assets/flower_daisylike_chrysanthemum.png': _LocaleValue(
    kz: 'Түймедақ хризантема',
    ru: 'Ромашковая хризантема',
    en: 'Daisy chrysanthemum',
  ),
  'assets/flower_mixed.png': _LocaleValue(
    kz: 'Аралас букет',
    ru: 'Смешанный букет',
    en: 'Mixed bouquet',
  ),
  'assets/product_candy_bouquet.png': _LocaleValue(
    kz: 'Тәтті букеті',
    ru: 'Сладкий букет',
    en: 'Candy bouquet',
  ),
  'assets/product_fruit_bouquet.png': _LocaleValue(
    kz: 'Жеміс букеті',
    ru: 'Фруктовый букет',
    en: 'Fruit bouquet',
  ),
  'assets/product_money_bouquet.png': _LocaleValue(
    kz: 'Ақша букеті',
    ru: 'Денежный букет',
    en: 'Money bouquet',
  ),
  'assets/product_bear_bouquet.png': _LocaleValue(
    kz: 'Аю букеті',
    ru: 'Букет с мишкой',
    en: 'Bear bouquet',
  ),
  'assets/product_flower_umbrella1.png': _LocaleValue(
    kz: 'Гүл қолшатырлары',
    ru: 'Цветочные зонты',
    en: 'Flower umbrellas',
  ),
  'assets/product_flower_umbrella2.png': _LocaleValue(
    kz: 'Гүл қолшатырлары (2)',
    ru: 'Цветочные зонты (2)',
    en: 'Flower umbrellas (2)',
  ),
  'assets/flower_tulip_pink.png': _LocaleValue(
    kz: 'Қызғалдақ (қызғылт)',
    ru: 'Тюльпан (розовый)',
    en: 'Tulip (pink)',
  ),
  'assets/flower_tulip_yellow.png': _LocaleValue(
    kz: 'Қызғалдақ (сары)',
    ru: 'Тюльпан (желтый)',
    en: 'Tulip (yellow)',
  ),
  'assets/product_balloons_birthday.png': _LocaleValue(
    kz: 'Шарлар (мерекелік)',
    ru: 'Шары (праздничные)',
    en: 'Balloons (birthday)',
  ),
  'assets/product_balloons_standart.png': _LocaleValue(
    kz: 'Шарлар (классикалық)',
    ru: 'Шары (классические)',
    en: 'Balloons (classic)',
  ),
};
