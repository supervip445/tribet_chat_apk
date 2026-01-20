class Like {
  final int id;
  final String likeableType;
  final int likeableId;
  final String type; // 'like' or 'dislike'
  final String? userIp;
  final String createdAt;
  final String updatedAt;

  Like({
    required this.id,
    required this.likeableType,
    required this.likeableId,
    required this.type,
    this.userIp,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      id: json['id'],
      likeableType: json['likeable_type'],
      likeableId: json['likeable_id'],
      type: json['type'],
      userIp: json['user_ip'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class Comment {
  final int id;
  final String commentableType;
  final int commentableId;
  final String? name;
  final String? email;
  final String comment;
  final bool isApproved;
  final String? userIp;
  final String createdAt;
  final String updatedAt;

  Comment({
    required this.id,
    required this.commentableType,
    required this.commentableId,
    this.name,
    this.email,
    required this.comment,
    required this.isApproved,
    this.userIp,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      commentableType: json['commentable_type'],
      commentableId: json['commentable_id'],
      name: json['name'],
      email: json['email'],
      comment: json['comment'],
      isApproved: json['is_approved'] ?? false,
      userIp: json['user_ip'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

