import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';

final welcomePostersProvider = FutureProvider<List<String>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final results = await Future.wait([
      api.fetchTrendingMovies(),
      api.fetchTrendingTvShows(),
    ]);

    final List<String> posters = [];
    final movies = results[0];
    final tvShows = results[1];

    final maxCount = movies.length > tvShows.length ? movies.length : tvShows.length;
    for (int i = 0; i < maxCount; i++) {
      if (i < movies.length) {
        final path = movies[i]['poster_path'] as String?;
        if (path != null && path.isNotEmpty) {
          posters.add('https://image.tmdb.org/t/p/w500$path');
        }
      }
      if (i < tvShows.length) {
        final path = tvShows[i]['poster_path'] as String?;
        if (path != null && path.isNotEmpty) {
          posters.add('https://image.tmdb.org/t/p/w500$path');
        }
      }
    }
    return posters;
  } catch (e) {
    print('Error fetching welcome posters from API: $e');
    return [];
  }
});

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  // Columns of local fallback poster URLs
  final List<String> _fallbackColumn1 = [
    'https://image.tmdb.org/t/p/w500/cvhNj491IIu5uqK7Pwtj5jF786u.jpg', // Rick and Morty
    'https://image.tmdb.org/t/p/w500/or06eK0nOOggkZTMwHMTs4PXtMa.jpg', // Avengers
    'https://image.tmdb.org/t/p/w500/4657155VqBszf65hU5HspK861vO.jpg', // Mushoku Tensei
    'https://image.tmdb.org/t/p/w500/9641il5BeFwb7564T7G564eg4N7.jpg', // X-Men '97
    'https://image.tmdb.org/t/p/w500/x2peo46A1Pz47x0wzV47FfL8Fm3.jpg', // Demon Slayer
  ];

  final List<String> _fallbackColumn2 = [
    'https://image.tmdb.org/t/p/w500/cMD9eVgcwzaCo5WstZOR93nuFd1.jpg', // One Piece
    'https://image.tmdb.org/t/p/w500/pIkRy2Il25fg5QI4Bx4IGw631eG.jpg', // Thor: Love and Thunder
    'https://image.tmdb.org/t/p/w500/oE67U08QzrbtyfsUIapGj1TKlMw.jpg', // Wednesday
    'https://image.tmdb.org/t/p/w500/h66Q1v4C5N496C147nQo6ZlD6C8.jpg', // Attack on Titan
    'https://image.tmdb.org/t/p/w500/ztkUQv65129vHgEvN56y4r79xJ1.jpg', // Breaking Bad
  ];

  final List<String> _fallbackColumn3 = [
    'https://image.tmdb.org/t/p/w500/gEU2Qv4w3Fg7vTT9xg0EFbgIm2v.jpg', // Interstellar
    'https://image.tmdb.org/t/p/w500/iiZZN6m3b6HgaPWGJ8e4w3wF3El.jpg', // Spider-Verse
    'https://image.tmdb.org/t/p/w500/uKVKSj6n389Z5OI71ui7sOIsw6B.jpg', // The Last of Us
    'https://image.tmdb.org/t/p/w500/z2yJ16mt224q4jGz7nzo7e7u063.jpg', // House of the Dragon
    'https://image.tmdb.org/t/p/w500/1XS1nmaNUBc2444r9y6Ooii5OCB.jpg', // Game of Thrones
  ];

  void _showAuthBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top notch line
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to CineList',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join the community and start tracking now!',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),
                // Create account button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/signup');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD200),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'CREATE ACCOUNT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Log in button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/login');
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24, width: 1.5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'LOG IN',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final postersAsync = ref.watch(welcomePostersProvider);

    // Default fallback columns
    List<String> col1 = _fallbackColumn1;
    List<String> col2 = _fallbackColumn2;
    List<String> col3 = _fallbackColumn3;

    if (postersAsync.hasValue && postersAsync.value!.isNotEmpty) {
      final allPosters = postersAsync.value!;
      final tempCol1 = <String>[];
      final tempCol2 = <String>[];
      final tempCol3 = <String>[];

      for (int i = 0; i < allPosters.length; i++) {
        if (i % 3 == 0) {
          tempCol1.add(allPosters[i]);
        } else if (i % 3 == 1) {
          tempCol2.add(allPosters[i]);
        } else {
          tempCol3.add(allPosters[i]);
        }
      }

      // Ensure each column has enough posters to scroll smoothly
      if (tempCol1.length >= 3 && tempCol2.length >= 3 && tempCol3.length >= 3) {
        col1 = tempCol1;
        col2 = tempCol2;
        col3 = tempCol3;
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Background scrolling columns
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: _ScrollingPosterColumn(
                    key: ValueKey('welcome_col1_${col1.join()}'),
                    posters: col1,
                    scrollUp: false,
                    speed: 0.25,
                  ),
                ),
                Expanded(
                  child: _ScrollingPosterColumn(
                    key: ValueKey('welcome_col2_${col2.join()}'),
                    posters: col2,
                    scrollUp: true,
                    speed: 0.20,
                  ),
                ),
                Expanded(
                  child: _ScrollingPosterColumn(
                    key: ValueKey('welcome_col3_${col3.join()}'),
                    posters: col3,
                    scrollUp: false,
                    speed: 0.25,
                  ),
                ),
              ],
            ),
          ),

          // 2. Translucent dark overlays
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.60),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black87,
                    Colors.transparent,
                    Colors.black,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.5, 0.95],
                ),
              ),
            ),
          ),

          // 3. Main Content
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top App Header
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD200),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Center(
                              child: Text(
                                'C',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'CINELIST',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Centered Call to Action
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Thumbs up circular badge
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.thumb_up_alt_rounded,
                              size: 36,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            'Help make your favorite shows even better',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Bottom Buttons
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () => _showAuthBottomSheet(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD200),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              'SIGN UP / LOG IN',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'CineList is a community-driven database for track records.\nBy continuing, you agree to our Terms.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Stateful scrolling column widget
class _ScrollingPosterColumn extends StatefulWidget {
  final List<String> posters;
  final bool scrollUp;
  final double speed;

  const _ScrollingPosterColumn({
    super.key,
    required this.posters,
    required this.scrollUp,
    required this.speed,
  });

  @override
  State<_ScrollingPosterColumn> createState() => _ScrollingPosterColumnState();
}

class _ScrollingPosterColumnState extends State<_ScrollingPosterColumn> {
  late ScrollController _scrollController;
  late double _offset;
  late List<String> _duplicatedPosters;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Triple the posters list to enable smooth wrapping
    _duplicatedPosters = [
      ...widget.posters,
      ...widget.posters,
      ...widget.posters,
    ];

    _offset = widget.scrollUp ? 800.0 : 200.0;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_offset);
      }
      _tick();
    });
  }

  void _tick() {
    if (!mounted) return;
    if (_scrollController.hasClients) {
      final max = _scrollController.position.maxScrollExtent;
      if (widget.scrollUp) {
        _offset -= widget.speed;
        if (_offset <= max * 0.1) {
          _offset = max * 0.5;
        }
      } else {
        _offset += widget.speed;
        if (_offset >= max * 0.9) {
          _offset = max * 0.5;
        }
      }
      _scrollController.jumpTo(_offset);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _duplicatedPosters.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.all(3.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              _duplicatedPosters[index],
              fit: BoxFit.cover,
              height: 160,
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                color: Colors.grey[900],
                child: const Icon(Icons.tv, color: Colors.grey),
              ),
            ),
          ),
        );
      },
    );
  }
}
