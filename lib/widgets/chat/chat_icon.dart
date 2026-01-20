import 'package:dhamma_apk/providers/auth_provider.dart';
import 'package:dhamma_apk/services/admin/admin_chat_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/public_auth_service.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';

enum ChatIconMode {
  fab,
  listTile,
}

class ChatIcon extends StatefulWidget {
  final ChatIconMode mode;
  final String title;

  const ChatIcon({
    super.key,
    this.mode = ChatIconMode.fab,
    this.title = 'Chat',
  });

  @override
  State<ChatIcon> createState() => _ChatIconState();
}

class _ChatIconState extends State<ChatIcon> {
  Map<String, dynamic>? _publicUser;
  int _unreadCount = 0;
  bool _isOpen = false;

  final ChatService _chatService = ChatService();
  final AdminChatService _adminChatService = AdminChatService();

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _checkUnreadMessages();
    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted) return;
      _checkUnreadMessages();
    });
  }

  Future<void> _initializeChat() async {
    await _loadPublicUser();
  }

  Future<void> _loadPublicUser() async {
    try {
      final user = await PublicAuthService().getCurrentUser();
      if (!mounted) return;
      setState(() => _publicUser = user);
    } catch (_) {}
  }

  Future<void> _checkUnreadMessages() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      if (_publicUser != null) {
        final response = await _chatService.getMessages(perPage: 50);
        if (response != null && response['data'] != null) {
          final messages = response['data'] as List;
          final unread = messages.where((msg) {
            return msg['read_at'] == null &&
                msg['receiver_id'] == _publicUser!['id'];
          }).length;

          if (mounted) setState(() => _unreadCount = unread);
        }
      } else if (authProvider.isAuthenticated) {
        final res = await _adminChatService.getUsers();
        if (res != null && res['data'] != null) {
          final users = res['data'] as List;
          final totalUnread =
              users.where((u) => (u['unread_count'] ?? 0) > 0).length;
          if (mounted) setState(() => _unreadCount = totalUnread);
        }
      }
    } catch (_) {}
  }

  void _handleChatClick() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_publicUser != null) {
      setState(() {
        _isOpen = true;
        _unreadCount = 0;
      });
      _showChatDialog();
      return;
    }

    if (authProvider.isAuthenticated) {
      Navigator.pushNamed(context, '/admin/chat');
      return;
    }

    Navigator.pushNamed(context, '/public-login');
  }

  void _showChatDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => ChatScreen(
        onClose: () => Navigator.of(context).pop(),
      ),
    ).then((_) async {
      if (!mounted) return;
      setState(() => _isOpen = false);
      await _checkUnreadMessages();
    });
  }

  Widget _buildUnreadBadge() {
    if (_unreadCount <= 0 || _isOpen) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Text(
        _unreadCount > 9 ? '9+' : '$_unreadCount',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFab() {
    return Positioned(
      left: 16,
      bottom: 80,
      child: FloatingActionButton(
        onPressed: _handleChatClick,
        backgroundColor: Colors.amber[600],
        foregroundColor: Colors.black,
        elevation: 8,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              _isOpen ? Icons.close : Icons.chat_bubble_outline,
              size: 24,
            ),
            Positioned(right: -10, top: -10, child: _buildUnreadBadge()),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile() {
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.chat_bubble_outline),
          Positioned(right: -6, top: -6, child: _buildUnreadBadge()),
        ],
      ),
      title: Text(widget.title),
      onTap: _handleChatClick,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.mode == ChatIconMode.fab
        ? _buildFab()
        : _buildListTile();
  }
}
