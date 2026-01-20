import 'package:dhamma_apk/widgets/admin/admin_gurd.dart';
import 'package:dhamma_apk/widgets/public_guard.dart';
import 'package:flutter/material.dart';
// Public screens
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/posts_screen.dart';
import 'screens/post_detail_screen.dart';
import 'screens/dhammas_screen.dart';
import 'screens/dhamma_detail_screen.dart';
import 'screens/biographies_screen.dart';
import 'screens/biography_detail_screen.dart';
import 'screens/donations_screen.dart';
import 'screens/monasteries_screen.dart';
import 'screens/monastery_building_donations_screen.dart';
import 'screens/lessons_screen.dart';
import 'screens/lesson_detail_screen.dart';
import 'screens/public_register_screen.dart';
import 'screens/public_login_screen.dart';

// Admin screens
import 'screens/admin/dashboard_admin_screen.dart';
import 'screens/admin/posts_admin_screen.dart';
import 'screens/admin/dhammas_admin_screen.dart';
import 'screens/admin/biographies_admin_screen.dart';
import 'screens/admin/academic_years_admin_screen.dart';
import 'screens/admin/subjects_admin_screen.dart';
import 'screens/admin/classes_admin_screen.dart';
import 'screens/admin/lessons_admin_screen.dart';
import 'screens/admin/categories_admin_screen.dart';
import 'screens/admin/donations_admin_screen.dart';
import 'screens/admin/monasteries_admin_screen.dart';
import 'screens/admin/monastery_building_donations_admin_screen.dart';
import 'screens/admin/contacts_admin_screen.dart';
import 'screens/admin/banners_admin_screen.dart';
import 'screens/admin/banner_texts_admin_screen.dart';
import 'screens/admin/admin_chat_screen.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case '/':
      case '/home':
        return _page(const PublicGuard(child: HomeScreen()), settings);

      case '/login':
        return _page(const LoginScreen(), settings);

      case '/register':
        return _page(const PublicRegisterScreen(), settings);

      case '/public-login':
        return _page(const PublicLoginScreen(), settings);

      // ---------- Public ----------
      case '/posts':
        return _page(const PublicGuard(child: PostsScreen()), settings);

      case '/post-detail':
        return _page(
          PublicGuard(child: PostDetailScreen(postId: args as int)),
          settings,
        );

      case '/dhammas':
        return _page(const PublicGuard(child: DhammasScreen()), settings);

      case '/dhamma-detail':
        return _page(
          PublicGuard(child: DhammaDetailScreen(dhammaId: args as int)),
          settings,
        );

      case '/biographies':
        return _page(const PublicGuard(child: BiographiesScreen()), settings);

      case '/biography-detail':
        return _page(
          PublicGuard(child: BiographyDetailScreen(biographyId: args as int)),
          settings,
        );

      case '/donations':
        return _page(const PublicGuard(child: DonationsScreen()), settings);

      case '/monasteries':
        return _page(const PublicGuard(child: MonasteriesScreen()), settings);

      case '/monastery-building-donations':
        return _page(
          const PublicGuard(child: MonasteryBuildingDonationsScreen()),
          settings,
        );

      case '/lessons':
        return _page(const PublicGuard(child: LessonsScreen()), settings);

      case '/lesson-detail':
        return _page(
          PublicGuard(child: LessonDetailScreen(lessonId: args as int)),
          settings,
        );

      // ---------- Admin (Protected) ----------
      case '/admin/dashboard':
        return _page(const AdminGuard(child: DashboardAdminScreen()), settings);

      case '/admin/posts':
        return _page(const AdminGuard(child: PostsAdminScreen()), settings);

      case '/admin/dhammas':
        return _page(const AdminGuard(child: DhammasAdminScreen()), settings);

      case '/admin/biographies':
        return _page(
          const AdminGuard(child: BiographiesAdminScreen()),
          settings,
        );

      case '/admin/academic-years':
        return _page(
          const AdminGuard(child: AcademicYearsAdminScreen()),
          settings,
        );

      case '/admin/subjects':
        return _page(const AdminGuard(child: SubjectsAdminScreen()), settings);

      case '/admin/classes':
        return _page(const AdminGuard(child: ClassesAdminScreen()), settings);

      case '/admin/lessons':
        return _page(const AdminGuard(child: LessonsAdminScreen()), settings);

      case '/admin/categories':
        return _page(
          const AdminGuard(child: CategoriesAdminScreen()),
          settings,
        );

      case '/admin/donations':
        return _page(const AdminGuard(child: DonationsAdminScreen()), settings);

      case '/admin/monasteries':
        return _page(
          const AdminGuard(child: MonasteriesAdminScreen()),
          settings,
        );

      case '/admin/monastery-building-donations':
        return _page(
          const AdminGuard(child: MonasteryBuildingDonationsAdminScreen()),
          settings,
        );

      case '/admin/contacts':
        return _page(const AdminGuard(child: ContactsAdminScreen()), settings);

      case '/admin/banners':
        return _page(const AdminGuard(child: BannersAdminScreen()), settings);

      case '/admin/banner-texts':
        return _page(
          const AdminGuard(child: BannerTextsAdminScreen()),
          settings,
        );

      case '/admin/chat':
        return _page(const AdminGuard(child: AdminChatScreen()), settings);

      default:
        return _page(
          const Scaffold(body: Center(child: Text('Page not found'))),
          settings,
        );
    }
  }

  static MaterialPageRoute _page(Widget child, RouteSettings settings) {
    return MaterialPageRoute(settings: settings, builder: (_) => child);
  }
}
