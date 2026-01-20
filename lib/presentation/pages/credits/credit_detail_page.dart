import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/credit.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/installment.dart';
import '../../provider/credit_provider.dart';
import '../../provider/customer_provider.dart';

class CreditDetailPage extends ConsumerStatefulWidget {
  final Credit credit;

  const CreditDetailPage({super.key, required this.credit});

  @override
  ConsumerState<CreditDetailPage> createState() => _CreditDetailPageState();
}

class _CreditDetailPageState extends ConsumerState<CreditDetailPage> {
  late Future<Credit> _creditFuture;
  late Future<Customer?> _customerFuture;
  final _currencyFormat =
      NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadCredit();
    _loadCustomer();
  }

  void _loadCredit() {
    _creditFuture =
        ref.read(creditListProvider.notifier).getCreditById(widget.credit.id);
  }

  void _loadCustomer() {
    _customerFuture = ref
        .read(customerListProvider.notifier)
        .getCustomerById(widget.credit.customerId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Crédito'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Credit>(
        future: _creditFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Crédito no encontrado'));
          }

          final credit = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<Customer?>(
                  future: _customerFuture,
                  builder: (context, customerSnapshot) {
                    if (customerSnapshot.hasData &&
                        customerSnapshot.data != null) {
                      return Column(
                        children: [
                          _buildCustomerCard(customerSnapshot.data!),
                          const SizedBox(height: 16),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                _buildSummaryCard(credit),
                const SizedBox(height: 24),
                const Text(
                  'Productos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildProductsList(credit),
                const SizedBox(height: 24),
                const Text(
                  'Tabla de Amortización',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildInstallmentsList(credit),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(Credit credit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
              'Monto Total', _currencyFormat.format(credit.totalAmount)),
          const Divider(),
          _buildSummaryRow('Interés', '${credit.interestRate}%'),
          const Divider(),
          _buildSummaryRow('Total con Interés',
              _currencyFormat.format(credit.totalWithInterest)),
          const Divider(),
          _buildSummaryRow(
            'Saldo Pendiente',
            _currencyFormat.format(credit.remainingBalance),
            valueColor: AppTheme.errorColor,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? Colors.black,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person, color: AppTheme.primaryColor, size: 28),
              SizedBox(width: 12),
              Text(
                'Información del Cliente',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow('Nombre', customer.name),
          const SizedBox(height: 8),
          _buildInfoRow('Cédula', customer.documentId),
          if (customer.phone != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Teléfono', customer.phone!),
          ],
          if (customer.email != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Email', customer.email!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildProductsList(Credit credit) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: credit.items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = credit.items[index];
          return ListTile(
            leading: const Icon(Icons.shopping_bag_outlined,
                color: AppTheme.primaryColor),
            title: Text(item.productName),
            subtitle: Text(
                '${item.quantity} x ${_currencyFormat.format(item.unitPrice)}'),
            trailing: Text(_currencyFormat.format(item.subtotal),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }

  Widget _buildInstallmentsList(Credit credit) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: credit.installments.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final inst = credit.installments[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  inst.isPaid ? Colors.green[100] : Colors.orange[100],
              child: Text(
                '${inst.number}',
                style: TextStyle(
                  color: inst.isPaid ? Colors.green[800] : Colors.orange[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(_currencyFormat.format(inst.amount)),
            subtitle: Text('Vence: ${_formatDate(inst.dueDate)}'),
            trailing: inst.isPaid
                ? const Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(
                    onPressed: () => _payInstallment(credit, inst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Pagar'),
                  ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _payInstallment(Credit credit, Installment installment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Pago'),
        content: Text(
            '¿Desea registrar el pago de la cuota #${installment.number} por ${_currencyFormat.format(installment.amount)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Pagar')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(creditListProvider.notifier)
            .payInstallment(credit.id, installment.id);
        setState(() {
          _loadCredit(); // Reload data
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
