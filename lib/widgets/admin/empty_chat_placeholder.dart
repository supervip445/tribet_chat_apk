import 'package:flutter/material.dart';

class EmptyChatPlaceholder extends StatelessWidget {
  const EmptyChatPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.chat, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Select a user to start chatting'),
          ],
        ),
      ),
    );
  }
}
