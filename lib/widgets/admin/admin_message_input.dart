import 'package:flutter/material.dart';

class AdminMessageInput extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onClearMedia;
  final String? selectedMediaName;
  final bool canSend;

  const AdminMessageInput({
    super.key,
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onClearMedia,
    required this.selectedMediaName,
    required this.canSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber[300],
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onSubmitted: (_) => onSend(),
                    cursorColor: Colors.black54,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      hintText: 'Type message',
                      hintStyle: TextStyle(color: Colors.black45),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.black54),
                  onPressed: onPickImage,
                ),
                IconButton(
                  icon: const Icon(Icons.videocam, color: Colors.black54),
                  onPressed: onPickVideo,
                ),
                IconButton(
                  icon: sending
                      ? const SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: Colors.black45),
                  onPressed: (sending || !canSend) ? null : onSend,
                ),
              ],
            ),
            if (selectedMediaName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.attach_file,
                      size: 16,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        selectedMediaName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.black45,
                      ),
                      onPressed: onClearMedia,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
