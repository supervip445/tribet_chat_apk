import 'package:flutter/material.dart';
import '../models/biography.dart';
import '../services/public_service.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/like_dislike.dart';
import '../widgets/comment_section.dart';
import '../widgets/sidebar.dart';

class BiographyDetailScreen extends StatefulWidget {
  final int biographyId;

  const BiographyDetailScreen({super.key, required this.biographyId});

  @override
  State<BiographyDetailScreen> createState() => _BiographyDetailScreenState();
}

class _BiographyDetailScreenState extends State<BiographyDetailScreen> {
  final PublicService _publicService = PublicService();
  Biography? _biography;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBiography();
  }

  Future<void> _fetchBiography() async {
    try {
      final response = await _publicService.getBiography(widget.biographyId);
      setState(() {
        _biography = Biography.fromJson(response['data']);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching biography: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      drawer: Builder(
        builder: (context) {
          return const Sidebar();
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _biography == null
                ? const Center(child: Text('Biography not found'))
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        if (_biography!.image != null)
                          Image.network(
                            _biography!.image!,
                            width: double.infinity,
                            height: 300,
                            fit: BoxFit.cover,
                          ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _biography!.name,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (_biography!.viewsCount != null)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.visibility,
                                          size: 18,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_biography!.viewsCount}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'views',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  if (_biography!.birthYear != null)
                                    _buildInfoChip(
                                      'မွေးနှစ်',
                                      _biography!.birthYear!,
                                    ),
                                  if (_biography!.sanghaEntryYear != null)
                                    _buildInfoChip(
                                      'ရဟန်းဝတ်နှစ်',
                                      _biography!.sanghaEntryYear!,
                                    ),
                                  if (_biography!.disciples != null)
                                    _buildInfoChip(
                                      'တပည့်ရဟန်းများ',
                                      _biography!.disciples!,
                                    ),
                                  if (_biography!.teachingMonastery != null)
                                    _buildInfoChip(
                                      'သင်ကြားရာ ကျောင်းတိုက်',
                                      _biography!.teachingMonastery!,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              LikeDislike(
                                likeableType: 'App\\Models\\Biography',
                                likeableId: _biography!.id,
                              ),
                              if (_biography!.sanghaDhamma != null) ...[
                                const SizedBox(height: 24),
                                const Text(
                                  'သာသနာ့ဓမ္မ',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _biography!.sanghaDhamma!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              CommentSection(
                                commentableType: 'App\\Models\\Biography',
                                commentableId: _biography!.id,
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
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
