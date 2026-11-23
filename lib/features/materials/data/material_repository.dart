import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../domain/material_item.dart';

class MaterialRepository {
  MaterialRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Uuid _uuid = const Uuid();

  Future<List<MaterialItem>> getMaterials(String userId) async {
    final results = await Future.wait([
      _firestore
          .collection('materials')
          .where('uploadedBy', isEqualTo: userId)
          .get(),
      _firestore
          .collection('materials')
          .where('visibility', isEqualTo: 'public')
          .get(),
      _firestore.collection('users').doc(userId).collection('bookmarks').get(),
    ]);
    final bookmarkedIds = results[2].docs
        .map((document) => document.id)
        .toSet();
    final documents = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final document in results[0].docs) {
      documents[document.id] = document;
    }
    for (final document in results[1].docs) {
      documents[document.id] = document;
    }
    final materials =
        documents.values
            .map(
              (document) => _fromDocument(
                document,
                isBookmarked: bookmarkedIds.contains(document.id),
              ),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return materials;
  }

  Future<void> upload({
    required String userId,
    required String title,
    required String subject,
    required String description,
    required PlatformFile file,
  }) async {
    final extension = file.extension?.toLowerCase();
    if (extension != 'pdf' && extension != 'txt') {
      throw const MaterialFailure('Choose a PDF or TXT file.');
    }
    final size = await file.length();
    if (size == null) {
      throw const MaterialFailure(
        'Could not determine the selected file size.',
      );
    }
    if (size > 20 * 1024 * 1024) {
      throw const MaterialFailure('The maximum file size is 20 MB.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const MaterialFailure('Could not read the selected file.');
    }

    final id = _uuid.v4();
    final contentType = extension == 'pdf' ? 'application/pdf' : 'text/plain';
    final storagePath = 'materials/$userId/$id/document.$extension';
    final storageRef = _storage.ref(storagePath);
    try {
      await storageRef.putData(
        bytes,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {'visibility': 'private'},
        ),
      );
      final fileUrl = await storageRef.getDownloadURL();
      await _firestore.collection('materials').doc(id).set({
        'title': title.trim(),
        'description': description.trim(),
        'subject': subject.trim(),
        'fileName': file.name,
        'fileType': extension,
        'fileSize': size,
        'fileUrl': fileUrl,
        'storagePath': storagePath,
        'uploadedBy': userId,
        'visibility': 'private',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      try {
        await storageRef.delete();
      } on FirebaseException {
        // Keep the original upload or Firestore error for the user.
      }
      throw MaterialFailure(
        error.code == 'permission-denied'
            ? 'Upload was denied. Check your Firebase Storage and Firestore rules.'
            : 'Could not upload this file. Check your connection and try again.',
      );
    }
  }

  Future<void> toggleBookmark({
    required String userId,
    required MaterialItem material,
  }) async {
    final bookmark = _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(material.id);
    if (material.isBookmarked) {
      await bookmark.delete();
    } else {
      await bookmark.set({
        'materialId': material.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> delete({
    required String userId,
    required MaterialItem material,
  }) async {
    if (material.uploadedBy != userId) {
      throw const MaterialFailure('You can only delete your own uploads.');
    }
    final data = await _firestore
        .collection('materials')
        .doc(material.id)
        .get();
    final storagePath = data.data()?['storagePath'] as String?;
    if (storagePath != null) {
      await _storage.ref(storagePath).delete();
    }
    await _firestore.collection('materials').doc(material.id).delete();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(material.id)
        .delete();
  }

  MaterialItem _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document, {
    required bool isBookmarked,
  }) {
    final data = document.data();
    final timestamp = data['createdAt'];
    return MaterialItem(
      id: document.id,
      title: data['title'] as String? ?? 'Untitled material',
      description: data['description'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      fileName: data['fileName'] as String? ?? '',
      fileType: data['fileType'] as String? ?? '',
      fileSize: data['fileSize'] as int? ?? 0,
      fileUrl: data['fileUrl'] as String? ?? '',
      uploadedBy: data['uploadedBy'] as String? ?? '',
      isBookmarked: isBookmarked,
      createdAt: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
    );
  }
}
