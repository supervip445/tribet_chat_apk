import 'dart:async';
import 'package:flutter/material.dart';
import '../models/banner.dart' as models;
import '../services/public_service.dart';
import '../widgets/render_image.dart'; // ✅ IMPORT RenderImage

class BannerSlider extends StatefulWidget {
  const BannerSlider({super.key});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final PublicService _publicService = PublicService();

  List<models.Banner> _banners = [];
  int _currentIndex = 0;
  bool _loading = true;

  late final PageController _pageController;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchBanners();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchBanners() async {
    try {
      final response = await _publicService.getBanners();

      if (!mounted) return;

      setState(() {
        _banners =
            (response['data'] as List)
                .map((e) => models.Banner.fromJson(e))
                .where((banner) => banner.isActive)
                .toList()
              ..sort((a, b) => a.order.compareTo(b.order));

        _loading = false;
      });

      if (_banners.length > 1) {
        _startAutoPlay();
      }
    } catch (e) {
      debugPrint('Error fetching banners: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _goToNext(),
    );
  }

  void _goToPrevious() {
    if (!_pageController.hasClients || _banners.isEmpty) return;
    final index = (_currentIndex - 1 + _banners.length) % _banners.length;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToNext() {
    if (!_pageController.hasClients || _banners.isEmpty) return;
    final index = (_currentIndex + 1) % _banners.length;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToSlide(int index) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 250,
        margin: const EdgeInsets.only(bottom: 24),
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (_banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          /// 🖼 Banner Images
          PageView.builder(
            controller: _pageController,
            itemCount: _banners.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final banner = _banners[index];

              return RenderImage(
                imageUrl: banner.image,
                width: double.infinity,
                height: 250,
                rounded: 0,
              );
            },
          ),

          /// ⬅ Previous
          if (_banners.length > 1)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: _ArrowButton(
                icon: Icons.chevron_left,
                onTap: _goToPrevious,
              ),
            ),

          /// ➡ Next
          if (_banners.length > 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: _ArrowButton(icon: Icons.chevron_right, onTap: _goToNext),
            ),

          /// ● Indicators
          if (_banners.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _banners.length,
                  (index) => GestureDetector(
                    onTap: () => _goToSlide(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: index == _currentIndex ? 32 : 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: index == _currentIndex
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.black.withValues(alpha: 0.5),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
