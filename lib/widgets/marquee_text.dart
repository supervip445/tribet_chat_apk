import 'package:flutter/material.dart';
import '../models/banner.dart';
import '../services/public_service.dart';
import 'dart:async';

class MarqueeText extends StatefulWidget {
  const MarqueeText({super.key});

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  final PublicService _publicService = PublicService();
  List<BannerText> _bannerTexts = [];
  int _currentIndex = 0;
  late ScrollController _scrollController;
  late AnimationController _animationController;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fetchBannerTexts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchBannerTexts() async {
    try {
      final response = await _publicService.getBannerTexts();
      if (mounted) {
        setState(() {
          _bannerTexts = (response['data'] as List)
              .map((item) => BannerText.fromJson(item))
              .where((text) => text.isActive)
              .toList();
        });
      }

      if (_bannerTexts.isNotEmpty) {
        _startMarquee();
      }
    } catch (e) {
      debugPrint('Error fetching banner texts: $e');
    }
  }

  void _startMarquee() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _animationController.addListener(() {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _animationController.value *
              _scrollController.position.maxScrollExtent,
        );
      }
    });

    // Switch banner text every 10 seconds
    _bannerTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % _bannerTexts.length;
        _animationController.reset();
        _animationController.forward();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerTexts.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.amber[800],
      height: 40,
      width: double.infinity,
      child: ListView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Row(
            children: [
              Text(
                _bannerTexts[_currentIndex].text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 50),
              Text(
                _bannerTexts[_currentIndex].text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
