import 'dart:io';
import 'package:flutter/material.dart';

/// Widget that handles Android back button presses
/// Navigates back in the navigation stack instead of exiting the app
class BackButtonHandler extends StatelessWidget {
  final Widget child;

  const BackButtonHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackButton(context);
      },
      child: child,
    );
  }

  Future<bool> _handleBackButton(BuildContext context) async {
    try {
      final navigator = Navigator.maybeOf(context);

      if (navigator != null && navigator.canPop()) {
        debugPrint('Navigating back with Navigator');
        navigator.pop();
        return false; // Don't exit the app
      }

      // If at root, show exit confirmation
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Exit App'),
          content: const Text('Do you want to exit the application?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Exit'),
            ),
          ],
        ),
      );

      if (shouldExit == true) {
        if (Platform.isAndroid) {
          debugPrint('Exiting app');
          exit(0); // Close the app
        }
      }

      return false; // Don't let system handle the pop automatically
    } catch (e, stackTrace) {
      debugPrint('Error handling back button: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
}
