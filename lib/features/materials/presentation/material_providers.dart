import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/material_repository.dart';
import '../domain/material_item.dart';

final materialRepositoryProvider = Provider<MaterialRepository>((ref) {
  return MaterialRepository(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
  );
});

final materialsProvider = FutureProvider.family<List<MaterialItem>, String>((
  ref,
  userId,
) {
  return ref.watch(materialRepositoryProvider).getMaterials(userId);
});
