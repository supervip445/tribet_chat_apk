import 'dart:developer' as developer;
import 'dart:io';
import 'package:dhamma_apk/widgets/admin/admin_chat_header.dart';
import 'package:dhamma_apk/widgets/admin/admin_message_input.dart';
import 'package:dhamma_apk/widgets/admin/admin_conversation_messages_list.dart';
import 'package:dhamma_apk/widgets/admin/admin_conversations_list.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../services/notification_service.dart';
import '../../widgets/admin/admin_layout.dart';
import '../../services/admin/admin_chat_service.dart';
import '../../providers/auth_provider.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final _chatService = AdminChatService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _audioPlayer = AudioPlayer();
  final ImagePicker _imagePicker = ImagePicker();

  List<dynamic> _users = [];
  Map<String, dynamic>? _selectedUser;
  List<dynamic> _messages = [];

  bool _loading = false;
  bool _sending = false;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _previousMessagesCount = 0;
  File? _selectedMediaFile;
  String? _selectedMediaType;
  Function(Map<String, dynamic>)? _socketListener;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _messageController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectSocket();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    if (_socketListener != null) {
      NotificationService().removeListener(_socketListener!);
    }
    super.dispose();
  }

  void _connectSocket() {
    final admin = Provider.of<AuthProvider>(context, listen: false).user;
    final userId = admin?['id']?.toString();
    if (userId == null) return;

    NotificationService().connect(userId: userId);
    _socketListener ??= (data) {
      final payload = data['notification_data'];
      if (payload is Map && payload['type'] == 'chat') {
        _fetchUsers();
        if (_selectedUser != null) {
          _fetchMessages(_selectedUser!['id'], 1, false);
        }
      }
    };
    NotificationService().onNotification(_socketListener!);
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

  Future<void> _playChatSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/livechat.mp3'));
    } catch (_) {
      try {
        await _audioPlayer.play(AssetSource('sounds/noti.wav'));
      } catch (_) {}
    }
  }

  /// Pull-to-refresh
  Future<void> _onRefresh() async {
    await _fetchUsers();
    if (_selectedUser != null) {
      await _fetchMessages(_selectedUser!['id'], 1, false);
    }
  }

  /// Fetch users
  Future<void> _fetchUsers() async {
    try {
      final res = await _chatService.getUsers();
      if (mounted && res?['data'] != null) {
        setState(() => _users = List.from(res['data']));
      }
    } catch (e) {
      developer.log('Fetch users error: $e');
    }
  }

  /// Fetch messages with proper order (oldest first)
  Future<void> _fetchMessages(int userId, int page, bool append) async {
    try {
      setState(() {
        page == 1 ? _loading = true : _isLoadingMore = true;
      });

      final res = await _chatService.getMessages(
        userId,
        page: page,
        perPage: 20,
      );

      if (!mounted || res?['data'] == null) return;

      // 🔄 Reverse API messages so oldest is first
      final fetched = List.from(res['data']).reversed.toList();
      final meta = res['meta'];

      final existingIds = _messages.map((m) => m['id']).toSet();
      final newMessages = fetched
          .where((m) => !existingIds.contains(m['id']))
          .toList();

      setState(() {
        if (append) {
          _messages = [...fetched, ..._messages]; // prepend older messages
        } else if (newMessages.isNotEmpty) {
          _messages.addAll(newMessages);
          _sortMessages();
        }

        _currentPage = page;
        _hasMore = meta != null && meta['current_page'] < meta['last_page'];
        _loading = false;
        _isLoadingMore = false;
      });

      if (!append) {
        if (_previousMessagesCount > 0 && newMessages.isNotEmpty) {
          final adminUser = Provider.of<AuthProvider>(
            context,
            listen: false,
          ).user;
          final hasNewFromUser = newMessages.any(
            (msg) =>
                msg['sender_type'] == 'player' ||
                msg['sender_id'] != adminUser?['id'],
          );
          if (hasNewFromUser) {
            await _playChatSound();
          }
        }
        _previousMessagesCount = _messages.length;
        _scrollToBottom();
      }
    } catch (e) {
      developer.log('Fetch messages error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _isLoadingMore = false;
      });
    }
  }

  /// Send message
  Future<void> _sendMessage() async {
    if (_sending || _selectedUser == null) return;
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedMediaFile == null) return;

    final admin = Provider.of<AuthProvider>(context, listen: false).user;
    final mediaFile = _selectedMediaFile;
    final mediaType = _selectedMediaType;

    // Add temporary message for UI
    setState(() {
      _sending = true;
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'message': text,
        'sender_id': admin?['id'],
        'sender_type': 'super_admin',
        'created_at': DateTime.now().toIso8601String(),
        'media_type': mediaType,
        'media_local_path': mediaFile?.path,
      });
    });

    _messageController.clear();
    _clearSelectedMedia();
    _scrollToBottom();

    try {
      final res = await _chatService.sendMessage(
        _selectedUser!['id'],
        message: text,
        media: mediaFile,
      );
      if (res?['data'] != null) {
        setState(() {
          _messages.removeLast(); // remove temp message
          _messages.add(res['data']); // add real message
        });
        _scrollToBottom();
        _fetchUsers(); // update users list with latest
      }
    } catch (e) {
      developer.log('Send message error: $e');
      setState(() {
        _selectedMediaFile = mediaFile;
        _selectedMediaType = mediaType;
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Load older messages when scrolling to top
  void _loadMore() {
    if (_hasMore && !_isLoadingMore && _selectedUser != null) {
      _fetchMessages(_selectedUser!['id'], _currentPage + 1, true);
    }
  }

  /// Scroll to bottom (latest message)
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _sortMessages() {
    _messages.sort((a, b) {
      final aTime = DateTime.parse(a['created_at']);
      final bTime = DateTime.parse(b['created_at']);
      return aTime.compareTo(bTime);
    });
  }

  /// Format time for message
  String _formatTime(String? s) {
    if (s == null) return '';
    final d = DateTime.tryParse(s);
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final adminId = Provider.of<AuthProvider>(context).user?['id'];

    return AdminLayout(
      title: 'User Chat Management',
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _selectedUser == null
            ? AdminConversationsList(
                users: _users,
                selectedUser: null,
                onSelect: (u) {
                  setState(() {
                    _selectedUser = u;
                    _messages.clear();
                    _currentPage = 1;
                    _previousMessagesCount = 0;
                  });
                  _fetchMessages(u['id'], 1, false);
                },
                formatTime: _formatTime,
                onRefresh: _fetchUsers,
              )
            : Column(
                children: [
                  AdminChatHeader(
                    user: _selectedUser!,
                    onBack: () {
                      setState(() {
                        _selectedUser = null;
                        _messages.clear();
                        _previousMessagesCount = 0;
                      });
                    },
                    onRefresh: () async {
                      await _fetchUsers();
                      await _fetchMessages(_selectedUser!['id'], 1, false);
                    },
                  ),
                  Expanded(
                    child: AdminConversationMessagesList(
                      messages: _messages,
                      loading: _loading,
                      hasMore: _hasMore,
                      isLoadingMore: _isLoadingMore,
                      scrollController: _scrollController,
                      adminId: adminId,
                      onLoadMore: _loadMore,
                      formatTime: _formatTime,
                    ),
                  ),
                  AdminMessageInput(
                    controller: _messageController,
                    sending: _sending,
                    onSend: _sendMessage,
                    onPickImage: _pickImage,
                    onPickVideo: _pickVideo,
                    onClearMedia: _clearSelectedMedia,
                    selectedMediaName: _selectedMediaFile?.path.split('/').last,
                    canSend:
                        _messageController.text.trim().isNotEmpty ||
                        _selectedMediaFile != null,
                  ),
                ],
              ),
      ),
    );
  }
}
