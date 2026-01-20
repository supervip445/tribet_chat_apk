class Monastery {
  final int id;
  final String name;
  final String type;
  final String? monasteryName;
  final int monks;
  final int novices;
  final int total;
  final int order;
  final String createdAt;
  final String updatedAt;

  Monastery({
    required this.id,
    required this.name,
    required this.type,
    this.monasteryName,
    required this.monks,
    required this.novices,
    required this.total,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Monastery.fromJson(Map<String, dynamic> json) {
    return Monastery(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      monasteryName: json['monastery_name'],
      monks: json['monks'] ?? 0,
      novices: json['novices'] ?? 0,
      total: json['total'] ?? 0,
      order: json['order'] ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class MonasteriesData {
  final String title;
  final String subtitle;
  final List<Monastery> monasteries;
  final List<Monastery> buildings;

  MonasteriesData({
    required this.title,
    required this.subtitle,
    required this.monasteries,
    required this.buildings,
  });

  factory MonasteriesData.fromJson(Map<String, dynamic> json) {
    return MonasteriesData(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      monasteries: (json['monasteries'] as List<dynamic>?)
              ?.map((item) => Monastery.fromJson(item))
              .toList() ??
          [],
      buildings: (json['buildings'] as List<dynamic>?)
              ?.map((item) => Monastery.fromJson(item))
              .toList() ??
          [],
    );
  }
}

