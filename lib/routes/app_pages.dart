import 'package:get/get.dart';
import '../views/splash_screen.dart';
import '../views/dashboard_screen.dart';
import '../views/dealer_list_screen.dart';
import '../views/add_dealer_screen.dart';
import '../views/dealer_ledger_screen.dart';
import '../views/scan_bill_screen.dart';
import '../views/add_payment_screen.dart';
import '../views/reports_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.dashboard, page: () => const DashboardScreen()),
    GetPage(name: AppRoutes.dealerList, page: () => const DealerListScreen()),
    GetPage(name: AppRoutes.addDealer, page: () => const AddDealerScreen()),
    GetPage(name: AppRoutes.editDealer, page: () => const AddDealerScreen()),
    GetPage(name: AppRoutes.dealerLedger, page: () => const DealerLedgerScreen()),
    GetPage(name: AppRoutes.scanBill, page: () => const ScanBillScreen()),
    GetPage(name: AppRoutes.addPayment, page: () => const AddPaymentScreen()),
    GetPage(name: AppRoutes.reports, page: () => const ReportsScreen()),
  ];
}
