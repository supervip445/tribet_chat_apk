import 'package:dhamma_apk/util/date_format_util.dart';
import 'package:flutter/material.dart';
import '../models/like_comment.dart';
import '../services/public_service.dart';

class CommentSection extends StatefulWidget {
  final String commentableType;
  final int commentableId;

  const CommentSection({
    super.key,
    required this.commentableType,
    required this.commentableId,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final PublicService _publicService = PublicService();
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    try {
      final response = await _publicService.getComments({
        'commentable_type': widget.commentableType,
        'commentable_id': widget.commentableId,
      });
      setState(() {
        _comments = (response['data'] as List)
            .map((item) => Comment.fromJson(item))
            .where((comment) => comment.isApproved)
            .toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _submitComment() async {
    if (!mounted) return;
    
    if (_commentController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a comment')),
        );
      }
      return;
    }

    try {
      await _publicService.addComment({
        'commentable_type': widget.commentableType,
        'commentable_id': widget.commentableId,
        'comment': _commentController.text.trim(),
      });

      _commentController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment submitted successfully')),
        );
      }

      _fetchComments();
    } catch (e) {
      debugPrint('Error submitting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error submitting comment')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comments',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Comment form
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    labelText: 'Comment *',
                    border: OutlineInputBorder(),
                    hintText: 'Write your comment here...',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _submitComment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Submit Comment'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Comments list
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_comments.isEmpty)
          const Text('No comments yet. Be the first to comment!')
        else
          ..._comments.map((comment) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormatUtil.formatDateTimeAmPm(comment.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        comment.comment,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}

