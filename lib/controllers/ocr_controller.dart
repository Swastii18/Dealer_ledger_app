import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';

class OcrController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();

  final RxBool isProcessing = false.obs;
  final Rx<File?> selectedImage = Rx<File?>(null);

  // Extracted fields — scan screen listens to these
  final RxString extractedBillNo = ''.obs;
  final RxString extractedDate = ''.obs;
  final RxDouble extractedAmount = 0.0.obs;
  final RxBool hasExtraction = false.obs;

  void reset() {
    selectedImage.value = null;
    extractedBillNo.value = '';
    extractedDate.value = '';
    extractedAmount.value = 0.0;
    hasExtraction.value = false;
  }

  Future<void> pickFromCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (picked != null) {
      await _processImage(File(picked.path));
    }
  }

  Future<void> pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked != null) {
      await _processImage(File(picked.path));
    }
  }

  Future<void> _processImage(File file) async {
    selectedImage.value = file;
    isProcessing.value = true;
    try {
      final result = await _ocrService.extractFromImage(file);
      extractedBillNo.value = result.billNo;
      extractedDate.value = result.date;
      extractedAmount.value = result.amount ?? 0.0;
      hasExtraction.value = true;
    } catch (_) {
      hasExtraction.value = false;
    } finally {
      isProcessing.value = false;
    }
  }

}
