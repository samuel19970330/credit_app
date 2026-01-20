class Customer {
  final String id;
  final String name;
  final String documentId; // Cédula/DNI
  final String? phone;
  final String? email;
  final String? address;
  final double generalDebt;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    required this.documentId,
    this.phone,
    this.email,
    this.address,
    this.generalDebt = 0.0,
    required this.createdAt,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'documentId': documentId,
      'phone': phone,
      'email': email,
      'address': address,
      'generalDebt': generalDebt,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      documentId: map['documentId'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      generalDebt: map['generalDebt'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
