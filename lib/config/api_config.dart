class ApiConfig {
  // Update this with your actual API base URL
  // For local development: 'http://localhost:8000/api'
  // For production: 'https://your-domain.com/api'
  static const String baseUrl = 'https://trichatback.site/api';

  // Public endpoints
  static const String publicPosts = '/public/posts';
  static const String publicDhammas = '/public/dhammas';
  static const String publicBiographies = '/public/biographies';
  static const String publicDonations = '/public/donations';
  static const String publicMonasteries = '/public/monasteries';
  static const String publicLessons = '/public/lessons';
  static const String publicBanners = '/public/banners';
  static const String publicBannerTexts = '/public/banner-texts';
  static const String publicLikesToggle = '/public/likes/toggle';
  static const String publicLikesCounts = '/public/likes/counts';
  static const String publicComments = '/public/comments';
}

