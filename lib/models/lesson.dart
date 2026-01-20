class Lesson {
  final int id;
  final String title;
  final String? description;
  final String? content;
  final int? classId;
  final int? subjectId;
  final int? teacherId;
  final String? lessonDate;
  final int? durationMinutes;
  final String? status;
  final List<String>? attachments;
  final SchoolClass? class_;
  final Subject? subject;
  final Teacher? teacher;
  final int? viewsCount;
  final String? createdAt;
  final String? updatedAt;

  Lesson({
    required this.id,
    required this.title,
    this.description,
    this.content,
    this.classId,
    this.subjectId,
    this.teacherId,
    this.lessonDate,
    this.durationMinutes,
    this.status,
    this.attachments,
    this.class_,
    this.subject,
    this.teacher,
    this.viewsCount,
    this.createdAt,
    this.updatedAt,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      content: json['content'],
      classId: json['class_id'],
      subjectId: json['subject_id'],
      teacherId: json['teacher_id'],
      lessonDate: json['lesson_date'],
      durationMinutes: json['duration_minutes'],
      status: json['status'],
      attachments: json['attachments'] != null
          ? (json['attachments'] is List
              ? List<String>.from(json['attachments'])
              : null)
          : null,
      class_: json['class'] != null ? SchoolClass.fromJson(json['class']) : null,
      subject: json['subject'] != null ? Subject.fromJson(json['subject']) : null,
      teacher: json['teacher'] != null ? Teacher.fromJson(json['teacher']) : null,
      viewsCount: json['views_count'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class SchoolClass {
  final int id;
  final String name;
  final String? code;

  SchoolClass({
    required this.id,
    required this.name,
    this.code,
  });

  factory SchoolClass.fromJson(Map<String, dynamic> json) {
    return SchoolClass(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'],
    );
  }
}

class Subject {
  final int id;
  final String name;
  final String? code;

  Subject({
    required this.id,
    required this.name,
    this.code,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'],
    );
  }
}

class Teacher {
  final int id;
  final String name;
  final String? email;

  Teacher({
    required this.id,
    required this.name,
    this.email,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'],
    );
  }
}

