import 'dart:async';
import 'package:dhamma_apk/models/post.dart';
import 'package:dhamma_apk/util/date_format_util.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  VideoPlayerController? _videoController;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();

    if (_shouldShowVideo) {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(widget.post.video!))
            ..initialize().then((_) {
              if (mounted) setState(() {});
            });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  bool get _shouldShowVideo =>
      widget.post.video != null &&
      widget.post.video!.isNotEmpty &&
      (widget.post.image == null || widget.post.image!.isEmpty);

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_videoController != null &&
        _videoController!.value.isInitialized &&
        _videoController!.value.isPlaying &&
        _showControls) {
      _hideControlsTimer?.cancel();
      _hideControlsTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentPreview = _stripHtmlTags(widget.post.content);
    final previewText = contentPreview.length > 150
        ? '${contentPreview.substring(0, 150)}...'
        : contentPreview;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.pushNamed(
              context,
              '/post-detail',
              arguments: widget.post.id,
            ),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMediaSection(constraints.maxWidth),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(),
                      const SizedBox(height: 8),
                      _buildPreviewText(previewText),
                      const SizedBox(height: 12),
                      _buildCategoryDateRow(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // media section

  Widget _buildMediaSection(double width) {
    final mediaHeight = width * 0.5;

    if (_shouldShowVideo) {
      return _buildVideo(mediaHeight);
    }

    if (widget.post.image != null && widget.post.image!.isNotEmpty) {
      return _buildImage(mediaHeight);
    }

    return _imagePlaceholder(mediaHeight);
  }

  Widget _buildVideo(double height) {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return _imagePlaceholder(height, fallbackIcon: Icons.play_circle_fill);
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
            // animated fade for controls
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IconButton(
                iconSize: 32,
                color: Colors.white,
                icon: Icon(
                  _videoController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
                onPressed: () {
                  if (_videoController == null ||
                      !_videoController!.value.isInitialized) {
                    return;
                  }

                  // Show controls immediately
                  setState(() => _showControls = true);

                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }

                  // Reset the hide timer
                  _hideControlsTimer?.cancel();
                  _hideControlsTimer = Timer(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _showControls = false);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(double height) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Image.network(
          widget.post.image!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _imagePlaceholder(height);
          },
          errorBuilder: (_, __, ___) => _imageError(height),
        ),
      ),
    );
  }

  Widget _imagePlaceholder(
    double height, {
    IconData fallbackIcon = Icons.article,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        gradient: LinearGradient(
          colors: [Colors.orange.shade100, Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(fallbackIcon, size: 48, color: Colors.orange.shade700),
      ),
    );
  }

  Widget _imageError(double height) {
    return Container(
      height: height,
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.post.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF424242),
      ),
    );
  }

  Widget _buildPreviewText(String text) {
    return Text(
      text,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
    );
  }

  Widget _buildCategoryDateRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            widget.post.category?.name ?? 'Uncategorized',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ),
        Text(
          DateFormatUtil.formatDate(widget.post.createdAt),
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
        ),
      ],
    );
  }
}

String _stripHtmlTags(String html) {
  return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}