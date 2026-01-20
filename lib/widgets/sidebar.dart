import 'package:dhamma_apk/services/public_auth_service.dart';
import 'package:dhamma_apk/widgets/chat/chat_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final Future<Map<String, dynamic>?> normalUserFuture = PublicAuthService()
        .getCurrentUser();

    final currentRoute = ModalRoute.of(context)?.settings.name ?? "/home";

    final menuItems = [
      {'title': 'Posts', 'icon': Icons.article, 'route': '/posts'},
      // {
      //   'title': 'Dhamma Talks',
      //   'icon': Icons.record_voice_over,
      //   'route': '/dhammas',
      // },
      {'title': 'Promotions', 'icon': Icons.person, 'route': '/biographies'},
      // {'title': 'Donations', 'icon': Icons.attach_money, 'route': '/donations'},
      {
        'title': 'TopSellers',
        'icon': Icons.temple_buddhist,
        'route': '/monasteries',
      },
      // {
      //   'title': 'Building Donations',
      //   'icon': Icons.home_work,
      //   'route': '/monastery-building-donations',
      // },
      // {'title': 'Lessons', 'icon': Icons.menu_book, 'route': '/lessons'},
    ];

    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // header
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.amber[600]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/logo.jpg',
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.amber[800],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.business_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tri chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // const Text(
                //   'Tri Chat',
                //   style: TextStyle(color: Colors.white, fontSize: 14),
                // ),
              ],
            ),
          ),

          // sidebar menus
          ...menuItems.map((item) {
            final isActive = currentRoute.startsWith(item['route'] as String);

            return ListTile(
              leading: Icon(
                item['icon'] as IconData,
                color: isActive ? Colors.amber[700] : Colors.grey[700],
              ),
              title: Text(
                item['title'] as String,
                style: TextStyle(
                  color: isActive ? Colors.amber[700] : Colors.grey[700],
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isActive,
              selectedTileColor: Colors.amber[50],
              onTap: () {
                Navigator.pushReplacementNamed(
                  context,
                  item['route'] as String,
                );
              },
            );
          }),

          // admin menu
          FutureBuilder<Map<String, dynamic>?>(
            future: normalUserFuture,
            builder: (context, snapshot) {
              final isAdminVisible =
                  (!authProvider.isAuthenticated && snapshot.data == null) ||
                  (authProvider.isAuthenticated && snapshot.data == null);

              if (!isAdminVisible) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.dashboard, color: Colors.amber),
                    title: const Text('Dashboard'),
                    selected: currentRoute == '/admin/dashboard',
                    selectedTileColor: Colors.amber[50],
                    onTap: () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/admin/dashboard',
                      );
                    },
                  ),
                ],
              );
            },
          ),

          const Divider(),

          // support team
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Admin service',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          // ListTile(
          //   leading: const Icon(Icons.person, color: Colors.amber),
          //   title: const Text('Mandalay IT Hub'),
          //   subtitle: Row(
          //     children: const [
          //       Icon(Icons.send, size: 14, color: Colors.grey),
          //       SizedBox(width: 4),
          //       Text('@mandalayithub', style: TextStyle(fontSize: 12)),
          //     ],
          //   ),
          //   onTap: () async {
          //     final scatffoldMes = ScaffoldMessenger.of(context);
          //     final Uri telegramUrl = Uri.parse('https://t.me/mandalayithub');
          //     if (await canLaunchUrl(telegramUrl)) {
          //       await launchUrl(
          //         telegramUrl,
          //         mode: LaunchMode.externalApplication,
          //       );
          //     } else {
          //       scatffoldMes.showSnackBar(
          //         const SnackBar(content: Text('Could not open Telegram link')),
          //       );
          //     }
          //   },
          // ),
          ChatIcon(mode: ChatIconMode.listTile, title: "Chat"),
        ],
      ),
    );
  }
}
