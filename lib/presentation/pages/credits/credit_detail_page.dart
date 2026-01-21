import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/credit.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/installment.dart';
import '../../provider/credit_provider.dart';
import '../../provider/customer_provider.dart';
import '../../../core/utils/pdf_generator.dart';

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
                        ].animate().fadeIn().slideY(begin: -0.1, end: 0),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const Text(
                  'Productos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildProductsList(credit)
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .slideX(begin: 0.1, end: 0),
                const SizedBox(height: 24),
                _buildSummaryCard(credit)
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 24),
                const Text(
                  'Tabla de Amortización',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildInstallmentsList(credit)
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .slideY(begin: 0.2, end: 0),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(Credit credit) {
    final isPaid = credit.remainingBalance <= 0;
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
          if (isPaid) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: const Text(
                'PAGADO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ] else if (credit.isOverdue) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: const Text(
                'EN MORA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
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
            valueColor: isPaid ? Colors.green : AppTheme.errorColor,
            isBold: true,
          ),
          if (!isPaid) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showExtraordinaryPaymentDialog(credit),
                icon: const Icon(Icons.monetization_on),
                label: const Text('REALIZAR ABONO EXTRAORDINARIO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _generatePazYSalvo(credit),
                icon: const Icon(Icons.verified_user),
                label: const Text('GENERAR PAZ Y SALVO'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
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
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: credit.installments.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final inst = credit.installments[index];
              final isPartiallyPaid = inst.paidAmount > 0 && !inst.isPaid;
              final canPay =
                  index == 0 || credit.installments[index - 1].isPaid;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: inst.isPaid
                      ? Colors.green[100]
                      : (isPartiallyPaid
                          ? Colors.orange[100]
                          : Colors.red[100]),
                  child: Text(
                    '${inst.number}',
                    style: TextStyle(
                      color: inst.isPaid
                          ? Colors.green[800]
                          : (isPartiallyPaid
                              ? Colors.orange[800]
                              : Colors.red[800]),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(_currencyFormat.format(inst.amount)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vence: ${_formatDate(inst.dueDate)}'),
                    if (isPartiallyPaid)
                      Text(
                        'Abonado: ${_currencyFormat.format(inst.paidAmount)}\nRestante: ${_currencyFormat.format(inst.amount - inst.paidAmount)}',
                        style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                  ],
                ),
                trailing: inst.isPaid
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.receipt_long,
                                color: AppTheme.primaryColor),
                            tooltip: 'Generar Comprobante',
                            onPressed: () => _generateReceipt(credit, inst),
                          ),
                        ],
                      )
                    : ElevatedButton(
                        onPressed:
                            canPay ? () => _payInstallment(credit, inst) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              canPay ? AppTheme.primaryColor : Colors.grey,
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
        ],
      ),
    );
  }

  Future<void> _showExtraordinaryPaymentDialog(Credit credit) async {
    final controller = TextEditingController();
    final unpaidInstallments = credit.installments.where((i) => !i.isPaid);

    if (unpaidInstallments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El crédito ya está pagado totalmente.')),
      );
      return;
    }

    final firstUnpaid = unpaidInstallments.first;
    final minAmount =
        firstUnpaid.amount; // Requirement: at least one installment value

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Realizar Abono'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Ingrese el monto a abonar. El valor mínimo es una cuota (${_currencyFormat.format(minAmount)}).'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount < minAmount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'El monto debe ser mayor o igual a ${_currencyFormat.format(minAmount)}')),
                );
                // Can't return from dialog button callback to close dialog conditionally easily without pop.
                // Better to just show error and keep dialog open? Or pop then error.
                // For simplicity, let's just validate and close if good, or show toast.
                // Actually, if we pop(true) we do logic outside.
              } else {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Abonar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final amount = double.parse(controller.text);

      // Validation: Cannot exceed remaining balance
      if (amount > credit.remainingBalance + 0.1) {
        // Tolerance
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'El abono no puede superar el saldo pendiente (${_currencyFormat.format(credit.remainingBalance)})')),
          );
        }
        return;
      }

      try {
        final result = await ref
            .read(creditListProvider.notifier)
            .processExtraordinaryPayment(credit.id, amount);

        setState(() {
          _loadCredit();
        });

        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Abono Exitoso'),
              content: Text('Se han pagado ${result['paidCount']} cuota(s).\n'
                  '${(result['remainingInCurrent'] ?? 0) > 0 ? "Queda un pago parcial en la cuota #${result['currentInstallmentNumber']} con un saldo pendiente de ${_currencyFormat.format(result['remainingInCurrent'])}." : ""}'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Aceptar'))
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _generatePazYSalvo(Credit credit) async {
    final customer = await _customerFuture;
    if (customer != null && mounted) {
      await PdfGenerator.generatePazYSalvo(credit: credit, customer: customer);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Información del cliente no disponible'),
          ),
        );
      }
    }
  }

  Future<void> _generateReceipt(Credit credit, Installment installment) async {
    // We need the customer data. It might be loaded in _customerFuture,
    // but better to fetch it or ensure it's available.
    // _customerFuture is a Future<Customer?>, so we can await it.
    final customer = await _customerFuture;

    if (customer != null && mounted) {
      await PdfGenerator.generateReceipt(
        credit: credit,
        customer: customer,
        installment: installment,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error: Información del cliente no disponible')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _payInstallment(Credit credit, Installment installment) async {
    final amountToPay = installment.amount - installment.paidAmount;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Pago'),
        content: Text(
            '¿Desea registrar el pago de la cuota #${installment.number} por ${_currencyFormat.format(amountToPay)}?'),
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
