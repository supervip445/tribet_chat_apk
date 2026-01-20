import 'package:flutter/material.dart';
import '../../widgets/admin/admin_layout.dart';
import '../../services/admin/post_service.dart';
import '../../services/admin/category_service.dart';

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  final AdminPostService _postService = AdminPostService();
  final AdminCategoryService _categoryService = AdminCategoryService();

  final Map<String, int> _stats = {
    'posts': 0,
    'categories': 0,
    'donations': 0,
    'contacts': 0,
  };

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final postsRes = await _postService.getAll(1);
      final categoriesRes = await _categoryService.getAll();

      setState(() {
        _stats['posts'] = (postsRes['data'] as List?)?.length ?? 0;
        _stats['categories'] = (categoriesRes['data'] as List?)?.length ?? 0;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount;
    if (screenWidth >= 1200) {
      crossAxisCount = 4;
    } else if (screenWidth >= 900) {
      crossAxisCount = 3;
    } else if (screenWidth >= 600) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    final double cardWidth =
        (screenWidth - 16 * (crossAxisCount + 1)) / crossAxisCount;
    const double cardHeight = 150;
    final double aspectRatio = cardWidth / cardHeight;

    return AdminLayout(
      title: 'Dashboard',
      child: Padding(
        padding: EdgeInsetsGeometry.all(12),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // stat cards
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount * 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: aspectRatio / 2,
                      children: [
                        _buildStatCard(
                          'Total Posts',
                          _stats['posts'].toString(),
                          Icons.article,
                          Colors.blue,
                          () => Navigator.pushNamed(context, '/admin/posts'),
                        ),
                        _buildStatCard(
                          'Categories',
                          _stats['categories'].toString(),
                          Icons.folder,
                          Colors.green,
                          () =>
                              Navigator.pushNamed(context, '/admin/categories'),
                        ),
                        _buildStatCard(
                          'Donations',
                          _stats['donations'].toString(),
                          Icons.attach_money,
                          Colors.orange,
                          () =>
                              Navigator.pushNamed(context, '/admin/donations'),
                        ),
                        _buildStatCard(
                          'Contacts',
                          _stats['contacts'].toString(),
                          Icons.contact_mail,
                          Colors.purple,
                          () => Navigator.pushNamed(context, '/admin/contacts'),
                        ),
                      ],
                    ),

                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: aspectRatio,
                      children: [
                        _buildQuickActionCard(
                          'Create New Post',
                          'Add a new blog post',
                          Icons.article,
                          Colors.blue,
                          () => Navigator.pushNamed(context, '/admin/posts'),
                        ),
                        _buildQuickActionCard(
                          'Manage Donations',
                          'View and approve donations',
                          Icons.attach_money,
                          Colors.green,
                          () =>
                              Navigator.pushNamed(context, '/admin/donations'),
                        ),
                        _buildQuickActionCard(
                          'View Contacts',
                          'Check new messages',
                          Icons.contact_mail,
                          Colors.purple,
                          () => Navigator.pushNamed(context, '/admin/contacts'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // stat card
  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // quick action card
  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
