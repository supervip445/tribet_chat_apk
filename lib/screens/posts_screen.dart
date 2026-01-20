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
  final ScrollController _scrollController = ScrollController();

  List<Post> _posts = [];

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMorePages = true;

  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMorePages) {
      _fetchMorePosts();
    }
  }

  Future<void> _fetchPosts() async {
    try {
      final response = await _publicService.getPosts(_currentPage);

      final posts = (response['data'] as List)
          .map((e) => Post.fromJson(e))
          .toList();

      final pagination = response['pagination'];

      setState(() {
        _posts = posts;
        _hasMorePages = pagination['has_more_pages'];
        _isInitialLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _fetchMorePosts() async {
    if (!_hasMorePages) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;

    try {
      final response = await _publicService.getPosts(_currentPage);

      final posts = (response['data'] as List)
          .map((e) => Post.fromJson(e))
          .toList();

      final pagination = response['pagination'];

      setState(() {
        _posts.addAll(posts);
        _hasMorePages = pagination['has_more_pages'];
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Error loading more posts: $e');
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 800 ? 2 : 1;
    final cardWidth =
        (screenWidth - 24 * (crossAxisCount + 1)) / crossAxisCount;
    final cardHeight = screenWidth < 400 ? 350.0 : 450.0;
    final aspectRatio = cardWidth / cardHeight;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushNamedAndRemoveUntil(context, "/home", (route) => false);
      },
      child: Scaffold(
        appBar: CustomAppBar(),
        drawer: const Sidebar(),
        body: _isInitialLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(12),
                    sliver: SliverToBoxAdapter(
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
                        ],
                      ),
                    ),
                  ),

                  if (_posts.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No posts available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 32),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == _posts.length) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return PostCard(post: _posts[index]);
                          },
                          childCount: _posts.length + (_isLoadingMore ? 1 : 0),
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: aspectRatio,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
