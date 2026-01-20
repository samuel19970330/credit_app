import '../../domain/entities/credit.dart';

class CreditModel extends Credit {
  CreditModel({
    required super.id,
    required super.customerId,
    required super.totalAmount,
    required super.interestRate,
    required super.totalWithInterest,
    required super.startDate,
    required super.installmentsCount,
    required super.status,
    required super.remainingBalance,
  });

  factory CreditModel.fromMap(Map<String, dynamic> map) {
    return CreditModel(
      id: map['id'],
      customerId: map['customer_id'],
      totalAmount: map['total_amount'],
      interestRate: map['interest_rate'],
      totalWithInterest: map['total_with_interest'],
      startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date']),
      installmentsCount: map['installments_count'],
      status: map['status'],
      remainingBalance: map['remaining_balance'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'total_amount': totalAmount,
      'interest_rate': interestRate,
      'total_with_interest': totalWithInterest,
      'start_date': startDate.millisecondsSinceEpoch,
      'installments_count': installmentsCount,
      'status': status,
      'remaining_balance': remainingBalance,
    };
  }
}
