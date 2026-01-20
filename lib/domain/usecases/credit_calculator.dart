import '../entities/credit.dart';
import '../entities/credit_item.dart';
import '../entities/installment.dart';

class CreditCalculator {
  /// Create a new Credit plan
  /// Returns a tuple of [Credit, List<Installment>]
  static (Credit, List<Installment>) createCreditPlan({
    required String customerId,
    required double amount,
    required double interestRate,
    required int installmentsCount,
    required DateTime startDate,
    List<CreditItem> items = const [],
  }) {
    // Logic: Interest is applied MONTHLY.
    // Example: 1,000,000 * 2% * 6 months = 120,000 Interest.
    // Total = 1,120,000. Monthly = 186,666.

    final monthlyInterestRateDecimal = interestRate / 100;
    final totalInterest =
        amount * monthlyInterestRateDecimal * installmentsCount;
    final totalWithInterest = amount + totalInterest;

    // We round to avoid long decimals, user example showed round numbers but let's keep precision then round installment
    final installmentAmountRaw = totalWithInterest / installmentsCount;

    final creditId = DateTime.now().microsecondsSinceEpoch.toString();

    final installments = List<Installment>.generate(installmentsCount, (index) {
      // Simple logic: Monthly installments
      final dueDate =
          DateTime(startDate.year, startDate.month + index + 1, startDate.day);
      return Installment(
        id: '${creditId}_${index + 1}',
        creditId: creditId,
        number: index + 1,
        dueDate: dueDate,
        amount: double.parse(installmentAmountRaw.toStringAsFixed(2)),
        isPaid: false,
        capitalAmount: amount / installmentsCount, // simplified assumption
        interestAmount:
            totalInterest / installmentsCount, // simplified assumption
      );
    });

    final credit = Credit(
      id: creditId,
      customerId: customerId,
      totalAmount: amount,
      interestRate: interestRate,
      totalWithInterest: totalWithInterest,
      startDate: startDate,
      installmentsCount: installmentsCount,
      status: 'ACTIVE',
      remainingBalance: totalWithInterest,
      items: items,
      installments: installments,
    );

    return (credit, installments);
  }
}
