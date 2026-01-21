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

      // 2. Calculate Amount to Pay
      final amountToPay = installment.amount - installment.paidAmount;
      if (amountToPay <= 0) {
        return; // Should not happen if check isPaid, but safety
      }

      // 3. Mark as Paid
      await txn.update(
        'installments',
        {
          'isPaid': 1,
          'paidAmount': installment.amount, // Full amount is now paid
          'paymentDate': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [installmentId],
      );

      // 4. Update Credit Balance
      final creditMaps =
          await txn.query('credits', where: 'id = ?', whereArgs: [creditId]);
      if (creditMaps.isEmpty) throw Exception('Credit not found');
      final credit = Credit.fromMap(creditMaps.first);

      final newBalance =
          (credit.remainingBalance - amountToPay).clamp(0.0, double.infinity);
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

      // 5. Update Customer Debt
      final customerMaps = await txn
          .query('customers', where: 'id = ?', whereArgs: [credit.customerId]);
      if (customerMaps.isNotEmpty) {
        final currentDebt = customerMaps.first['generalDebt'] as double;
        final newDebt = (currentDebt - amountToPay).clamp(0.0, double.infinity);
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
  Future<Map<String, dynamic>> processExtraordinaryPayment(
      String creditId, double amount) async {
    final db = await DatabaseHelper.instance.database;
    return await db.transaction<Map<String, dynamic>>((txn) async {
      // 1. Fetch Credit and Installments
      final creditMaps =
          await txn.query('credits', where: 'id = ?', whereArgs: [creditId]);
      if (creditMaps.isEmpty) throw Exception('Credit not found');
      final credit = Credit.fromMap(creditMaps.first);

      final instMaps = await txn.query('installments',
          where: 'creditId = ?', whereArgs: [creditId], orderBy: 'number ASC');
      final installments = instMaps.map((m) => Installment.fromMap(m)).toList();

      // 2. Validate Unpaid Installments
      final unpaidInstallments = installments.where((i) => !i.isPaid).toList();

      if (unpaidInstallments.isEmpty) {
        throw Exception('El crédito ya está pagado totalmente.');
      }

      // 3. Logic: Distribute Amount
      double remainingToDistribute = amount;
      int paidCount = 0;
      double remainingInCurrent = 0;
      int? currentInstallmentNumber;

      // Minimum payment validation: Must be at least the value of a single installment?
      // User Req: "el abono no puede ser menor al valor de una cuota"
      // Assuming this means the input amount >= standard installment amount.
      // However, installments might vary? Let's assume standard amount from first unpaid.
      if (amount < unpaidInstallments.first.amount) {
        throw Exception(
            'El abono no puede ser menor al valor de una cuota (${unpaidInstallments.first.amount})');
      }

      for (var inst in unpaidInstallments) {
        if (remainingToDistribute <= 0) break;

        final amountDue = inst.amount - inst.paidAmount;

        if (remainingToDistribute >= amountDue) {
          // Pay fully
          await txn.update(
            'installments',
            {
              'isPaid': 1,
              'paidAmount': inst.amount,
              'paymentDate': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [inst.id],
          );
          remainingToDistribute -= amountDue;
          paidCount++;
        } else {
          // Pay partially
          await txn.update(
            'installments',
            {
              'paidAmount': inst.paidAmount + remainingToDistribute,
              // 'isPaid' remains 0
            },
            where: 'id = ?',
            whereArgs: [inst.id],
          );
          remainingInCurrent =
              inst.amount - (inst.paidAmount + remainingToDistribute);
          currentInstallmentNumber = inst.number;
          remainingToDistribute = 0;
        }
      }

      // 4. Update Credit Status & Balance
      final newBalance =
          (credit.remainingBalance - amount).clamp(0.0, double.infinity);
      final newStatus = newBalance <= 0.1 ? 'PAID' : 'ACTIVE';

      await txn.update(
        'credits',
        {'remainingBalance': newBalance, 'status': newStatus},
        where: 'id = ?',
        whereArgs: [creditId],
      );

      // 5. Update Customer Debt
      final customerMaps = await txn
          .query('customers', where: 'id = ?', whereArgs: [credit.customerId]);
      if (customerMaps.isNotEmpty) {
        final currentDebt = customerMaps.first['generalDebt'] as double;
        final newDebt = (currentDebt - amount).clamp(0.0, double.infinity);
        await txn.update(
          'customers',
          {'generalDebt': newDebt},
          where: 'id = ?',
          whereArgs: [credit.customerId],
        );
      }

      return {
        'paidCount': paidCount,
        'remainingInCurrent': remainingInCurrent,
        'currentInstallmentNumber': currentInstallmentNumber,
      };
    });
  }

  @override
  Future<void> recalculateBalances() async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // 1. Fix Negative Balances
      await txn.rawUpdate('''
        UPDATE credits 
        SET remainingBalance = 0, status = 'PAID' 
        WHERE remainingBalance < 0
      ''');

      // 2. Recalculate Customer Debts
      // Reset all debts to 0
      await txn.update('customers', {'generalDebt': 0});

      // Sum active credits per customer
      final debtResults = await txn.rawQuery('''
        SELECT customerId, SUM(remainingBalance) as totalDebt
        FROM credits
        WHERE remainingBalance > 0
        GROUP BY customerId
      ''');

      for (var row in debtResults) {
        final customerId = row['customerId'] as String;
        final totalDebt = row['totalDebt'] as double;

        await txn.update(
          'customers',
          {'generalDebt': totalDebt},
          where: 'id = ?',
          whereArgs: [customerId],
        );
      }
    });
  }
}
