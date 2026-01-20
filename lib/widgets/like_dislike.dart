import 'package:flutter/material.dart';
import '../services/public_service.dart';

class LikeDislike extends StatefulWidget {
  final String likeableType;
  final int likeableId;

  const LikeDislike({
    super.key,
    required this.likeableType,
    required this.likeableId,
  });

  @override
  State<LikeDislike> createState() => _LikeDislikeState();
}

class _LikeDislikeState extends State<LikeDislike> {
  final PublicService _publicService = PublicService();
  int _likes = 0;
  int _dislikes = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLikeCounts();
  }

  Future<void> _fetchLikeCounts() async {
    try {
      final response = await _publicService.getLikeCounts({
        'likeable_type': widget.likeableType,
        'likeable_id': widget.likeableId,
      });
      setState(() {
        _likes = response['likes'] ?? 0;
        _dislikes = response['dislikes'] ?? 0;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching like counts: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    try {
      await _publicService.toggleLike({
        'likeable_type': widget.likeableType,
        'likeable_id': widget.likeableId,
        'type': 'like',
      });
      await _fetchLikeCounts();
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  Future<void> _toggleDislike() async {
    try {
      await _publicService.toggleLike({
        'likeable_type': widget.likeableType,
        'likeable_id': widget.likeableId,
        'type': 'dislike',
      });
      await _fetchLikeCounts();
    } catch (e) {
      debugPrint('Error toggling dislike: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _toggleLike,
          icon: const Icon(Icons.thumb_up),
          label: Text('$_likes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[100],
            foregroundColor: Colors.green[800],
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _toggleDislike,
          icon: const Icon(Icons.thumb_down),
          label: Text('$_dislikes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[100],
            foregroundColor: Colors.red[800],
          ),
        ),
      ],
    );
  }
}

