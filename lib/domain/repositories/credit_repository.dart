import '../entities/credit.dart';

abstract class CreditRepository {
  Future<List<Credit>> getCredits();
  Future<List<Credit>> getCreditsByCustomer(String customerId);
  Future<Credit> getCreditById(String id);
  Future<void> addCredit(Credit credit);
  Future<void> deleteCredit(String id);
  Future<void> payInstallment(String creditId, String installmentId);
  Future<Map<String, dynamic>> processExtraordinaryPayment(
      String creditId, double amount);
  Future<void> recalculateBalances();
}
