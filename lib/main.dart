//App entrypoint — initializes Firebase, Hive, and runs the app.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'core/services/local_storage_service.dart';
import 'app.dart';

void main() async {
  // Ensure Flutter bindings are ready
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize the Local Storage Service (Hive)
  final localStorage = LocalStorageService();
  await localStorage.init();

  // Open the Hive box for profile images
  await Hive.openBox('profile_box');

  // Run the App wrapped in ProviderScope (Required for Riverpod)
  runApp(const ProviderScope(child: MyApp()));
}
