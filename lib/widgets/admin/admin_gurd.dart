import 'package:dhamma_apk/providers/auth_provider.dart';
import 'package:dhamma_apk/screens/login_screen.dart';
import 'package:dhamma_apk/services/public_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminGuard extends StatelessWidget {
  final Widget child;

  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Check if user is authenticated as admin
    if (!auth.isAuthenticated || auth.user == null) {
      return const LoginScreen();
    }

    // Check if user is admin (super_admin type)
    final userType = auth.user?['type'];
    if (userType != 'super_admin') {
      // If user is a public user, redirect to home
      return FutureBuilder<Map<String, dynamic>?>(
        future: PublicAuthService().getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            // Public user trying to access admin - redirect to home
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushNamed(context, '/home');
            });
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          // Not a public user either - show login
          return const LoginScreen();
        },
      );
    }

    return child;
  }
}
