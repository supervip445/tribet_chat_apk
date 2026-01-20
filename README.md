# Parayana Dhamma Center Flutter App

This Flutter application replicates the React web application functionality for the Parayana Dhamma Center.

## Features

- **Home Screen**: Displays recent posts and dhamma talks with banner slider
- **Post Detail**: View full post with likes, comments, and rich text content
- **Dhamma Talk Detail**: View full dhamma talk with speaker info, likes, and comments
- **Biographies**: Browse and view detailed biographies of masters
- **Donations**: View approved donations with summary statistics
- **Monasteries**: View monastery and building lists with statistics
- **Interactive Features**: Like/Dislike and Comment functionality

## Setup Instructions

1. **Update API Base URL**
   - Open `lib/config/api_config.dart`
   - Update `baseUrl` to your Laravel API URL (e.g., `http://your-domain.com/api`)

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Add Logo Asset**
   - Copy `dhamma_center/src/assets/logo.png` to `dhamma_apk/assets/logo.png`
   - Or update the asset path in `pubspec.yaml` if using a different location

4. **Run the App**
   ```bash
   flutter run
   ```

5. **Build APK**
   ```bash
   flutter build apk --release
   ```

## Project Structure

```
lib/
├── config/
│   └── api_config.dart          # API configuration
├── models/                       # Data models
│   ├── post.dart
│   ├── dhamma.dart
│   ├── biography.dart
│   ├── donation.dart
│   ├── monastery.dart
│   ├── banner.dart
│   └── like_comment.dart
├── services/                     # API services
│   ├── api_service.dart
│   └── public_service.dart
├── screens/                      # App screens
│   ├── home_screen.dart
│   ├── post_detail_screen.dart
│   ├── dhamma_detail_screen.dart
│   ├── biographies_screen.dart
│   ├── biography_detail_screen.dart
│   ├── donations_screen.dart
│   └── monasteries_screen.dart
├── widgets/                      # Reusable widgets
│   ├── navbar.dart
│   ├── footer.dart
│   ├── banner_slider.dart
│   ├── marquee_text.dart
│   ├── like_dislike.dart
│   └── comment_section.dart
└── main.dart                     # App entry point
```

## API Endpoints Used

All endpoints are public (no authentication required):
- `/api/public/posts` - Get all posts
- `/api/public/posts/{id}` - Get single post
- `/api/public/dhammas` - Get all dhamma talks
- `/api/public/dhammas/{id}` - Get single dhamma talk
- `/api/public/biographies` - Get all biographies
- `/api/public/biographies/{id}` - Get single biography
- `/api/public/donations` - Get approved donations
- `/api/public/monasteries` - Get monasteries and buildings
- `/api/public/banners` - Get active banners
- `/api/public/banner-texts` - Get active banner texts
- `/api/public/likes/toggle` - Toggle like/dislike
- `/api/public/likes/counts` - Get like counts
- `/api/public/comments` - Get/add comments

## Notes

- The app uses the same API endpoints as the React web application
- All data is publicly accessible (no login required)
- Like/Dislike and Comments work based on IP address tracking
- Make sure CORS is properly configured on your Laravel backend
