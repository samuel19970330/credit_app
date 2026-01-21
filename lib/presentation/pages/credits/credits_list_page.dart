import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/credit.dart';
import '../../provider/credit_provider.dart';
import '../../provider/customer_provider.dart';
import 'credit_detail_page.dart';

class CreditsListPage extends ConsumerStatefulWidget {
  const CreditsListPage({super.key});

  @override
  ConsumerState<CreditsListPage> createState() => _CreditsListPageState();
}

class _CreditsListPageState extends ConsumerState<CreditsListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creditsAsync = ref.watch(creditListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créditos Activos'),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por cédula del cliente',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.trim());
              },
            ),
          ),
          Expanded(
            child: creditsAsync.when(
              data: (credits) {
                // Filter credits by customer document ID
                final filteredCredits = _searchQuery.isEmpty
                    ? credits
                    : credits.where((credit) {
                        // We need to fetch customer for each credit to check document ID
                        // For now, we'll use a FutureBuilder approach
                        return true; // Will be filtered in the list builder
                      }).toList();

                if (filteredCredits.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No hay créditos activos'
                              : 'No se encontraron créditos',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredCredits.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final credit = filteredCredits[index];
                    if (_searchQuery.isEmpty) {
                      return _CreditCard(credit: credit)
                          .animate()
                          .fadeIn(duration: 400.ms, delay: (50 * index).ms)
                          .slideX(begin: 0.1, end: 0);
                    }
                    // Filter by customer document
                    return FutureBuilder(
                      future: ref
                          .read(customerListProvider.notifier)
                          .getCustomerById(credit.customerId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          final customer = snapshot.data!;
                          if (customer.documentId.contains(_searchQuery)) {
                            return _CreditCard(credit: credit)
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideX(begin: 0.1, end: 0);
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditCard extends ConsumerWidget {
  final Credit credit;

  const _CreditCard({required this.credit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We could validly fetch the customer name here using the ID if we had a provider for single customer lookup
    // or if we pre-fetched all customers. For now, we'll just show the ID or "Cliente".

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreditDetailPage(credit: credit),
          ),
        );
      },
      child: Container(
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.monetization_on,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FutureBuilder(
                    future: ref
                        .read(customerListProvider.notifier)
                        .getCustomerById(credit.customerId),
                    builder: (context, snapshot) {
                      final customerName =
                          snapshot.hasData ? snapshot.data!.name : 'Cliente';
                      final customerDoc =
                          snapshot.hasData ? snapshot.data!.documentId : '...';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${credit.id.substring(0, 8).toUpperCase()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey[500],
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            customerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18, // Larger font
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'CC: $customerDoc',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (credit.remainingBalance <= 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Text(
                          'PAGADO',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )
                    else if (credit.isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red),
                        ),
                        child: const Text(
                          'EN MORA',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    Text(
                      NumberFormat.currency(
                              locale: 'es_CO', symbol: '\$', decimalDigits: 0)
                          .format(credit.totalWithInterest),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      '${credit.installmentsCount} Cuotas',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inicio',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      _formatDate(credit.startDate),
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Saldo Pendiente',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                              locale: 'es_CO', symbol: '\$', decimalDigits: 0)
                          .format(credit.remainingBalance),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: credit.remainingBalance <= 0
                            ? Colors.green
                            : AppTheme.errorColor,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.grey, size: 20),
                  onPressed: () => _confirmDelete(context, ref),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Crédito'),
        content: const Text(
            '¿Estás seguro de que deseas eliminar este crédito? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(creditListProvider.notifier).deleteCredit(credit.id);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
