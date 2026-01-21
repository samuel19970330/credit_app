import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/usecases/credit_calculator.dart';
import '../../provider/credit_form_provider.dart';
import '../../provider/customer_provider.dart';
import '../../provider/product_provider.dart';
import '../../provider/credit_provider.dart';
import '../../../core/theme/app_theme.dart';

class CreditRegistrationPage extends ConsumerStatefulWidget {
  const CreditRegistrationPage({super.key});

  @override
  ConsumerState<CreditRegistrationPage> createState() =>
      _CreditRegistrationPageState();
}

class _CreditRegistrationPageState
    extends ConsumerState<CreditRegistrationPage> {
  final TextEditingController _customerSearchController =
      TextEditingController();
  final TextEditingController _productSearchController =
      TextEditingController();
  final TextEditingController _interestController = TextEditingController();
  final TextEditingController _installmentsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default values
    Future.microtask(() {
      ref
          .read(creditFormProvider.notifier)
          .updateInterestRate(2.0); // Default to user example
      ref.read(creditFormProvider.notifier).updateInstallmentsCount(6);
      _interestController.text = '2';
      _installmentsController.text = '6';
    });
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(creditFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Crédito'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Customer Section
            _buildSectionTitle('Cliente'),
            const SizedBox(height: 8),
            _buildCustomerSearch(),
            if (formState.selectedCustomer != null)
              _buildCustomerInfo(formState.selectedCustomer!),

            const SizedBox(height: 24),

            // 2. Product Section (Add Items)
            _buildSectionTitle('Productos'),
            const SizedBox(height: 8),
            _buildProductSearch(),
            const SizedBox(height: 16),
            _buildItemsList(formState),

            const SizedBox(height: 24),

            // 3. Configuration & Totals
            _buildSectionTitle('Configuración de Pago'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _interestController,
                    decoration: const InputDecoration(
                      labelText: 'Interés Mensual (%)',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      final val = double.tryParse(value) ?? 0.0;
                      ref
                          .read(creditFormProvider.notifier)
                          .updateInterestRate(val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _installmentsController,
                    decoration: const InputDecoration(
                      labelText: 'Cuotas (Meses)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final val = int.tryParse(value) ?? 1;
                      ref
                          .read(creditFormProvider.notifier)
                          .updateInstallmentsCount(val);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 4. Summary Card
            _buildSummaryCard(formState),

            const SizedBox(height: 24),

            // 5. Action
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: formState.selectedCustomer == null ||
                        formState.items.isEmpty
                    ? null
                    : () => _saveCredit(formState),
                child: const Text('REGISTRAR CRÉDITO'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildCustomerSearch() {
    return Column(
      children: [
        Autocomplete<Customer>(
          displayStringForOption: (Customer c) => '${c.name} - ${c.documentId}',
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text == '') {
              return const Iterable<Customer>.empty();
            }
            // Use Repository Provider to search directly
            final customers = await ref
                .read(customerRepositoryProvider)
                .searchCustomers(textEditingValue.text);
            return customers;
          },
          onSelected: (Customer selection) {
            ref.read(creditFormProvider.notifier).selectCustomer(selection);
            _customerSearchController.clear();
          },
          fieldViewBuilder:
              (context, controller, focusNode, onEditingComplete) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              onEditingComplete: onEditingComplete,
              decoration: const InputDecoration(
                labelText: 'Buscar Cliente (Cédula o Nombre)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomerInfo(Customer customer) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.blue.shade50,
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(customer.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            'Cédula: ${customer.documentId}\nTel: ${customer.phone ?? "N/A"}'),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Logic to clear selection could be added if needed, for now just replace by searching again
          },
        ),
      ),
    );
  }

  Widget _buildProductSearch() {
    return Autocomplete<Product>(
      displayStringForOption: (Product p) => p.name,
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text == '') {
          return const Iterable<Product>.empty();
        }
        final products = await ref
            .read(productRepositoryProvider)
            .searchProducts(textEditingValue.text);
        return products;
      },
      onSelected: (Product selection) {
        _showQuantityDialog(selection);
        _productSearchController.clear(); // Reset search
      },
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onEditingComplete: onEditingComplete,
          decoration: const InputDecoration(
            labelText: 'Buscar Producto (Nombre o SKU)',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        );
      },
    );
  }

  Future<void> _showQuantityDialog(Product product) async {
    int quantity = 1;
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Agregar ${product.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Precio: \$${product.price}'),
                const SizedBox(height: 16),
                TextField(
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                  controller: TextEditingController(text: '1'),
                  onChanged: (val) {
                    quantity = int.tryParse(val) ?? 1;
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(creditFormProvider.notifier)
                      .addProduct(product, quantity);
                  Navigator.pop(context);
                },
                child: const Text('AGREGAR'),
              ),
            ],
          );
        });
  }

  Widget _buildItemsList(CreditFormState state) {
    if (state.items.isEmpty) {
      return const Center(
        child: Text('No hay productos agregados',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final item = state.items[index];
        return Card(
          child: ListTile(
            title: Text(item.productName),
            subtitle: Text('${item.quantity} x \$${item.unitPrice}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('\$${item.subtotal}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    ref
                        .read(creditFormProvider.notifier)
                        .removeProduct(item.productId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(CreditFormState state) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _summaryRow('Costo Base (Capital)', state.baseAmount),
            const Divider(),
            _summaryRow(
                'Interés Total (${state.interestRate}%)', state.interestAmount,
                color: Colors.orange),
            const Divider(),
            _summaryRow('Total a Pagar', state.totalWithInterest,
                isTotal: true),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              // Use primary color for installment, readable in both modes (purple/blue-ish)
              // or standard green if it's bright enough. Let's use primaryColor for consistency.
              child: _summaryRow('Valor Cuota Mensual', state.installmentAmount,
                  color: AppTheme.primaryColor, isTotal: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value,
      {Color? color, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        Text(
          '\$${value.toStringAsFixed(0)}', // Showing integers usually looks cleaner for prices like 1,000,000
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  void _saveCredit(CreditFormState state) async {
    if (state.selectedCustomer == null) return;

    // Create the credit
    final (credit, installments) = CreditCalculator.createCreditPlan(
      customerId: state.selectedCustomer!.id,
      amount: state.baseAmount,
      interestRate: state.interestRate,
      installmentsCount: state.installmentsCount,
      startDate: state.startDate,
      items: state.items,
    );

    // Save via Provider
    try {
      await ref.read(creditListProvider.notifier).addCredit(credit);

      // Refresh customer list to update debt
      await ref.read(customerListProvider.notifier).loadCustomers();

      // Update inventory (in a real app this should be transactional or handled by a service)
      // For now we assume optimistic update or just simple update
      // await ref.read(productProvider.notifier).deductStock(state.items);
      // (Assuming functionality exists or just skip for this specific task scope unless requested)

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Crédito registrado exitosamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar crédito: $e')),
        );
      }
    }
  }
}
