import 'package:flutter/material.dart';
import '../../widgets/admin/admin_layout.dart';

class CategoriesAdminScreen extends StatelessWidget {
  const CategoriesAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Categories',
      child: const Center(
        child: Text('Categories management coming soon...'),
      ),
    );
  }
}

