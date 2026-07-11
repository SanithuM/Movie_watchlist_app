import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/cloudinary_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../../../auth/data/auth_service.dart';

class ProfileState {
  final String name;
  final String? bannerPath; // Holds the compressed Base64 string
  final String? avatarPath; // Holds the compressed Base64 string
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

  // Pick Image, Aggressively Compress, & Upload to Cloudinary
  Future<String?> pickImage(bool isBanner) async {
    final user = _auth.currentUser;
    if (user == null) return "User is not logged in.";

    // Set precise boundaries depending on use case to save space.
    // Banners need width but can be shallow; avatars can be quite small squares.
    final double targetWidth = isBanner ? 600 : 250;

    try {
      // Pick Image with low quality and capped resolution constraints
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 25,     // Downsample image quality strictly to lower file size
        maxWidth: targetWidth, // Restrict maximum width dimension
      );
      
      if (image == null) return null; // User cancelled

      state = state.copyWith(isLoading: true);

      // Convert File to Bytes
      final bytes = await image.readAsBytes();
      
      // Enforce a sensible 10MB limit for Cloudinary upload
      if (bytes.length > 10000000) {
        state = state.copyWith(isLoading: false);
        return "Image size exceeds the 10MB limit.";
      }

      // Upload to Cloudinary
      final cloudinaryService = ref.read(cloudinaryServiceProvider);
      final filename = isBanner ? 'banner_${user.uid}.jpg' : 'avatar_${user.uid}.jpg';
      final imageUrl = await cloudinaryService.uploadImage(bytes, filename);

      // Save String to Firestore & Update State
      if (isBanner) {
        state = state.copyWith(bannerPath: imageUrl, isLoading: false);
        await _firestore.collection('users').doc(user.uid).set({
          'banner_image': imageUrl,
        }, SetOptions(merge: true));
      } else {
        state = state.copyWith(avatarPath: imageUrl, isLoading: false);
        await _firestore.collection('users').doc(user.uid).set({
          'avatar_image': imageUrl,
        }, SetOptions(merge: true));
      }
      return null;
    } catch (e) {
      debugPrint("Error picking image: $e");
      state = state.copyWith(isLoading: false);
      return e.toString().replaceAll("Exception: ", "");
    }
  }

  Future<String?> pickGif(bool isBanner) async {
    final user = _auth.currentUser;
    if (user == null) return "User is not logged in.";

    state = state.copyWith(isLoading: true);

    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gif'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        state = state.copyWith(isLoading: false);
        return null; // User cancelled
      }

      final file = result.files.first;
      Uint8List? bytes = file.bytes;

      if (bytes == null && !kIsWeb && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null) {
        state = state.copyWith(isLoading: false);
        return "Could not retrieve GIF file bytes.";
      }

      // Enforce a sensible 10MB limit for Cloudinary upload
      if (bytes.length > 10000000) {
        state = state.copyWith(isLoading: false);
        return "GIF size (${(bytes.length / 1048576).toStringAsFixed(1)} MB) exceeds the 10MB limit.";
      }

      // Upload to Cloudinary
      final cloudinaryService = ref.read(cloudinaryServiceProvider);
      final filename = isBanner ? 'banner_${user.uid}.gif' : 'avatar_${user.uid}.gif';
      final imageUrl = await cloudinaryService.uploadImage(bytes, filename);

      if (isBanner) {
        state = state.copyWith(bannerPath: imageUrl, isLoading: false);
        await _firestore.collection('users').doc(user.uid).set({
          'banner_image': imageUrl,
        }, SetOptions(merge: true));
      } else {
        state = state.copyWith(avatarPath: imageUrl, isLoading: false);
        await _firestore.collection('users').doc(user.uid).set({
          'avatar_image': imageUrl,
        }, SetOptions(merge: true));
      }
      return null;
    } catch (e) {
      debugPrint("Error picking GIF: $e");
      state = state.copyWith(isLoading: false);
      return e.toString().replaceAll("Exception: ", "");
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