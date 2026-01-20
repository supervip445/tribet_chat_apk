class Banner {
  final int id;
  final String image;
  final int? adminId;
  final int order;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  Banner({
    required this.id,
    required this.image,
    this.adminId,
    required this.order,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id'],
      image: json['image'],
      adminId: json['admin_id'],
      order: json['order'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class BannerText {
  final int id;
  final String text;
  final bool isActive;
  final int? adminId;
  final String createdAt;
  final String updatedAt;

  BannerText({
    required this.id,
    required this.text,
    required this.isActive,
    this.adminId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BannerText.fromJson(Map<String, dynamic> json) {
    return BannerText(
      id: json['id'],
      text: json['text'],
      isActive: json['is_active'] ?? true,
      adminId: json['admin_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

