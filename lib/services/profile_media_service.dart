import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileMediaService {
  ProfileMediaService({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _db = db ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  Future<ImageSource?> chooseSource(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from library'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> pickFromSheet(BuildContext context) async {
    final source = await chooseSource(context);
    if (source == null) return null;
    try {
      return await pickAndUploadAvatar(source: source);
    } on StateError catch (e) {
      if (e.message == 'cancelled') return null;
      rethrow;
    }
  }

  Future<String> pickAndUploadAvatar({
    ImageSource source = ImageSource.gallery,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to update your photo');
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) throw StateError('cancelled');
    final bytes = await picked.readAsBytes();
    return uploadAvatar(bytes);
  }

  Future<String> uploadAvatar(Uint8List bytes) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to update your photo');
    if (bytes.length > 8 * 1024 * 1024) {
      throw StateError('Photo must be under 8 MB');
    }
    final path = 'users/${user.uid}/avatar/profile.jpg';
    await _storage
        .ref(path)
        .putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await _storage.ref(path).getDownloadURL();
    await user.updatePhotoURL(url);
    await _db.collection('users').doc(user.uid).set({
      'photoUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return url;
  }
}
