import 'package:flutter/material.dart';
import '../screens/public_login_screen.dart';
import '../services/public_auth_service.dart';

class PublicGuard extends StatelessWidget {
  final Widget child;

  const PublicGuard({super.key, required this.child});

  Future<bool> _checkAuth() async {
    final auth = PublicAuthService();
    await auth.initializeAuth();
    return await auth.isAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAuth(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != true) {
          return const PublicLoginScreen();
        }
        return child;
      },
    );
  }
}
