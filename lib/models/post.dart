class Post {
  final int id;
  final String title;
  final String content;
  final String? image;
  final String? video;
  final String? slug;
  final String status;
  final int? categoryId;
  final Category? category;
  final int? viewsCount;
  final String createdAt;
  final String updatedAt;

  Post({
    required this.id,
    required this.title,
    required this.content,
    this.image,
    this.video,
    this.slug,
    required this.status,
    this.categoryId,
    this.category,
    this.viewsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      image: json['image'],
      video: json['video'],
      slug: json['slug'],
      status: json['status'],
      categoryId: json['category_id'],
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
      viewsCount: json['views_count'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class Category {
  final int id;
  final String name;
  final String? description;
  final String? slug;

  Category({required this.id, required this.name, this.description, this.slug});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      slug: json['slug'],
    );
  }
}
