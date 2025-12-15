//Profile state & notifier (avatar/banner, name) with Hive/Firestore sync.
import 'dart:convert'; // Import this for Base64
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/data/auth_service.dart';


class ProfileState {
  final String name;
  final String? bannerPath; // This will now hold a huge Base64 string
  final String? avatarPath; // This will now hold a huge Base64 string
  final bool isLoading;

  ProfileState({
    this.name = "User",
    this.bannerPath,
    this.avatarPath,
    this.isLoading = false,
  });

  ProfileState copyWith({
    String? name,
    String? bannerPath,
    String? avatarPath,
    bool? isLoading,
  }) {
    return ProfileState(
      name: name ?? this.name,
      bannerPath: bannerPath ?? this.bannerPath,
      avatarPath: avatarPath ?? this.avatarPath,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _boxName = 'profile_box';

  @override
  ProfileState build() {
    // Initialize and trigger loading of saved profile data.
    ref.watch(authStateProvider);
    _loadProfile();
    return ProfileState();
  }

  Future<void> _loadProfile() async {
    // Load profile from Hive and Firestore into state.
    if (!Hive.isBoxOpen(_boxName)) await Hive.openBox(_boxName);
    final box = Hive.box(_boxName);
    final user = _auth.currentUser;

    String defaultName = "User";
    if (user != null && user.email != null) {
      defaultName = user.email!.split('@')[0];
    }

    state = ProfileState(name: box.get('name', defaultValue: defaultName));

    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          state = state.copyWith(
            name: data['name'] ?? state.name,
            bannerPath: data['banner_image'], // Loading Base64 string
            avatarPath: data['avatar_image'], // Loading Base64 string
          );
          if (data['name'] != null) box.put('name', data['name']);
        }
      } catch (e) {
        debugPrint('Error loading profile: $e');
      }
    }
  }

  Future<void> updateDisplayName(String newName) async {
    // Update display name locally and sync to Firestore.
    state = state.copyWith(name: newName);
    final box = Hive.box(_boxName);
    box.put('name', newName);

    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'name': newName,
      }, SetOptions(merge: true));
    }
  }

  //  Pick Image & Convert to Base64 String 
  Future<void> pickImage(bool isBanner) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Pick Image with lower quality to save database space
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Compress image to 50% quality
      maxWidth: 800,    // Resize width
    );
    
    if (image == null) return;

    state = state.copyWith(isLoading: true);

    try {
      // 2. Convert File to Bytes, then to Base64 String
      final bytes = await File(image.path).readAsBytes();
      String base64Image = base64Encode(bytes);

      // 3. Save String to Firestore & Update State
      if (isBanner) {
        state = state.copyWith(bannerPath: base64Image, isLoading: false);
        await _firestore.collection('users').doc(user.uid).set({
          'banner_image': base64Image,
        }, SetOptions(merge: true));
      } else {
        state = state.copyWith(avatarPath: base64Image, isLoading: false);
        await _firestore.collection('users').doc(user.uid).set({
          'avatar_image': base64Image,
        }, SetOptions(merge: true));
      }

    } catch (e) {
      debugPrint("Error encoding image: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> deleteUserData() async {
    // Remove user data from Firestore and clear local profile box.
     final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).delete();
    }
    final box = Hive.box(_boxName);
    await box.clear();
    state = ProfileState(name: "User");
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(() => ProfileNotifier());