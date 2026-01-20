import 'package:flutter/material.dart';

class AdminChatHeader extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onBack;
  final VoidCallback? onRefresh;

  const AdminChatHeader({
    super.key,
    required this.user,
    required this.onBack,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
            iconSize: 20,
          ),
          const CircleAvatar(child: Icon(Icons.person)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user['name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '@${user['user_name'] ?? ''}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: onRefresh),
        ],
      ),
    );
  }
}
