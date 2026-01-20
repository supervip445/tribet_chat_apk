import 'package:dhamma_apk/widgets/cards/lesson_card.dart';
import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../services/public_service.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/sidebar.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final PublicService _publicService = PublicService();
  final ScrollController _scrollController = ScrollController();

  List<Lesson> _lessons = [];

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMorePages = true;

  int _currentPage = 1;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLessons();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMorePages) {
      _fetchMoreLessons();
    }
  }

  /// 🔹 Fetch first page
  Future<void> _fetchLessons() async {
    try {
      final response = await _publicService.getLessons(_currentPage);

      final lessons = (response['data'] as List)
          .map((e) => Lesson.fromJson(e))
          .toList();

      final pagination = response['pagination'];

      setState(() {
        _lessons = lessons;
        _hasMorePages = pagination['has_more_pages'];
        _isInitialLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching lessons: $e');
      setState(() {
        _isInitialLoading = false;
        _errorMessage = 'Failed to load lessons. Please try again.';
      });
    }
  }

  /// 🔹 Fetch next pages
  Future<void> _fetchMoreLessons() async {
    if (!_hasMorePages) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;

    try {
      final response = await _publicService.getLessons(_currentPage);

      final lessons = (response['data'] as List)
          .map((e) => Lesson.fromJson(e))
          .toList();

      final pagination = response['pagination'];

      setState(() {
        _lessons.addAll(lessons);
        _hasMorePages = pagination['has_more_pages'];
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Error loading more lessons: $e');
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

    int crossAxisCount;
    if (screenWidth >= 1200) {
      crossAxisCount = 4;
    } else if (screenWidth >= 900) {
      crossAxisCount = 3;
    } else if (screenWidth >= 600) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    final cardWidth =
        (screenWidth - 16 * (crossAxisCount + 1)) / crossAxisCount;
    final cardHeight = 200.0;
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
            : (_lessons.isEmpty || _errorMessage != null)
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.book,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No lesson available at the moment.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check back later for new lesson.',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
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
                            'Lessons',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Browse all published lessons',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  if (_lessons.isEmpty && _errorMessage == null)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No lessons available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == _lessons.length) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return LessonCard(lesson: _lessons[index]);
                          },
                          childCount:
                              _lessons.length + (_isLoadingMore ? 1 : 0),
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
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
