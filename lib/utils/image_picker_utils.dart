import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

// Hàm chọn ảnh từ thư viện
Future<File?> pickImage() async {
  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    return File(pickedFile.path);
  }
  return null;
}

// Hàm lưu đường dẫn ảnh vào SharedPreferences
Future<void> saveImagePath(String path) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('profile_image', path);
}

// Hàm tải ảnh đã lưu
Future<File?> loadSavedImage() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? imagePath = prefs.getString('profile_image');

  if (imagePath != null && File(imagePath).existsSync()) {
    return File(imagePath);
  }
  return null;
}

// Hàm xóa ảnh cũ trước khi lưu ảnh mới
Future<void> deleteOldImage() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? oldImagePath = prefs.getString('profile_image');

  if (oldImagePath != null) {
    File oldImage = File(oldImagePath);
    if (await oldImage.exists()) {
      await oldImage.delete();
      prefs.remove('profile_image'); // Xóa đường dẫn trong SharedPreferences
    }
  }
}

// Hàm lưu ảnh vào bộ nhớ thiết bị
Future<File> saveImage(File image) async {
  await deleteOldImage(); // Xóa ảnh cũ trước khi lưu ảnh mới

  final appDir = await getApplicationDocumentsDirectory();
  final fileName = 'profile_image.png';
  final savedImage = await image.copy('${appDir.path}/$fileName');

  return savedImage;
}
