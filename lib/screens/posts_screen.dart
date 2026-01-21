import 'package:dhamma_apk/widgets/cards/post_card.dart';
import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/public_service.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/sidebar.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final PublicService _publicService = PublicService();
  List<Post> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      final response = await _publicService.getPosts(1);
      setState(() {
        _posts = (response['data'] as List)
            .map((item) => Post.fromJson(item))
            .toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<bool> onWillPop() async {
    Navigator.canPop(context)
        ? Navigator.pop(context)
        : Navigator.pushNamedAndRemoveUntil(context, "/home", (route) => false);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        onWillPop();
      },
      child: Scaffold(
        appBar: CustomAppBar(),
        drawer: const Sidebar(),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _posts.isEmpty
                ? _buildEmptyState()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Posts',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Read our latest posts and articles',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
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

                            const double spacing = 16;
                            final double itemWidth =
                                (constraints.maxWidth -
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
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No posts available at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new posts.',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
