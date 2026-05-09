class DealerModel {
  final int? id;
  final String name;
  final String phone;
  final String address;
  final String createdAt;

  DealerModel({
    this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'created_at': createdAt,
      };

  factory DealerModel.fromMap(Map<String, dynamic> map) => DealerModel(
        id: map['id'],
        name: map['name'],
        phone: map['phone'],
        address: map['address'],
        createdAt: map['created_at'],
      );

  DealerModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    String? createdAt,
  }) =>
      DealerModel(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        createdAt: createdAt ?? this.createdAt,
      );
}
