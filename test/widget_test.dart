import 'package:dealer_ledger_app/views/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('Splash screen shows app identity', (tester) async {
    Get.testMode = true;
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const SplashScreen()),
          GetPage(
            name: '/dashboard',
            page: () => const Scaffold(body: Text('Dashboard')),
          ),
        ],
      ),
    );

    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    expect(find.text('Dealer Ledger'), findsOneWidget);
    expect(find.text('Track bills. Manage dues.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    Get.reset();
  });
}
