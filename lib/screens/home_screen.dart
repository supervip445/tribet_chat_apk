import 'package:dhamma_apk/widgets/cards/dhamma_card.dart';
import 'package:dhamma_apk/widgets/cards/post_card.dart';
import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/dhamma.dart';
import '../services/public_service.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/banner_slider.dart';
import '../widgets/marquee_text.dart';
import '../widgets/sidebar.dart';
import '../widgets/chat/chat_icon.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PublicService _publicService = PublicService();
  List<Post> _posts = [];
  List<Dhamma> _dhammas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    dynamic postsResponse;
    dynamic dhammasResponse;

    try {
      postsResponse = await _publicService.getPosts(1);
      dhammasResponse = await _publicService.getDhammas(1);

      if (mounted) {
        setState(() {
          final postsData = postsResponse['data'] ?? [];
          final dhammasData = dhammasResponse['data'] ?? [];

          _posts = (postsData is List)
              ? postsData.map((item) => Post.fromJson(item)).toList()
              : [];

          _dhammas = (dhammasData is List)
              ? dhammasData.map((item) => Dhamma.fromJson(item)).take(6).toList()
              : [];

          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      debugPrint('Posts response: $postsResponse');
      debugPrint('Dhammas response: $dhammasResponse');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      drawer: const Sidebar(),
      backgroundColor: const Color(0xFFFFF8E1),
      body: Stack(
        children: [
          Column(
            children: [
              const MarqueeText(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const BannerSlider(),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFFB300),
                              ),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 32.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Recent Posts
                              const Padding(
                                padding: EdgeInsets.only(bottom: 24.0),
                                child: Text(
                                  'Recent Posts',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF424242),
                                  ),
                                ),
                              ),
                              if (_posts.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Center(
                                    child: Text(
                                      'No posts available',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    int crossAxisCount;
                                    if (constraints.maxWidth >= 1200) {
                                      crossAxisCount = 4;
                                    } else if (constraints.maxWidth >= 900) {
                                      crossAxisCount = 3;
                                    } else if (constraints.maxWidth >= 600) {
                                      crossAxisCount = 2;
                                    } else {
                                      crossAxisCount = 1;
                                    }

                                    const double spacing = 24;
                                    final double itemWidth = (constraints.maxWidth -
                                            spacing * (crossAxisCount - 1)) /
                                        crossAxisCount;

                                    return Wrap(
                                      spacing: spacing,
                                      runSpacing: spacing,
                                      children: _posts.map((post) {
                                        return SizedBox(
                                          width: itemWidth,
                                          child: PostCard(post: post),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              const SizedBox(height: 48),
                              // Recent Dhamma Talks
                              const Padding(
                                padding: EdgeInsets.only(bottom: 24.0),
                                child: Text(
                                  'Recent Dhamma Talks',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF424242),
                                  ),
                                ),
                              ),
                              if (_dhammas.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Center(
                                    child: Text(
                                      'No dhamma talks available',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    int crossAxisCount;
                                    if (constraints.maxWidth >= 1200) {
                                      crossAxisCount = 4;
                                    } else if (constraints.maxWidth >= 900) {
                                      crossAxisCount = 3;
                                    } else if (constraints.maxWidth >= 600) {
                                      crossAxisCount = 2;
                                    } else {
                                      crossAxisCount = 1;
                                    }

                                    const double spacing = 24;
                                    final double itemWidth = (constraints.maxWidth -
                                            spacing * (crossAxisCount - 1)) /
                                        crossAxisCount;

                                    return Wrap(
                                      spacing: spacing,
                                      runSpacing: spacing,
                                      children: _dhammas.map((dhamma) {
                                        return SizedBox(
                                          width: itemWidth,
                                          child: DhammaCard(dhamma: dhamma),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const ChatIcon(),
        ],
      ),
    );
  }
}
