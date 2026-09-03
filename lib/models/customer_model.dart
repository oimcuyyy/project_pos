class CustomerModel {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final int points;

  CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.points = 0,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Pelanggan',
      phone: map['phone']?.toString(),
      email: map['email']?.toString(),
      points: (map['points'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'points': points,
    };
  }
}
