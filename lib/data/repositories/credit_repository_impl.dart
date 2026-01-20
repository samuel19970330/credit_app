import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/credit.dart';
import '../../domain/entities/credit_item.dart';
import '../../domain/entities/installment.dart';
import '../../domain/repositories/credit_repository.dart';

class CreditRepositoryImpl implements CreditRepository {
  @override
  Future<List<Credit>> getCredits() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('credits', orderBy: 'startDate DESC');

    // For list view, we might not need items/installments, but if we do:
    // This could be optimized to lazy load or load on demand.
    // For now, let's load basic info. If detail is needed, we usually go to detail page.
    // However, the `Credit` object expects list or empty.

    return result.map((json) => Credit.fromMap(json)).toList();
  }

  @override
  Future<List<Credit>> getCreditsByCustomer(String customerId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'credits',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'startDate DESC',
    );
    return result.map((json) => Credit.fromMap(json)).toList();
  }

  // Helper to fetch full details
  @override
  Future<Credit> getCreditById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final creditMaps = await db.query(
      'credits',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (creditMaps.isEmpty) throw Exception('Credit not found');

    final itemsMaps = await db.query(
      'credit_items',
      where: 'creditId = ?',
      whereArgs: [id],
    );
    final installmentsMaps = await db.query(
      'installments',
      where: 'creditId = ?',
      whereArgs: [id],
      orderBy: 'number ASC',
    );

    return Credit.fromMap(
      creditMaps.first,
      items: itemsMaps.map((m) => CreditItem.fromMap(m)).toList(),
      installments:
          installmentsMaps.map((m) => Installment.fromMap(m)).toList(),
    );
  }

  @override
  Future<void> addCredit(Credit credit) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // Insert Credit
      await txn.insert(
        'credits',
        credit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert Items
      for (var item in credit.items) {
        final itemMap = item.toMap();
        itemMap['creditId'] = credit.id;
        itemMap.remove('id'); // Auto-increment
        await txn.insert('credit_items', itemMap);
      }

      // Insert Installments
      for (var installment in credit.installments) {
        final installmentMap = installment.toMap();
        // Ensure creditId is set if not already in entity (it should be)
        await txn.insert('installments', installmentMap);
      }

      // Update Customer Debt
      // We need to fetch current debt and add totalAmount (or totalWithInterest) depending on logic.
      // Usually debt decreases with payments. Initial debt is the loan amount.
      // Let's assume we read the customer, add `totalWithInterest` to `generalDebt`.
      final customerMaps = await txn
          .query('customers', where: 'id = ?', whereArgs: [credit.customerId]);
      if (customerMaps.isNotEmpty) {
        final currentDebt = customerMaps.first['generalDebt'] as double;
        final newDebt = currentDebt + credit.totalWithInterest;
        await txn.update(
          'customers',
          {'generalDebt': newDebt},
          where: 'id = ?',
          whereArgs: [credit.customerId],
        );
      }
    });
  }

  @override
  Future<void> deleteCredit(String id) async {
    final db = await DatabaseHelper.instance.database;
    // Retrieve credit to reduce customer debt before deleting?
    // Or just delete. If we delete, we should probably reduce the debt by the remaining balance.

    final creditMaps =
        await db.query('credits', where: 'id = ?', whereArgs: [id]);
    if (creditMaps.isNotEmpty) {
      final credit = Credit.fromMap(creditMaps.first);
      final customerId = credit.customerId;
      final remaining = credit.remainingBalance;

      await db.transaction((txn) async {
        await txn.delete('credits', where: 'id = ?', whereArgs: [id]);
        // Items and Installments deleted by CASCADE if supported, else manual

        // Update Customer Debt
        final customerMaps = await txn
            .query('customers', where: 'id = ?', whereArgs: [customerId]);
        if (customerMaps.isNotEmpty) {
          final currentDebt = customerMaps.first['generalDebt'] as double;
          final newDebt = (currentDebt - remaining).clamp(0.0, double.infinity);
          await txn.update(
            'customers',
            {'generalDebt': newDebt},
            where: 'id = ?',
            whereArgs: [customerId],
          );
        }
      });
    }
  }

  @override
  Future<void> payInstallment(String creditId, String installmentId) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // 1. Get Installment
      final instMaps = await txn
          .query('installments', where: 'id = ?', whereArgs: [installmentId]);
      if (instMaps.isEmpty) throw Exception('Installment not found');

      final installment = Installment.fromMap(instMaps.first);
      if (installment.isPaid) return; // Already paid

      // 2. Mark as Paid
      await txn.update(
        'installments',
        {
          'isPaid': 1,
          'paymentDate': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [installmentId],
      );

      // 3. Update Credit Balance
      final creditMaps =
          await txn.query('credits', where: 'id = ?', whereArgs: [creditId]);
      if (creditMaps.isEmpty) throw Exception('Credit not found');
      final credit = Credit.fromMap(creditMaps.first);

      final newBalance = credit.remainingBalance - installment.amount;
      final newStatus =
          newBalance <= 0.1 ? 'PAID' : 'ACTIVE'; // Tolerance for float

      await txn.update(
        'credits',
        {
          'remainingBalance': newBalance,
          'status': newStatus,
        },
        where: 'id = ?',
        whereArgs: [creditId],
      );

      // 4. Update Customer Debt
      final customerMaps = await txn
          .query('customers', where: 'id = ?', whereArgs: [credit.customerId]);
      if (customerMaps.isNotEmpty) {
        final currentDebt = customerMaps.first['generalDebt'] as double;
        final newDebt = currentDebt - installment.amount;
        await txn.update(
          'customers',
          {'generalDebt': newDebt},
          where: 'id = ?',
          whereArgs: [credit.customerId],
        );
      }
    });
  }
}
