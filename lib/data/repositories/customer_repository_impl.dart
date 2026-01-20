import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  @override
  Future<List<Customer>> getCustomers() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('customers', orderBy: 'name ASC');
    return result.map((json) => Customer.fromMap(json)).toList();
  }

  @override
  Future<Customer?> getCustomerById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Customer.fromMap(result.first);
  }

  @override
  Future<void> addCustomer(Customer customer) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  @override
  Future<List<Customer>> searchCustomers(String query) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'customers',
      where: 'name LIKE ? OR documentId LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return result.map((json) => Customer.fromMap(json)).toList();
  }

  @override
  Future<void> deleteCustomer(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
