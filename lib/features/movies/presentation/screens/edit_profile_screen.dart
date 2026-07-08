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

  // Helper to safely parse image paths (Base64, Network, or File)
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
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text("Edit Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextButton(
                  onPressed: () {
                    profileNotifier.updateDisplayName(_nameController.text.trim());
                    Navigator.pop(context);
                  },
                  child: const Text("SAVE", style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- VISUAL HEADER EDITOR ---
                SizedBox(
                  height: 240, // Tall enough to hold banner + overlapping avatar
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. BANNER EDITOR
                      GestureDetector(
                        onTap: () async {
                          await profileNotifier.pickImage(true);
                        },
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            image: bannerProvider != null
                                ? DecorationImage(image: bannerProvider, fit: BoxFit.cover)
                                : null,
                          ),
                          // Dark overlay with Camera Icon
                          child: Container(
                            color: Colors.black.withOpacity(0.5),
                            child: const Center(
                              child: Icon(Icons.camera_alt, color: Colors.white70, size: 40),
                            ),
                          ),
                        ),
                      ),

                      // 2. AVATAR EDITOR
                      Positioned(
                        top: 120, // Overlaps the bottom edge of the banner
                        left: 20,
                        child: GestureDetector(
                          onTap: () async {
                            await profileNotifier.pickImage(false); 
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black, // Creates the cutout effect
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[800],
                              backgroundImage: avatarProvider,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Show Person Icon if no image exists underneath
                                  if (avatarProvider == null)
                                    const Icon(Icons.person, color: Colors.white54, size: 50),
                                  
                                  // Dark overlay with Camera Icon
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.camera_alt, color: Colors.white70, size: 30),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // --- TEXT FIELDS ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Display Name",
                        style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        cursorColor: Colors.amber,
                        decoration: InputDecoration(
                          hintText: "Enter your name",
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.grey[900],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.amber, width: 1.5),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      const Text(
                        "This is how you will appear to other users across CineList.",
                        style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // --- GLOBAL LOADING OVERLAY ---
        // Prevents user from tapping anything else while image is compressing
        if (profileState.isLoading)
          Container(
            color: Colors.black.withOpacity(0.7),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.amber),
                  SizedBox(height: 16),
                  Text("Processing Image...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}