import 'package:dhamma_apk/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notification_bell.dart';
import '../services/public_auth_service.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

class _CustomAppBarState extends State<CustomAppBar> {
  Map<String, dynamic>? _publicUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPublicUser();
  }

  Future<void> _loadPublicUser() async {
    final user = await PublicAuthService().getCurrentUser();
    if (mounted) {
      setState(() {
        _publicUser = user;
        _isLoading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPublicUser();
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 4,
      shadowColor: Colors.grey.withValues(alpha: 0.3),
      automaticallyImplyLeading: false,

      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.grey),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),

      actions: [
        _buildHomeIconButton(context, currentRoute),
        const NotificationBell(),
        _buildAuthDropdown(context),
      ],
    );
  }

  Widget _buildHomeIconButton(BuildContext context, String? currentRoute) {
    final isActive = currentRoute == '/home';

    return IconButton(
      onPressed: () {
        if (!isActive) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      },
      icon: Icon(
        Icons.home,
        color: isActive ? Colors.amber[600] : Colors.grey[700],
        size: 26,
      ),
    );
  }

  // auth dropdown menu
  Widget _buildAuthDropdown(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(right: 12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final isLoggedIn = _publicUser != null;
    final authProvider = Provider.of<AuthProvider>(context);

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        children: [
          if (isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    color: const Color.fromARGB(255, 5, 135, 179),
                    size: 18,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${_publicUser!['name'] ?? 'User'}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          if (!authProvider.isAuthenticated)
            PopupMenuButton<_AuthMenuAction>(
              color: Colors.white,
              offset: Offset(-20, 40),
              icon: Icon(Icons.more_vert, color: Colors.grey[700]),
              onSelected: (value) async {
                switch (value) {
                  case _AuthMenuAction.login:
                    await Navigator.pushNamed(context, '/public-login');
                    _loadPublicUser();
                    break;

                  case _AuthMenuAction.register:
                    await Navigator.pushNamed(context, '/register');
                    _loadPublicUser();
                    break;

                  case _AuthMenuAction.logout:
                    await PublicAuthService().logout();
                    setState(() => _publicUser = null);
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      );
                    }
                    break;
                }
              },
              itemBuilder: (context) {
                if (isLoggedIn) {
                  return const [
                    PopupMenuItem(
                      value: _AuthMenuAction.logout,
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 18),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ];
                } else {
                  return const [
                    PopupMenuItem(
                      value: _AuthMenuAction.login,
                      child: Row(
                        children: [
                          Icon(Icons.login, size: 18),
                          SizedBox(width: 8),
                          Text('Login'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _AuthMenuAction.register,
                      child: Row(
                        children: [
                          Icon(Icons.person_add, size: 18),
                          SizedBox(width: 8),
                          Text('Register'),
                        ],
                      ),
                    ),
                  ];
                }
              },
            ),
        ],
      ),
    );
  }
}

enum _AuthMenuAction { login, register, logout }
