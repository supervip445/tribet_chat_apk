import 'package:dhamma_apk/widgets/cards/dhamma_card.dart';
import 'package:flutter/material.dart';
import '../models/dhamma.dart';
import '../services/public_service.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/sidebar.dart';

class DhammasScreen extends StatefulWidget {
  const DhammasScreen({super.key});

  @override
  State<DhammasScreen> createState() => _DhammasScreenState();
}

class _DhammasScreenState extends State<DhammasScreen> {
  final PublicService _publicService = PublicService();
  final ScrollController _scrollController = ScrollController();

  List<Dhamma> _dhammas = [];

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMorePages = true;

  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _fetchDhammas();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMorePages) {
      _fetchMoreDhammas();
    }
  }

  /// 🔹 Fetch first page
  Future<void> _fetchDhammas() async {
    try {
      final response = await _publicService.getDhammas(_currentPage);

      final dhammas = (response['data'] as List)
          .map((e) => Dhamma.fromJson(e))
          .toList();

      final pagination = response['pagination'];

      setState(() {
        _dhammas = dhammas;
        _hasMorePages = pagination['has_more_pages'];
        _isInitialLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching dhammas: $e');
      setState(() => _isInitialLoading = false);
    }
  }

  /// 🔹 Fetch next pages
  Future<void> _fetchMoreDhammas() async {
    if (!_hasMorePages) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;

    try {
      final response = await _publicService.getDhammas(_currentPage);
      final dhammas = (response['data'] as List)
          .map((e) => Dhamma.fromJson(e))
          .toList();

      final pagination = response['pagination'];

      setState(() {
        _dhammas.addAll(dhammas);
        _hasMorePages = pagination['has_more_pages'];
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Error loading more dhammas: $e');
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
    final cardHeight = 250.0;
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
                  // header
                  SliverPadding(
                    padding: const EdgeInsets.all(12),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dhamma Talks',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Listen to teachings and dhamma talks',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Empty state
                  if (_dhammas.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No dhamma talks available',
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
                            if (index == _dhammas.length) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return DhammaCard(dhamma: _dhammas[index]);
                          },
                          childCount:
                              _dhammas.length + (_isLoadingMore ? 1 : 0),
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
