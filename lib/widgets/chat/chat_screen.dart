import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:dhamma_apk/util/date_format_util.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../services/notification_service.dart';
import '../../services/chat_service.dart';
import '../../services/public_auth_service.dart';

class ChatScreen extends StatefulWidget {
  final VoidCallback onClose;

  const ChatScreen({super.key, required this.onClose});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ImagePicker _imagePicker = ImagePicker();

  Map<String, dynamic>? _publicUser;
  final List<dynamic> _messages = [];

  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _sending = false;
  bool _hasMore = true;

  int _currentPage = 1;
  static const int _perPage = 20;
  int _previousMessagesCount = 0;
  File? _selectedMediaFile;
  String? _selectedMediaType;
  Function(Map<String, dynamic>)? _socketListener;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _messageController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadPublicUser();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _messageController.dispose();
    _audioPlayer.dispose();
    if (_socketListener != null) {
      NotificationService().removeListener(_socketListener!);
    }
    super.dispose();
  }

  void _sortMessages() {
    _messages.sort((a, b) {
      final aTime = DateTime.parse(a['created_at']);
      final bTime = DateTime.parse(b['created_at']);
      return aTime.compareTo(bTime);
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _loadPublicUser() async {
    final user = await PublicAuthService().getCurrentUser();
    if (!mounted) return;

    setState(() => _publicUser = user);

    if (user != null) {
      await _fetchMessages(page: 1, replace: true);
      _scrollToBottom();
      _connectSocket();
    }
  }

  void _connectSocket() {
    if (_publicUser == null) return;
    final userId = _publicUser!['id']?.toString();
    if (userId == null) return;

    NotificationService().connect(userId: userId);
    _socketListener ??= (data) {
      final payload = data['notification_data'];
      if (payload is Map && payload['type'] == 'chat') {
        _fetchMessages(page: 1, replace: true);
      }
    };
    NotificationService().onNotification(_socketListener!);
  }

  Future<void> _playChatSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/livechat.mp3'));
    } catch (_) {
      try {
        await _audioPlayer.play(AssetSource('sounds/noti.wav'));
      } catch (_) {}
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile == null) return;
    setState(() {
      _selectedMediaFile = File(pickedFile.path);
      _selectedMediaType = 'image';
    });
  }

  Future<void> _pickVideo() async {
    final XFile? pickedFile = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 10),
    );
    if (pickedFile == null) return;
    setState(() {
      _selectedMediaFile = File(pickedFile.path);
      _selectedMediaType = 'video';
    });
  }

  void _clearSelectedMedia() {
    setState(() {
      _selectedMediaFile = null;
      _selectedMediaType = null;
    });
  }

  Future<void> _fetchMessages({required int page, bool replace = false}) async {
    if (_loadingMore || (!_hasMore && page > 1)) return;

    if (page == 1) {
      setState(() => _initialLoading = true);
    } else {
      setState(() => _loadingMore = true);
    }

    double prevOffset = 0;
    double prevMaxScroll = 0;

    if (_scrollController.hasClients && page > 1) {
      prevOffset = _scrollController.position.pixels;
      prevMaxScroll = _scrollController.position.maxScrollExtent;
    }

    try {
      final res = await _chatService.getMessages(page: page, perPage: _perPage);
      if (!mounted || res == null) return;

      final List<dynamic> fetched = List.from(res['data'] ?? []);

      final existingIds = _messages.map((m) => m['id']).toSet();
      final newMessages = fetched
          .where((m) => !existingIds.contains(m['id']))
          .toList();

      setState(() {
        if (replace) {
          if (newMessages.isNotEmpty) {
            _messages.addAll(newMessages);
            _sortMessages();
          }
        } else {
          _messages.addAll(fetched);
          _sortMessages();
        }

        _currentPage = page;
        _hasMore = res['meta']['current_page'] < res['meta']['last_page'];
      });

      if (replace) {
        if (_previousMessagesCount > 0 && newMessages.isNotEmpty) {
          final hasNewFromAdmin = newMessages.any(
            (msg) =>
                msg['sender_type'] == 'agent' ||
                msg['sender_id'] != _publicUser?['id'],
          );
          if (hasNewFromAdmin) {
            await _playChatSound();
          }
        }
        _previousMessagesCount = _messages.length;
      }

      // preserve scroll position when loading older messages
      if (!replace && _scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final newMaxScroll = _scrollController.position.maxScrollExtent;
          _scrollController.jumpTo(newMaxScroll - prevMaxScroll + prevOffset);
        });
      }
    } catch (e) {
      debugPrint('Fetch messages error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _initialLoading = false;
          _loadingMore = false;
        });
      }
    }
  }

  /* -------------------- SCROLL -------------------- */

  void _onScroll() {
    if (!_scrollController.hasClients || _loadingMore) return;

    // load older messages when near TOP
    if (_scrollController.position.pixels <= 100) {
      _fetchMessages(page: _currentPage + 1);
    }
  }

  Future<void> _sendMessage() async {
    if (_sending || _publicUser == null) return;

    final text = _messageController.text.trim();
    if ((text.isEmpty && _selectedMediaFile == null) || text.length > 2000) {
      return;
    }

    setState(() => _sending = true);

    final tempId = DateTime.now().millisecondsSinceEpoch;
    final tempMessage = {
      'id': tempId,
      'message': text,
      'sender_id': _publicUser!['id'],
      'created_at': DateTime.now().toIso8601String(),
      'media_type': _selectedMediaType,
      'media_local_path': _selectedMediaFile?.path,
    };

    setState(() {
      _messages.add(tempMessage);
      _sortMessages();
    });

    _messageController.clear();
    final mediaFile = _selectedMediaFile;
    final mediaType = _selectedMediaType;
    _clearSelectedMedia();
    _scrollToBottom();

    try {
      final res = await _chatService.sendMessage(
        message: text,
        media: mediaFile,
      );
      if (res?['data'] != null) {
        setState(() {
          _messages.removeWhere((m) => m['id'] == tempId);
          _messages.add(res['data']);
          _sortMessages();
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Send message error: $e');
      setState(() {
        _messages.removeWhere((m) => m['id'] == tempId);
        _selectedMediaFile = mediaFile;
        _selectedMediaType = mediaType;
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1a1d3a), Color(0xFF101223)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: .5),

            Expanded(
              child: _initialLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.amber),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_loadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_loadingMore && index == _messages.length) {
                          return const Padding(
                            padding: EdgeInsets.all(8),
                            child: Center(
                              child: Text(
                                'Loading older messages...',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }

                        final msg = _messages[index];
                        final isMine = msg['sender_id'] == _publicUser?['id'];
                        final mediaWidget = _buildMediaWidget(msg);

                        return Align(
                          key: ValueKey(msg['id']),
                          alignment: isMine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMine
                                  ? Colors.amber
                                  : const Color(0xFF23243a),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (mediaWidget != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: mediaWidget,
                                  ),
                                if ((msg['message'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                                  Text(
                                    msg['message'] ?? '',
                                    style: TextStyle(
                                      color: isMine
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                  ),
                                Text(
                                  DateFormatUtil.timeAgoSinceDate(
                                    dateTime: DateTime.parse(msg['created_at']),
                                  ),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMine
                                        ? Colors.black.withValues(alpha: .5)
                                        : Colors.white.withValues(alpha: .5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => ListTile(
    leading: const Icon(Icons.chat, color: Colors.amber),
    title: const Text('TriChatSupport', style: TextStyle(color: Colors.white)),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.amber),
          onPressed: () async {
            await _fetchMessages(page: 1, replace: true);
            _scrollToBottom();
          },
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: widget.onClose,
        ),
      ],
    ),
  );

  Widget? _buildMediaWidget(dynamic message) {
    final mediaType = message['media_type'];
    final mediaUrl = message['media_url'];
    final mediaLocalPath = message['media_local_path'];

    if (mediaType == 'image') {
      if (mediaLocalPath != null) {
        return _buildZoomableImage(
          child: Image.file(File(mediaLocalPath), fit: BoxFit.cover),
          onTap: () => _showImagePreview(
            Image.file(File(mediaLocalPath), fit: BoxFit.contain),
          ),
        );
      }
      if (mediaUrl != null) {
        return _buildZoomableImage(
          child: Image.network(mediaUrl, fit: BoxFit.cover),
          onTap: () =>
              _showImagePreview(Image.network(mediaUrl, fit: BoxFit.contain)),
        );
      }
    }

    if (mediaType == 'video') {
      final source = mediaLocalPath ?? mediaUrl;
      if (source != null) {
        return _PublicChatVideoPlayer(
          source: source,
          isLocal: mediaLocalPath != null,
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

  void _showImagePreview(Widget image) {
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

  Widget _buildInput() => Padding(
    padding: const EdgeInsets.only(left: 24, right: 12, bottom: 32),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                maxLength: 2000,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: .5),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.image, color: Colors.amber),
              onPressed: _pickImage,
            ),
            IconButton(
              icon: const Icon(Icons.videocam, color: Colors.amber),
              onPressed: _pickVideo,
            ),
            IconButton(
              icon: _sending
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: Colors.amber),
              onPressed:
                  (_sending ||
                      (_messageController.text.trim().isEmpty &&
                          _selectedMediaFile == null))
                  ? null
                  : _sendMessage,
            ),
          ],
        ),
        if (_messageController.text.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_messageController.text.length}/2000',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .6),
                fontSize: 10,
              ),
            ),
          ),
        if (_selectedMediaFile != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.attach_file, size: 16, color: Colors.white54),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _selectedMediaFile!.path.split('/').last,
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white54,
                  ),
                  onPressed: _clearSelectedMedia,
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _PublicChatVideoPlayer extends StatefulWidget {
  final String source;
  final bool isLocal;

  const _PublicChatVideoPlayer({required this.source, required this.isLocal});

  @override
  State<_PublicChatVideoPlayer> createState() => _PublicChatVideoPlayerState();
}

class _PublicChatVideoPlayerState extends State<_PublicChatVideoPlayer> {
  late final VideoPlayerController _controller;
  late final Future<void> _initializeFuture;

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
                  } else {
                    _controller.play();
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
