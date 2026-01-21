import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class RenderVideo extends StatefulWidget {
  final String videoUrl;
  final double aspectRatio;

  const RenderVideo({super.key, required this.videoUrl, this.aspectRatio = 16 / 9});

  @override
  State<RenderVideo> createState() => _RenderVideoState();
}

class _RenderVideoState extends State<RenderVideo> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
          });
          _startHideControlsTimer();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);

    if (_controller.value.isInitialized && _controller.value.isPlaying && _showControls) {
      _startHideControlsTimer();
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _playPause() {
    if (!_controller.value.isInitialized) return;

    setState(() => _showControls = true);

    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }

    _startHideControlsTimer();
  }

  @override
  Widget build(BuildContext context) {
    return _initialized
        ? AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: GestureDetector(
              onTap: _toggleControls,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_controller),
                  AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: IconButton(
                      iconSize: 32,
                      color: Colors.white,
                      icon: Icon(
                        _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                      onPressed: _playPause,
                    ),
                  ),
                  // Progress bar at the bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                        playedColor: Colors.red,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        bufferedColor: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : const SizedBox(
            height: 150,
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator()
              )
            )
          );
  }
}
