import 'package:get/get.dart';
import '../controllers/dealer_controller.dart';
import '../controllers/ledger_controller.dart';
import '../controllers/ocr_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(DealerController(), permanent: true);
    Get.put(LedgerController(), permanent: true);
    Get.put(OcrController(), permanent: true);
  }
}
