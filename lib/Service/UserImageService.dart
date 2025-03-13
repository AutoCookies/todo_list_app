import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserImageService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> uploadUserProfileImage(File imageFile) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      String uid = user.uid;
      String filePath = 'user_images/$uid.jpg';
      Reference ref = _storage.ref().child(filePath);

      // Xóa ảnh cũ trước khi tải ảnh mới
      await _deleteOldProfileImage(uid);

      // Upload ảnh mới
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Cập nhật URL ảnh mới vào Firestore
      await _firestore.collection('users').doc(uid).update({
        'profileImage': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      print("Lỗi upload ảnh: $e");
      return null;
    }
  }

  Future<void> _deleteOldProfileImage(String uid) async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('users').doc(uid).get();
      if (snapshot.exists) {
        String? oldImageUrl = snapshot['profileImage'];
        if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
          Reference oldRef = _storage.refFromURL(oldImageUrl);
          await oldRef.delete(); // Xóa ảnh cũ khỏi Firebase Storage
        }
      }
    } catch (e) {
      print("Lỗi xóa ảnh cũ: $e");
    }
  }

  Future<String?> getUserProfileImage() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      DocumentSnapshot snapshot = await _firestore.collection('users').doc(user.uid).get();
      return snapshot['profileImage'];
    } catch (e) {
      print("Lỗi lấy ảnh: $e");
      return null;
    }
  }
}
