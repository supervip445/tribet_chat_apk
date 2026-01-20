class Biography {
  final int id;
  final String name;
  final String? birthYear;
  final String? sanghaEntryYear;
  final String? disciples;
  final String? teachingMonastery;
  final String? sanghaDhamma;
  final String? image;
  final int? viewsCount;
  final String createdAt;
  final String updatedAt;

  Biography({
    required this.id,
    required this.name,
    this.birthYear,
    this.sanghaEntryYear,
    this.disciples,
    this.teachingMonastery,
    this.sanghaDhamma,
    this.image,
    this.viewsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Biography.fromJson(Map<String, dynamic> json) {
    return Biography(
      id: json['id'],
      name: json['name'],
      birthYear: json['birth_year'],
      sanghaEntryYear: json['sangha_entry_year'],
      disciples: json['disciples'],
      teachingMonastery: json['teaching_monastery'],
      sanghaDhamma: json['sangha_dhamma'],
      image: json['image'],
      viewsCount: json['views_count'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

