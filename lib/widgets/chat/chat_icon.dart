import 'package:dhamma_apk/providers/auth_provider.dart';
import 'package:dhamma_apk/services/admin/admin_chat_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/public_auth_service.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';

class ChatIcon extends StatefulWidget {
  const ChatIcon({super.key});

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

  /// Initialize chat state
  Future<void> _initializeChat() async {
    await _loadPublicUser();
  }

  /// Load the current public user
  Future<void> _loadPublicUser() async {
    try {
      final user = await PublicAuthService().getCurrentUser();
      if (!mounted) return;

      setState(() => _publicUser = user);
      debugPrint("Loaded public user: $_publicUser");
    } catch (e) {
      debugPrint('Load public user error: $e');
    }
  }

  Future<void> _checkUnreadMessages() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      // Public user unread messages
      if (_publicUser != null) {
        final response = await _chatService.getMessages(perPage: 50);

        if (response != null && response['data'] != null) {
          final messages = response['data'] as List;

          final unread = messages.where((msg) {
            return msg['read_at'] == null &&
                msg['receiver_id'] == _publicUser!['id'];
          }).length;

          if (mounted) {
            setState(() => _unreadCount = unread);
            debugPrint('Unread messages for public user: $_unreadCount');
          }
        }
      }
      // Admin: fetch users
      else if (authProvider.isAuthenticated) {
        final res = await _adminChatService.getUsers();
        if (mounted && res != null && res['data'] != null) {
          final users = res['data'] as List<dynamic>;

          // Count users with unread messages
          final totalUnread = users.where((user) {
            final unread = user['unread_count'] ?? 0;
            return unread > 0;
          }).length;

          setState(() {
            _unreadCount = totalUnread;
          });
        }
      }
    } catch (e, st) {
      debugPrint('Check messages error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  /// Show chat screen as dialog
  void _showChatDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => ChatScreen(
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
    ).then((_) async {
      if (!mounted) return;

      setState(() => _isOpen = false);

      await _checkUnreadMessages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    /// Handle chat icon click
    void handleChatClick() {
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

    return Positioned(
      left: 16,
      bottom: 80,
      child: FloatingActionButton(
        onPressed: handleChatClick,
        backgroundColor: Colors.amber[600],
        foregroundColor: Colors.black,
        elevation: 8,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(_isOpen ? Icons.close : Icons.chat_bubble_outline, size: 24),
            if (_unreadCount > 0 && !_isOpen)
              Positioned(
                right: -12,
                top: -12,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(width: 1),
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    _unreadCount > 9 ? '9+' : '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
