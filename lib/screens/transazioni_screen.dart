import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:developer';
import '../models.dart';
import '../services/database_service.dart';
import '../services/printing_service.dart';

class TransazioniScreen extends StatefulWidget {
  const TransazioniScreen({super.key});

  @override
  State<TransazioniScreen> createState() => _TransazioniScreenState();
}

class _TransazioniScreenState extends State<TransazioniScreen> {
  final DatabaseService _db = DatabaseService();
  
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedPaymentMethod;
  bool? _selectedIsReturn;
  bool _filtersExpanded = false;

  final List<String> _paymentMethods = [
    'CONTANTE',
    'CARTA',
    'TICKET',
    'SATISPAY',
    'TRANSFER',
    'MOBILE',
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await _db.getTransactions(
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
        paymentMethod: _selectedPaymentMethod,
        isReturn: _selectedIsReturn,
      );
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _selectStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
            ), dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() => _selectedStartDate = pickedDate);
      _loadTransactions();
    }
  }

  Future<void> _selectEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
            ), dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() => _selectedEndDate = pickedDate);
      _loadTransactions();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedStartDate = null;
      _selectedEndDate = null;
      _selectedPaymentMethod = null;
      _selectedIsReturn = null;
    });
    _loadTransactions();
  }

  String _getPaymentMethodDisplay(String method) {
    final methods = {
      'CONTANTE': 'Contanti',
      'CARTA': 'Carta',
      'TICKET': 'Buono',
      'SATISPAY': 'Satispay',
      'TRANSFER': 'Bonifico',
      'MOBILE': 'Mobile',
    };
    return methods[method] ?? method;
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final isSmallScreen = MediaQuery.of(context).size.width < 768;
    
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: isSmallScreen ? 14 : 16, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 768;
    final totalAmount = _transactions.fold(0.0, (sum, t) => sum + t.total);
    final salesCount = _transactions.where((t) => t.status == 0).length;
    final returnsCount = _transactions.where((t) => t.status == 1).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: isSmallScreen
            ? IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF64748B)),
              )
            : null,
        title: const Text(
          'Transazioni',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadTransactions,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            tooltip: 'Aggiorna',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Section
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    _buildStatCard(
                      'Totale',
                      '€${totalAmount.toStringAsFixed(2)}',
                      Icons.euro_rounded,
                      const Color(0xFF10B981),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    _buildStatCard(
                      'Vendite',
                      salesCount.toString(),
                      Icons.shopping_bag_rounded,
                      const Color(0xFF2563EB),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    _buildStatCard(
                      'Resi',
                      returnsCount.toString(),
                      Icons.undo_rounded,
                      const Color(0xFFEF4444),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Filter Toggle
                GestureDetector(
                  onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filtri',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                        Icon(
                          _filtersExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filters Section
          if (_filtersExpanded) _buildFiltersPanel(),

          // Transactions List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _transactions.isEmpty
                    ? _buildEmptyState()
                    : _buildTransactionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    final isSmallScreen = MediaQuery.of(context).size.width < 768;
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Filters
          isSmallScreen 
              ? Column(
                  children: [
                    _buildDateFilterButton(
                      label: 'Dal',
                      date: _selectedStartDate,
                      onTap: _selectStartDate,
                    ),
                    const SizedBox(height: 8),
                    _buildDateFilterButton(
                      label: 'Al',
                      date: _selectedEndDate,
                      onTap: _selectEndDate,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildDateFilterButton(
                        label: 'Dal',
                        date: _selectedStartDate,
                        onTap: _selectStartDate,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDateFilterButton(
                        label: 'Al',
                        date: _selectedEndDate,
                        onTap: _selectEndDate,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 12),

          // Payment Methods
          Text(
            'Metodo di pagamento:',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _paymentMethods.map((method) {
              final isSelected = _selectedPaymentMethod == method;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPaymentMethod = isSelected ? null : method;
                  });
                  _loadTransactions();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 10 : 12,
                    vertical: isSmallScreen ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    _getPaymentMethodDisplay(method),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Transaction Type
          Text(
            'Tipo transazione:',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTypeButton(
                  label: 'Vendite',
                  isSelected: _selectedIsReturn == false,
                  onTap: () {
                    setState(() {
                      _selectedIsReturn = _selectedIsReturn == false ? null : false;
                    });
                    _loadTransactions();
                  },
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTypeButton(
                  label: 'Resi',
                  isSelected: _selectedIsReturn == true,
                  onTap: () {
                    setState(() {
                      _selectedIsReturn = _selectedIsReturn == true ? null : true;
                    });
                    _loadTransactions();
                  },
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Clear Filters
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _clearFilters,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 12 : 16,
                ),
              ),
              icon: const Icon(Icons.clear_all_rounded, size: 16),
              label: const Text('Cancella filtri'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 768;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date != null ? DateFormat('dd/MM/yy').format(date) : label,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                color: date != null
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF94A3B8),
              ),
            ),
            Icon(
              Icons.calendar_month_rounded,
              size: isSmallScreen ? 14 : 16,
              color: const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 768;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? color : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSmallScreen = MediaQuery.of(context).size.width < 768;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isSmallScreen ? 60 : 80,
            height: isSmallScreen ? 60 : 80,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: isSmallScreen ? 28 : 36,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Nessuna transazione',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prova a modificare i filtri',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    final isSmallScreen = MediaQuery.of(context).size.width < 768;
    
    return ListView.separated(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      itemCount: _transactions.length,
      separatorBuilder: (_, __) => SizedBox(height: isSmallScreen ? 8 : 12),
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return _buildTransactionCard(transaction, isSmallScreen);
      },
    );
  }

  Widget _buildTransactionCard(Transaction transaction, bool isSmallScreen) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TransactionDetailScreen(
                transaction: transaction,
                onRefundCompleted: _loadTransactions, // Pass refresh callback
              ),
            ),
          );
          
          // Refresh list when returning from detail screen if a refund was processed
          if (result == true) {
            _loadTransactions();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Status Indicator
              Container(
                width: 4,
                height: isSmallScreen ? 32 : 40,
                decoration: BoxDecoration(
                  color: transaction.status == 1
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(transaction.date),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        if (transaction.isReturn)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'RESO',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 9 : 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(transaction.date),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getPaymentMethodDisplay(transaction.paymentMethod),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                        Text(
                          '${transaction.items.length} articoli',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount and Arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '€${transaction.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: isSmallScreen ? 18 : 20,
                    color: const Color(0xFFCBD5E1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;
  final VoidCallback? onRefundCompleted; // Callback to refresh list

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    this.onRefundCompleted,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _isProcessingRefund = false;
  Transaction get transaction => widget.transaction;

  String _getPaymentMethodDisplay(String method) {
    final methods = {
      'CONTANTE': 'Contanti',
      'CARTA': 'Carta',
      'TICKET': 'Buono',
      'SATISPAY': 'Satispay',
      'TRANSFER': 'Bonifico',
      'MOBILE': 'Mobile',
    };
    return methods[method] ?? method;
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 768;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context, _isProcessingRefund),
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF64748B)),
        ),
        title: const Text(
          'Dettagli',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            children: [
              // Header Card
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ID #${transaction.id ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        if (transaction.isReturn)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 10 : 12,
                              vertical: isSmallScreen ? 4 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'RESO',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      DateFormat('dd MMMM yyyy').format(transaction.date),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 15 : 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm').format(transaction.date),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Info Cards
              Column(
                children: [
                  // Payment Info
                  _buildInfoCard(
                    icon: Icons.payment_rounded,
                    title: 'Pagamento',
                    isSmallScreen: isSmallScreen,
                    children: [
                      _buildInfoRow(
                        'Metodo', 
                        _getPaymentMethodDisplay(transaction.paymentMethod),
                        isSmallScreen: isSmallScreen,
                      ),
                      if (transaction.fiscalReceiptNumber != null)
                        _buildInfoRow(
                          'Ricevuta', 
                          '#${transaction.fiscalReceiptNumber!}',
                          isSmallScreen: isSmallScreen,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Items List
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Articoli',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...transaction.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 13 : 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '€${item.price.toStringAsFixed(2)} × ${item.quantity}',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 13,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '€${item.total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Total Card
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Totale',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 15 : 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        Text(
                          '€${transaction.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Refund Button (only if not already a return)
              if (transaction.fiscalReceiptNumber != null && transaction.status != 1)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessingRefund ? null : _showRefundConfirmation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isProcessingRefund
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.undo_rounded, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Richiedi Reso',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: const Color(0xFF475569)),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {required bool isSmallScreen}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 13,
              color: const Color(0xFF64748B),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRefundConfirmation() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Conferma Reso',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Stai per emettere il reso di questa transazione. L\'operazione non può essere annullata.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Importo del reso',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '€${transaction.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: const Text('Annulla'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Conferma'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _processRefund();
    }
  }

  Future<void> _processRefund() async {
    setState(() => _isProcessingRefund = true);

    try {
      final printingService = PrintingService();
      
      final refundItems = transaction.items
          .map((item) => {
            'name': item.productName,
            'price': item.price,
            'quantity': item.quantity,
          })
          .toList();
      
      final responseBody = await printingService.printRefundReceipt(
        zRepNumber: transaction.zRepNumber ?? '',
        fiscalReceiptNumber: transaction.fiscalReceiptNumber ?? '',
        receiptISODateTime: transaction.receiptISODateTime ?? '',
        serialNumber: transaction.serialNumber ?? '',
        refundItems: refundItems,
        paymentMethod: transaction.paymentMethod,
        justification: 'Reso completo',
      );

      if (mounted) {
        if (responseBody != null && responseBody.isNotEmpty) {
          await _handleRefundSuccess(responseBody);
        } else {
          _showRefundErrorDialog('Errore nella stampa del reso');
        }
      }
    } catch (e) {
      if (mounted) {
        _showRefundErrorDialog('Errore: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingRefund = false);
      }
    }
  }

  Future<void> _handleRefundSuccess(String responseBody) async {
    try {
      final printerStatus = _extractPrinterStatus(responseBody);
      
      if (printerStatus != null) {
        final statusSegments = _decodePrinterStatus(printerStatus);
        final printerState = statusSegments['printer'] ?? '';
        
        if (printerState.toLowerCase().contains('ok')) {
          // Update local transaction
          transaction.status = 1;
          
          // Update in database
          if (transaction.id != null) {
            final dbService = DatabaseService();
            await dbService.updateTransactionStatus(transaction.id!, 1);
          }
          
          // Call the callback to refresh the list
          widget.onRefundCompleted?.call();
          
          // Show success dialog and navigate back with true to indicate refresh
          _showRefundSuccessDialog();
          
        } else {
          _showRefundErrorDialog('Stato stampante non OK: $printerState');
        }
      } else {
        _showRefundErrorDialog('Impossibile leggere lo stato della stampante');
      }
    } catch (e) {
      _showRefundErrorDialog('Errore nel processamento: $e');
    }
  }

  String? _extractPrinterStatus(String xmlResponse) {
    try {
      const startTag = '<printerStatus>';
      const endTag = '</printerStatus>';
      final startIndex = xmlResponse.indexOf(startTag);
      final endIndex = xmlResponse.indexOf(endTag);
      
      if (startIndex != -1 && endIndex != -1) {
        return xmlResponse.substring(startIndex + startTag.length, endIndex).trim();
      }
    } catch (e) {
      log('Error extracting printer status: $e');
    }
    return null;
  }

  Map<String, String> _decodePrinterStatus(String printerStatus) {
    try {
      String printer = '';
      String ej = '';
      String cashDrawer = '';
      String receipt = '';
      String mode = '';

      if (printerStatus.length >= 5) {
        switch (printerStatus[0]) {
          case '0':
            printer = 'OK';
            break;
          case '2':
            printer = 'Carta in esaurimento';
            break;
          case '3':
            printer = 'Stampante offline';
            break;
          default:
            printer = 'Stato stampante sconosciuto';
        }

        switch (printerStatus[1]) {
          case '0':
            ej = 'Giornale OK';
            break;
          case '1':
            ej = 'Giornale prossimo ad esaurimento';
            break;
          default:
            ej = 'Stato giornale sconosciuto';
        }

        switch (printerStatus[2]) {
          case '0':
            cashDrawer = 'Cassetto aperto';
            break;
          case '1':
            cashDrawer = 'Cassetto chiuso';
            break;
          default:
            cashDrawer = 'Stato cassetto sconosciuto';
        }

        switch (printerStatus[3]) {
          case '1':
            receipt = 'Scontrino chiuso';
            break;
          default:
            receipt = 'Stato scontrino: ${printerStatus[3]}';
        }

        switch (printerStatus[4]) {
          case '0':
            mode = 'Registrazione';
            break;
          case '2':
            mode = 'Z';
            break;
          default:
            mode = 'Modalità: ${printerStatus[4]}';
        }
      }

      return {
        'printer': printer,
        'ej': ej,
        'cashDrawer': cashDrawer,
        'receipt': receipt,
        'mode': mode,
      };
    } catch (e) {
      log('Error decoding printer status: $e');
      return {};
    }
  }

  void _showRefundSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Reso Completato',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '€${transaction.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'La ricevuta di reso è stata stampata con successo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context, true); // Navigate back with refresh flag
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRefundErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFDC2626),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Errore',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}