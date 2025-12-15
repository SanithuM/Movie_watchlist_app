//Screen to edit user's profile and upload avatar/banner.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;

  ImageProvider? _imageProviderForPath(String? path) {
    if (path == null || path.isEmpty) return null;
    
    // Base64 Check
    if (path.length > 500) {
      try {
        return MemoryImage(base64Decode(path));
      } catch (e) {
        return null;
      }
    }
    
    if (path.startsWith('http')) return NetworkImage(path);
    final file = File(path);
    return file.existsSync() ? FileImage(file) : null;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: ref.read(profileProvider).name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final profileNotifier = ref.read(profileProvider.notifier);

    // Get providers
    final bannerProvider = _imageProviderForPath(profileState.bannerPath);
    final avatarProvider = _imageProviderForPath(profileState.avatarPath);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                onPressed: () {
                  profileNotifier.updateDisplayName(_nameController.text.trim());
                  Navigator.pop(context);
                },
                child: const Text("SAVE", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Profile Photo Picker
                GestureDetector(
                  onTap: () async {
                    await profileNotifier.pickImage(false); 
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: avatarProvider,
                        // Show Person Icon if no image
                        child: avatarProvider == null 
                            ? const Icon(Icons.person, color: Colors.white) 
                            : null,
                      ),
                      const SizedBox(width: 15),
                      const Text("Choose profile photo", style: TextStyle(color: Colors.blue, fontSize: 16)),
                    ],
                  ),
                ),
                const Divider(color: Colors.grey, height: 30),

                // Cover Photo Picker
                GestureDetector(
                  onTap: () async {
                    await profileNotifier.pickImage(true);
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                          image: bannerProvider != null
                              ? DecorationImage(image: bannerProvider, fit: BoxFit.cover)
                              : null,
                        ),
                        // Show Image Icon if no image
                        child: bannerProvider == null 
                            ? const Icon(Icons.image, color: Colors.white) 
                            : null,
                      ),
                      const SizedBox(width: 15),
                      const Text("Choose cover photo", style: TextStyle(color: Colors.blue, fontSize: 16)),
                    ],
                  ),
                ),
                const Divider(color: Colors.grey, height: 30),

                // Display Name
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Display name", style: TextStyle(color: Colors.white, fontSize: 16)),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.blue, fontSize: 18),
                      decoration: const InputDecoration(
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Loading Overlay
        if (profileState.isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}