import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madina/register.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Register screen UI test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterScreen(),
      ),
    );

    
    await tester.pump();

    expect(
      find.text("Тіркеліп, жақыныңызды қуантыңыз!"),
      findsOneWidget,
    );

    expect(find.byType(TextField), findsNWidgets(5));
    expect(find.text("Тіркелуден өту"), findsOneWidget);
  });
}
