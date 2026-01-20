import '../../domain/entities/customer.dart';

class CustomerModel extends Customer {
  CustomerModel({
    required super.id,
    required super.name,
    required super.documentId,
    super.phone,
    super.email,
    super.address,
    super.generalDebt,
    required super.createdAt,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'],
      name: map['name'],
      documentId: map['document_id'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      generalDebt: map['general_debt'] ?? 0.0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'document_id': documentId,
      'phone': phone,
      'email': email,
      'address': address,
      'general_debt': generalDebt,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}
