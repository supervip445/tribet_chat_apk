import 'package:dhamma_apk/widgets/admin/empty_chat_placeholder.dart';
import 'package:flutter/material.dart';

class AdminConversationsList extends StatelessWidget {
  final List users;
  final Map<String, dynamic>? selectedUser;
  final Function(Map<String, dynamic>) onSelect;
  final String Function(String?) formatTime;
  final VoidCallback? onRefresh;

  const AdminConversationsList({
    super.key,
    required this.users,
    required this.selectedUser,
    required this.onSelect,
    required this.formatTime,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sort users: unread first, then latest message
    final List sortedUsers = [...users]
      ..sort((a, b) {
        final int aUnread = a['unread_count'] ?? 0;
        final int bUnread = b['unread_count'] ?? 0;

        // 1️ Unread conversations first
        if (aUnread > 0 && bUnread == 0) return -1;
        if (aUnread == 0 && bUnread > 0) return 1;

        // 2️ Sort by latest message time
        final aTime = a['last_message']?['created_at'];
        final bTime = b['last_message']?['created_at'];

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        return DateTime.parse(bTime).compareTo(DateTime.parse(aTime));
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Your Conversations',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.refresh), onPressed: onRefresh),
            ],
          ),
        ),

        /// users List
        Expanded(
          child: sortedUsers.isEmpty
              ? const EmptyChatPlaceholder()
              : ListView.separated(
                  padding: const EdgeInsets.only(
                    left: 12,
                    right: 12,
                    bottom: 32,
                  ),
                  itemCount: sortedUsers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final u = sortedUsers[i];
                    final isSelected = selectedUser?['id'] == u['id'];
                    final lastMessage = u['last_message'];
                    final unreadCount = u['unread_count'] ?? 0;
                    final hasUnread = unreadCount > 0;

                    return Material(
                      elevation: isSelected ? 2 : 0,
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.08)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => onSelect(u),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // avatar and unread dot
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: theme.colorScheme.primary,
                                    child: Text(
                                      _getInitials(u['name']),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (hasUnread)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(width: 12),

                              // name and last message
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      u['name'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? theme.colorScheme.primary
                                                : Colors.black87,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (lastMessage != null)
                                      Text(
                                        lastMessage['message'] ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight: hasUnread
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: hasUnread
                                                  ? Colors.black87
                                                  : Colors.grey.shade600,
                                            ),
                                      ),
                                  ],
                                ),
                              ),

                              // time and unread count badge
                              if (lastMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (hasUnread)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            unreadCount.toString(),
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      Text(
                                        formatTime(lastMessage['created_at']),
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: Colors.grey.shade500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
