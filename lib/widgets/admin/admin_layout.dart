import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;
  final String title;

  const AdminLayout({
    super.key,
    required this.child,
    this.title = 'AdminPanel',
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentPath = ModalRoute.of(context)?.settings.name ?? '';

    final menuItems = [
      {
        'path': '/admin/dashboard',
        'label': 'Dashboard',
        'icon': Icons.dashboard,
      },

      {
        'path': '/admin/chat',
        'label': 'User Chat',
        'icon': Icons.chat_bubble_outline,
      },
      {'path': '/admin/banners', 'label': 'Banners', 'icon': Icons.image},
      {
        'path': '/admin/banner-texts',
        'label': 'Banner Texts',
        'icon': Icons.text_fields,
      },
      {'path': '/admin/posts', 'label': 'Posts', 'icon': Icons.article},
      // {
      //   'path': '/admin/categories',
      //   'label': 'Categories',
      //   'icon': Icons.folder,
      // },
      // {
      //   'path': '/admin/dhammas',
      //   'label': 'Dhamma Talks',
      //   'icon': Icons.record_voice_over,
      // },
      // {
      //   'path': '/admin/donations',
      //   'label': 'Donations',
      //   'icon': Icons.attach_money,
      // },
      {
        'path': '/admin/biographies',
        'label': 'Promotions',
        'icon': Icons.person,
      },
      {
        'path': '/admin/monasteries',
        'label': 'TopSellers',
        'icon': Icons.temple_buddhist,
      },
      // {
      //   'path': '/admin/monastery-building-donations',
      //   'label': 'Building Donations',
      //   'icon': Icons.business,
      // },
      // {
      //   'path': '/admin/contacts',
      //   'label': 'Contacts',
      //   'icon': Icons.contact_mail,
      // },
      // {
      //   'path': '/admin/academic-years',
      //   'label': 'Academic Years',
      //   'icon': Icons.calendar_today,
      // },
      // {'path': '/admin/subjects', 'label': 'Subjects', 'icon': Icons.book},
      // {'path': '/admin/classes', 'label': 'Classes', 'icon': Icons.school},
      // {'path': '/admin/lessons', 'label': 'Lessons', 'icon': Icons.menu_book},
    ];

    final pageTitle =
        menuItems.firstWhere(
              (item) => item['path'] == currentPath,
              orElse: () => {'label': title},
            )['label']
            as String;

    Future<bool> onWillPop() async {
      Navigator.pushNamedAndRemoveUntil(context, "/home", (route) => false);
      return false;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        onWillPop();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.amber[800],
          iconTheme: const IconThemeData(color: Colors.white),
          toolbarHeight: 72,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pageTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Welcome, ${authProvider.user?['name'] ?? 'Admin'}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => Navigator.pushReplacementNamed(context, "/home"),
              icon: Icon(Icons.home),
            ),
            SizedBox(width: 8),
          ],
        ),

        drawer: Drawer(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: Colors.amber[800]),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.amber[700],
                  child: Text(
                    authProvider.user?['name']?.substring(0, 1).toUpperCase() ??
                        'A',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
                accountName: Text(authProvider.user?['name'] ?? 'Admin'),
                accountEmail: Text(authProvider.user?['user_name'] ?? ''),
              ),

              Expanded(
                child: ListView(
                  children: menuItems.map((item) {
                    final isActive = currentPath == item['path'];
                    return ListTile(
                      leading: Icon(
                        item['icon'] as IconData,
                        color: isActive ? Colors.amber[800] : null,
                      ),
                      title: Text(item['label'] as String),
                      selected: isActive,
                      selectedTileColor: Colors.amber.withValues(alpha: 0.15),
                      onTap: () {
                        Navigator.pop(context);
                        if (!isActive) {
                          Navigator.of(
                            context,
                          ).pushReplacementNamed(item['path'] as String);
                        }
                      },
                    );
                  }).toList(),
                ),
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout'),
                onTap: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/home');
                  }
                },
              ),
            ],
          ),
        ),

        body: Container(color: Colors.grey[100], child: child),
      ),
    );
  }
}
