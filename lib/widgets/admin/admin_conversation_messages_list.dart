import 'dart:io';
import 'package:dhamma_apk/util/date_format_util.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AdminConversationMessagesList extends StatelessWidget {
  final List messages;
  final bool loading;
  final bool hasMore;
  final bool isLoadingMore;
  final ScrollController scrollController;
  final int? adminId;
  final VoidCallback onLoadMore;
  final String Function(String?) formatTime;
  final ValueChanged<bool>? onVideoPlaybackChanged;

  const AdminConversationMessagesList({
    super.key,
    required this.messages,
    required this.loading,
    required this.hasMore,
    required this.isLoadingMore,
    required this.scrollController,
    required this.adminId,
    required this.onLoadMore,
    required this.formatTime,
    this.onVideoPlaybackChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Colors.white,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels <= 0 && hasMore && !isLoadingMore) {
            onLoadMore();
          }
          return false;
        },
        child: ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length + (isLoadingMore ? 1 : 0),
          itemBuilder: (_, i) {
            if (isLoadingMore && i == 0) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Loading older messages...',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              );
            }

            final msgIndex = isLoadingMore ? i - 1 : i;
            final m = messages[msgIndex];
            final mine = m['sender_id'] == adminId;
            final senderName =
                m['sender']?['name'] ?? m['sender']?['user_name'];

            final mediaWidget = _buildMediaWidget(
              context,
              m,
              onVideoPlaybackChanged,
            );

            return Align(
              key: ValueKey(m['id']),
              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: mine ? Colors.amber[300] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!mine && senderName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          senderName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    if (mediaWidget != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: mediaWidget,
                      ),
                    if ((m['message'] ?? '').toString().isNotEmpty)
                      Text(m['message'] ?? ''),
                    const SizedBox(height: 4),
                    Text(
                      DateFormatUtil.timeAgoSinceDate(
                        dateTime: DateTime.parse(m['created_at']),
                      ),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget? _buildMediaWidget(
    BuildContext context,
    dynamic message,
    ValueChanged<bool>? onVideoPlaybackChanged,
  ) {
    final mediaType = message['media_type'];
    final mediaUrl = message['media_url'];
    final mediaLocalPath = message['media_local_path'];

    if (mediaType == 'image') {
      if (mediaLocalPath != null) {
        return _buildZoomableImage(
          child: Image.file(File(mediaLocalPath), fit: BoxFit.cover),
          onTap: () => _showImagePreview(
            context,
            Image.file(File(mediaLocalPath), fit: BoxFit.contain),
          ),
        );
      }
      if (mediaUrl != null) {
        return _buildZoomableImage(
          child: Image.network(mediaUrl, fit: BoxFit.cover),
          onTap: () => _showImagePreview(
            context,
            Image.network(mediaUrl, fit: BoxFit.contain),
          ),
        );
      }
    }

    if (mediaType == 'video') {
      final source = mediaLocalPath ?? mediaUrl;
      if (source != null) {
        return _AdminChatVideoPlayer(
          source: source,
          isLocal: mediaLocalPath != null,
          onPlaybackChanged: onVideoPlaybackChanged,
        );
      }
    }

    return null;
  }

  Widget _buildZoomableImage({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 160,
        child: Material(
          color: Colors.transparent,
          child: InkWell(onTap: onTap, child: child),
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context, Widget image) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: image,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminChatVideoPlayer extends StatefulWidget {
  final String source;
  final bool isLocal;
  final ValueChanged<bool>? onPlaybackChanged;

  const _AdminChatVideoPlayer({
    required this.source,
    required this.isLocal,
    this.onPlaybackChanged,
  });

  @override
  State<_AdminChatVideoPlayer> createState() => _AdminChatVideoPlayerState();
}

class _AdminChatVideoPlayerState extends State<_AdminChatVideoPlayer> {
  late final VideoPlayerController _controller;
  late final Future<void> _initializeFuture;
  bool _reportedPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.isLocal
        ? VideoPlayerController.file(File(widget.source))
        : VideoPlayerController.networkUrl(Uri.parse(widget.source));
    _initializeFuture = _controller.initialize();
  }

  @override
  void dispose() {
    if (_reportedPlaying) {
      widget.onPlaybackChanged?.call(false);
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Column(
          children: [
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
            IconButton(
              icon: Icon(
                _controller.value.isPlaying
                    ? Icons.pause_circle
                    : Icons.play_circle,
                color: Colors.amber,
              ),
              onPressed: () {
                setState(() {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                    if (_reportedPlaying) {
                      widget.onPlaybackChanged?.call(false);
                      _reportedPlaying = false;
                    }
                  } else {
                    _controller.play();
                    if (!_reportedPlaying) {
                      widget.onPlaybackChanged?.call(true);
                      _reportedPlaying = true;
                    }
                  }
                });
              },
            ),
          ],
        );
      },
    );
  }
}
