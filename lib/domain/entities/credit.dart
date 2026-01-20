import 'credit_item.dart';
import 'installment.dart';

class Credit {
  final String id;
  final String customerId;
  final double totalAmount;
  final double interestRate;
  final double totalWithInterest;
  final DateTime startDate;
  final int installmentsCount;
  final String status;
  final double remainingBalance;
  final List<CreditItem> items;
  final List<Installment> installments;

  Credit({
    required this.id,
    required this.customerId,
    required this.totalAmount,
    required this.interestRate,
    required this.totalWithInterest,
    required this.startDate,
    required this.installmentsCount,
    required this.status,
    required this.remainingBalance,
    this.items = const [],
    this.installments = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'totalAmount': totalAmount,
      'interestRate': interestRate,
      'totalWithInterest': totalWithInterest,
      'startDate': startDate.toIso8601String(),
      'installmentsCount': installmentsCount,
      'status': status,
      'remainingBalance': remainingBalance,
    };
  }

  factory Credit.fromMap(Map<String, dynamic> map,
      {List<CreditItem>? items, List<Installment>? installments}) {
    return Credit(
      id: map['id'],
      customerId: map['customerId'],
      totalAmount: map['totalAmount'],
      interestRate: map['interestRate'],
      totalWithInterest: map['totalWithInterest'],
      startDate: DateTime.parse(map['startDate']),
      installmentsCount: map['installmentsCount'],
      status: map['status'],
      remainingBalance: map['remainingBalance'],
      items: items ?? [],
      installments: installments ?? [],
    );
  }
}
