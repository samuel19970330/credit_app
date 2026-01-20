import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/credit.dart';
import '../../domain/repositories/credit_repository.dart';
import '../../data/repositories/credit_repository_impl.dart';

final creditRepositoryProvider = Provider<CreditRepository>((ref) {
  return CreditRepositoryImpl();
});

final creditListProvider =
    StateNotifierProvider<CreditListNotifier, AsyncValue<List<Credit>>>((ref) {
  return CreditListNotifier(ref.watch(creditRepositoryProvider));
});

class CreditListNotifier extends StateNotifier<AsyncValue<List<Credit>>> {
  final CreditRepository _repository;

  CreditListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCredits();
  }

  Future<void> loadCredits() async {
    try {
      state = const AsyncValue.loading();
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
    } catch (e) {
      // Allow UI to handle error or rethrow
      rethrow;
    }
  }

  Future<void> deleteCredit(String id) async {
    try {
      await _repository.deleteCredit(id);
      await loadCredits();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> payInstallment(String creditId, String installmentId) async {
    try {
      await _repository.payInstallment(creditId, installmentId);
      // We might want to reload or just return success and let UI refetch detail
      await loadCredits();
    } catch (e) {
      rethrow;
    }
  }

  Future<Credit> getCreditById(String id) async {
    return _repository.getCreditById(id);
  }
}
