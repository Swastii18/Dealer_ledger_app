import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class OcrController extends GetxController {
  final ImagePicker _picker = ImagePicker();

  final RxBool isProcessing = false.obs;
  final Rx<File?> selectedImage = Rx<File?>(null);

  void reset() {
    selectedImage.value = null;
  }

  Future<void> pickFromCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked != null) {
      selectedImage.value = File(picked.path);
    }
  }

  Future<void> pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      selectedImage.value = File(picked.path);
    }
  }
}
