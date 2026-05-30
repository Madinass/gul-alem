import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gul_alem/admin_products_screen.dart';
import 'package:gul_alem/app_language.dart';

void main() {
  Future<List<FlutterErrorDetails>> pumpAdminProductsScreen(
    WidgetTester tester,
  ) async {
    final languageController = AppLanguageController();
    final previousOnError = FlutterError.onError;
    final flutterErrors = <FlutterErrorDetails>[];

    FlutterError.onError = (details) {
      flutterErrors.add(details);
    };

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = previousOnError;
      languageController.dispose();
    });

    await tester.pumpWidget(
      AppLanguageScope(
        controller: languageController,
        child: MaterialApp(
          home: AdminProductsScreen(
            fetchProducts: () async => [],
            fetchCategories: () async => [],
            fetchFlowerTypes: () async => [],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    return flutterErrors;
  }

  testWidgets('product editor fits a phone viewport without overflow', (
    tester,
  ) async {
    final flutterErrors = await pumpAdminProductsScreen(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      flutterErrors.where(
        (details) => details.exceptionAsString().contains('overflowed'),
      ),
      isEmpty,
    );
  });

  testWidgets('product editor can be dismissed with back without errors', (
    tester,
  ) async {
    final flutterErrors = await pumpAdminProductsScreen(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AlertDialog), findsNothing);
    expect(flutterErrors, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('product editor cancel button closes without errors', (
    tester,
  ) async {
    final flutterErrors = await pumpAdminProductsScreen(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Бас тарту'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AlertDialog), findsNothing);
    expect(flutterErrors, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog setup dialogs cancel without errors', (tester) async {
    final flutterErrors = await pumpAdminProductsScreen(tester);

    await tester.tap(find.text('Санат қосу'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Бас тарту'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.text('Гүл түрін қосу'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Бас тарту'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AlertDialog), findsNothing);
    expect(flutterErrors, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
