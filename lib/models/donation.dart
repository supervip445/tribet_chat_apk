class Donation {
  final int id;
  final String donorName;
  final double amount;
  final String donationType;
  final String date;
  final String status;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  Donation({
    required this.id,
    required this.donorName,
    required this.amount,
    required this.donationType,
    required this.date,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Donation.fromJson(Map<String, dynamic> json) {
    // Handle amount as either string or number
    double parseAmount(dynamic value) {
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return Donation(
      id: json['id'] as int,
      donorName: json['donor_name'] as String,
      amount: parseAmount(json['amount']),
      donationType: json['donation_type'] as String,
      date: json['date'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

