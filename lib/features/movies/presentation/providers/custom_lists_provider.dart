import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomListItem {
  final String id;
  final String title;
  final String posterPath;
  final String type; // 'movie' or 'tv'

  CustomListItem({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.type,
  });

  factory CustomListItem.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return CustomListItem(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      posterPath: map['posterPath'] ?? '',
      type: map['type'] ?? 'movie',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'posterPath': posterPath,
      'type': type,
    };
  }
}

class CustomList {
  final String id;
  final String name;
  final List<CustomListItem> items;
  final DateTime createdAt;

  CustomList({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
  });

  factory CustomList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CustomList(
      id: doc.id,
      name: data['name'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => CustomListItem.fromJson(item))
              .toList() ??
          [],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class CustomListsNotifier extends StreamNotifier<List<CustomList>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Stream<List<CustomList>> build() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('lists')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomList.fromFirestore(doc))
            .toList());
  }

  Future<void> createList(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('lists')
        .doc();

    final newList = CustomList(
      id: docRef.id,
      name: name,
      items: [],
      createdAt: DateTime.now(),
    );

    await docRef.set(newList.toJson());
  }

  Future<void> deleteList(String listId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('lists')
        .doc(listId)
        .delete();
  }

  Future<void> toggleItemInList({
    required String listId,
    required String itemId,
    required String title,
    required String posterPath,
    required String type,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('lists')
        .doc(listId);

    final doc = await docRef.get();
    if (!doc.exists) return;

    final currentList = CustomList.fromFirestore(doc);
    final items = List<CustomListItem>.from(currentList.items);

    final existingIndex = items.indexWhere((item) => item.id == itemId && item.type == type);
    if (existingIndex >= 0) {
      items.removeAt(existingIndex);
    } else {
      items.add(CustomListItem(
        id: itemId,
        title: title,
        posterPath: posterPath,
        type: type,
      ));
    }

    await docRef.update({
      'items': items.map((item) => item.toJson()).toList(),
    });
  }
}

final customListsProvider =
    StreamNotifierProvider<CustomListsNotifier, List<CustomList>>(() {
  return CustomListsNotifier();
});
