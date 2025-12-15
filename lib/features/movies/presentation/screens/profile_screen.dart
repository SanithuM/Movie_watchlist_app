// User profile screen showing avatar, watched and rated movies.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/movie_model.dart';
import '../providers/wishlist_provider.dart';
import '../providers/profile_provider.dart';
import 'details_screen.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // Returns NULL if no image
  ImageProvider? _getImageProvider(String? imageString) {
    if (imageString == null || imageString.isEmpty) {
      return null;
    }
    // Base64 Check
    if (imageString.length > 500) {
      try {
        return MemoryImage(base64Decode(imageString));
      } catch (e) {
        return null;
      }
    }
    if (imageString.startsWith('http')) return NetworkImage(imageString);
    final file = File(imageString);
    return file.existsSync() ? FileImage(file) : null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final wishlist = ref.watch(wishlistProvider);
    final ratedMovies = wishlist.where((m) => m.myRating != null).toList();
    final watchedMovies = wishlist.where((m) => m.isWatched).toList();

    // Get providers
    final bannerProvider = _getImageProvider(profileState.bannerPath);
    final avatarProvider = _getImageProvider(profileState.avatarPath);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 280,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // BANNER
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      image: bannerProvider != null
                          ? DecorationImage(image: bannerProvider, fit: BoxFit.cover)
                          : null,
                    ),
                    // Show a solid color overlay if image exists, or just dark grey if not
                    child: bannerProvider != null 
                        ? Container(color: Colors.black.withOpacity(0.4)) 
                        : null,
                  ),

                  // SETTINGS ICON
                  Positioned(
                    top: 50,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                      },
                    ),
                  ),

                  // AVATAR
                  Positioned(
                    top: 160,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: avatarProvider,
                        // Show Icon if no image
                        child: avatarProvider == null 
                            ? const Icon(Icons.person, size: 60, color: Colors.white54) 
                            : null,
                      ),
                    ),
                  ),

                  // NAME & EDIT BUTTON
                  Positioned(
                    top: 230,
                    left: 150,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          profileState.name,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 32,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                            ),
                            child: const Text('Edit'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _buildSectionHeader("Watched Movies"),
            _buildHorizontalList(context, watchedMovies),
            const SizedBox(height: 20),
            _buildSectionHeader("Rated Movies"),
            _buildHorizontalList(context, ratedMovies, isRatedSection: true),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // Helper Methods (Same as before)
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        ],
      ),
    );
  }

  Widget _buildHorizontalList(BuildContext context, List<Movie> movies, {bool isRatedSection = false}) {
    if (movies.isEmpty) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        child: Text("No movies ${isRatedSection ? 'rated' : 'watched'} yet", style: const TextStyle(color: Colors.grey)),
      );
    }
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailScreen(movie: movie))),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 110,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      movie.posterPath,
                      height: 140,
                      width: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey[800], height: 140),
                    ),
                  ),
                  if (isRatedSection) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          movie.myRating?.toStringAsFixed(1) ?? "0.0",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}