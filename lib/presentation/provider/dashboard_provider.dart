import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'customer_provider.dart';
import 'credit_provider.dart';

class DashboardStats {
  final double totalReceivable;
  final int clientCount;
  final int activeCreditCount;

  DashboardStats({
    required this.totalReceivable,
    required this.clientCount,
    required this.activeCreditCount,
  });
}

final dashboardStatsProvider = Provider<AsyncValue<DashboardStats>>((ref) {
  final customersAsync = ref.watch(customerListProvider);
  final creditsAsync = ref.watch(creditListProvider);

  if (customersAsync.isLoading || creditsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (customersAsync.hasError || creditsAsync.hasError) {
    return AsyncValue.error('Error loading stats', StackTrace.current);
  }

  final customers = customersAsync.valueOrNull ?? [];
  final credits = creditsAsync.valueOrNull ?? [];

  final totalReceivable = customers.fold<double>(
      0.0, (sum, customer) => sum + customer.generalDebt);

  final activeCreditCount = credits.where((c) => c.status == 'ACTIVE').length;

  return AsyncValue.data(DashboardStats(
    totalReceivable: totalReceivable,
    clientCount: customers.length,
    activeCreditCount: activeCreditCount,
  ));
});
