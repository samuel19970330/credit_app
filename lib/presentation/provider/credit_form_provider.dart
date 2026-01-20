import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/credit_item.dart';

class CreditFormState {
  final Customer? selectedCustomer;
  final List<CreditItem> items;
  final double interestRate;
  final int installmentsCount;
  final DateTime startDate;

  // Computed values
  final double baseAmount;
  final double interestAmount;
  final double totalWithInterest;
  final double installmentAmount;

  CreditFormState({
    this.selectedCustomer,
    this.items = const [],
    this.interestRate = 0.0,
    this.installmentsCount = 1,
    required this.startDate,
    this.baseAmount = 0.0,
    this.interestAmount = 0.0,
    this.totalWithInterest = 0.0,
    this.installmentAmount = 0.0,
  });

  CreditFormState copyWith({
    Customer? selectedCustomer,
    List<CreditItem>? items,
    double? interestRate,
    int? installmentsCount,
    DateTime? startDate,
    double? baseAmount,
    double? interestAmount,
    double? totalWithInterest,
    double? installmentAmount,
  }) {
    return CreditFormState(
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      items: items ?? this.items,
      interestRate: interestRate ?? this.interestRate,
      installmentsCount: installmentsCount ?? this.installmentsCount,
      startDate: startDate ?? this.startDate,
      baseAmount: baseAmount ?? this.baseAmount,
      interestAmount: interestAmount ?? this.interestAmount,
      totalWithInterest: totalWithInterest ?? this.totalWithInterest,
      installmentAmount: installmentAmount ?? this.installmentAmount,
    );
  }
}

class CreditFormNotifier extends StateNotifier<CreditFormState> {
  CreditFormNotifier() : super(CreditFormState(startDate: DateTime.now()));

  void selectCustomer(Customer customer) {
    state = state.copyWith(selectedCustomer: customer);
  }

  void addProduct(Product product, int quantity) {
    final existingIndex =
        state.items.indexWhere((i) => i.productId == product.id);
    List<CreditItem> newItems;

    if (existingIndex != -1) {
      // Update quantity if already exists
      final existing = state.items[existingIndex];
      final newQuantity = existing.quantity + quantity;

      final newItem = CreditItem(
        productId: product.id,
        productName: product.name,
        unitPrice: product.price,
        quantity: newQuantity,
      );

      newItems = List.from(state.items);
      newItems[existingIndex] = newItem;
    } else {
      // Add new
      final newItem = CreditItem(
        productId: product.id,
        productName: product.name,
        unitPrice: product.price,
        quantity: quantity,
      );
      newItems = [...state.items, newItem];
    }

    state = state.copyWith(items: newItems);
    _calculateTotals();
  }

  void removeProduct(String productId) {
    final newItems =
        state.items.where((i) => i.productId != productId).toList();
    state = state.copyWith(items: newItems);
    _calculateTotals();
  }

  void updateInterestRate(double rate) {
    state = state.copyWith(interestRate: rate);
    _calculateTotals();
  }

  void updateInstallmentsCount(int count) {
    state = state.copyWith(installmentsCount: count);
    _calculateTotals();
  }

  void _calculateTotals() {
    final baseAmount =
        state.items.fold(0.0, (sum, item) => sum + item.subtotal);

    // Use the logic from CreditCalculator to get consistent values
    // but just for display here.
    // Logic: Interest = Base * (Rate/100) * Months

    final monthlyInterestRateDecimal = state.interestRate / 100;
    final totalInterest =
        baseAmount * monthlyInterestRateDecimal * state.installmentsCount;
    final totalWithInterest = baseAmount + totalInterest;
    final installmentAmount = state.installmentsCount > 0
        ? totalWithInterest / state.installmentsCount
        : 0.0;

    state = state.copyWith(
      baseAmount: baseAmount,
      interestAmount: totalInterest,
      totalWithInterest: totalWithInterest,
      installmentAmount: installmentAmount,
    );
  }

  void clear() {
    state = CreditFormState(startDate: DateTime.now());
  }
}

final creditFormProvider =
    StateNotifierProvider.autoDispose<CreditFormNotifier, CreditFormState>(
        (ref) {
  return CreditFormNotifier();
});
