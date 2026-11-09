import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Upload profile photo to Firebase Storage and return download URL.
Future<String> uploadProfileImage({
  required String role,
  required String uid,
  required File file,
}) async {
  final ref = FirebaseStorage.instance
      .ref('profile_images/$role/$uid/profile.jpg');
  await ref.putFile(
    file,
    SettableMetadata(contentType: 'image/jpeg'),
  );
  return ref.getDownloadURL();
}

Future<File?> pickProfileImageFile() async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
  );
  if (picked == null) return null;
  return File(picked.path);
}

String profilePhotoUploadErrorMessage(Object e) {
  final msg = e.toString().toLowerCase();
  if (msg.contains('unauthorized') || msg.contains('permission')) {
    return 'Upload blocked by Storage rules. Publish rules for profile_images/{role}/{userId}/{fileName}.';
  }
  if (msg.contains('bucket')) {
    return 'Storage bucket missing. Restart the app after setting FIREBASE_STORAGE_BUCKET in .env.';
  }
  return 'Could not upload photo: $e';
}

String? profileImageUrlFrom(Map<String, dynamic>? data) {
  if (data == null) return null;
  final url = (data['profile_image_url'] as String?)?.trim();
  if (url != null && url.isNotEmpty) return url;
  final legacy = (data['photo_url'] as String?)?.trim();
  if (legacy != null && legacy.isNotEmpty) return legacy;
  return null;
}
