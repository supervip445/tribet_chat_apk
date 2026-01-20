class Dhamma {
  final int id;
  final String title;
  final String content;
  final String speaker;
  final String date;
  final String? image;
  final int? viewsCount;
  final String createdAt;
  final String updatedAt;

  Dhamma({
    required this.id,
    required this.title,
    required this.content,
    required this.speaker,
    required this.date,
    this.image,
    this.viewsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Dhamma.fromJson(Map<String, dynamic> json) {
    return Dhamma(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      speaker: json['speaker'],
      date: json['date'],
      image: json['image'],
      viewsCount: json['views_count'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

