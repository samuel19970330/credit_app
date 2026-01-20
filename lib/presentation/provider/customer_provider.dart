import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../data/repositories/customer_repository_impl.dart';

// Repository Provider
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepositoryImpl();
});

// Customer List Provider
final customerListProvider =
    StateNotifierProvider<CustomerNotifier, AsyncValue<List<Customer>>>((ref) {
  return CustomerNotifier(ref.watch(customerRepositoryProvider));
});

class CustomerNotifier extends StateNotifier<AsyncValue<List<Customer>>> {
  final CustomerRepository _repository;

  CustomerNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    try {
      final customers = await _repository.getCustomers();
      state = AsyncValue.data(customers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> searchCustomers(String query) async {
    state = const AsyncValue.loading();
    try {
      final customers = await _repository.searchCustomers(query);
      state = AsyncValue.data(customers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCustomer(Customer customer) async {
    // Optimistic update or reload? Let's reload for simplicity
    try {
      await _repository.addCustomer(customer);
      await loadCustomers();
    } catch (e) {
      // Handle error, maybe expose via another provider/callback if needed
      // For now, list will just not update if it failed silently in background
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      await _repository.updateCustomer(customer);
      await loadCustomers();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _repository.deleteCustomer(id);
      await loadCustomers();
    } catch (e) {
      // Handle error
    }
  }

  Future<Customer?> getCustomerById(String id) async {
    return await _repository.getCustomerById(id);
  }
}
