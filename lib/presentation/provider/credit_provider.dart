import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/credit.dart';
import 'customer_provider.dart';
import '../../domain/repositories/credit_repository.dart';
import '../../data/repositories/credit_repository_impl.dart';

final creditRepositoryProvider = Provider<CreditRepository>((ref) {
  return CreditRepositoryImpl();
});

final creditListProvider =
    StateNotifierProvider<CreditListNotifier, AsyncValue<List<Credit>>>((ref) {
  return CreditListNotifier(ref.watch(creditRepositoryProvider), ref);
});

class CreditListNotifier extends StateNotifier<AsyncValue<List<Credit>>> {
  final CreditRepository _repository;
  final Ref _ref;

  CreditListNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    loadCredits();
  }

  Future<void> loadCredits() async {
    try {
      state = const AsyncValue.loading();
      await _repository.recalculateBalances(); // Sanitize data on load
      final credits = await _repository.getCredits();
      state = AsyncValue.data(credits);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCredit(Credit credit) async {
    try {
      await _repository.addCredit(credit);
      await loadCredits();
      _ref.invalidate(customerListProvider); // Sync customers
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCredit(String id) async {
    try {
      await _repository.deleteCredit(id);
      await loadCredits();
      _ref.invalidate(customerListProvider); // Sync customers
    } catch (e) {
      rethrow;
    }
  }

  Future<void> payInstallment(String creditId, String installmentId) async {
    try {
      await _repository.payInstallment(creditId, installmentId);
      await loadCredits();
      _ref.invalidate(customerListProvider); // Sync customers
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> processExtraordinaryPayment(
      String creditId, double amount) async {
    try {
      final result =
          await _repository.processExtraordinaryPayment(creditId, amount);
      await loadCredits();
      _ref.invalidate(customerListProvider); // Sync customers
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<Credit> getCreditById(String id) async {
    return _repository.getCreditById(id);
  }
}
