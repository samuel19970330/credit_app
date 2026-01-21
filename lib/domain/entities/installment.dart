class Installment {
  final String id;
  final String creditId;
  final int number;
  final double amount;
  final DateTime dueDate;
  final DateTime? paymentDate;
  final bool isPaid;
  final double paidAmount;
  final double capitalAmount;
  final double interestAmount;

  Installment({
    required this.id,
    required this.creditId,
    required this.number,
    required this.amount,
    required this.dueDate,
    this.paymentDate,
    this.isPaid = false,
    this.paidAmount = 0.0,
    this.capitalAmount = 0.0,
    this.interestAmount = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creditId': creditId,
      'number': number,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'paymentDate': paymentDate?.toIso8601String(),
      'isPaid': isPaid ? 1 : 0,
      'paidAmount': paidAmount,
      'capitalAmount': capitalAmount,
      'interestAmount': interestAmount,
    };
  }

  factory Installment.fromMap(Map<String, dynamic> map) {
    return Installment(
      id: map['id'],
      creditId: map['creditId'],
      number: map['number'],
      amount: map['amount'],
      dueDate: DateTime.parse(map['dueDate']),
      paymentDate: map['paymentDate'] != null
          ? DateTime.parse(map['paymentDate'])
          : null,
      isPaid: map['isPaid'] == 1,
      paidAmount: (map['paidAmount'] ?? 0.0) as double,
      capitalAmount: map['capitalAmount'] ?? 0.0,
      interestAmount: map['interestAmount'] ?? 0.0,
    );
  }
}
