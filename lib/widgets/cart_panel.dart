import 'package:flutter/material.dart';
import '../models.dart';
import '../services/printing_service.dart';

class CartPanel extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalAmount;
  final int totalItems;
  final Function(String, int) onUpdateQuantity;
  final Function(String) onRemoveItem;
  final VoidCallback onClearCart;
  final String keypadNumber;
  final Function(String) onNumberTap;
  final VoidCallback onClear;
  final VoidCallback onBackspace;
  final VoidCallback onXTap;
  final bool xPressed;
  final VoidCallback? onCloseCart;
  final VoidCallback? onOpenKeypad;
  final Future<void> Function()? onPrint;
  final Future<void> Function(String)? onPaymentProcessed;

  const CartPanel({
    super.key,
    required this.cartItems,
    required this.totalAmount,
    required this.totalItems,
    required this.onUpdateQuantity,
    required this.onRemoveItem,
    required this.onClearCart,
    required this.keypadNumber,
    required this.onNumberTap,
    required this.onClear,
    required this.onBackspace,
    required this.onXTap,
    required this.xPressed,
    this.onCloseCart,
    this.onOpenKeypad,
    this.onPrint,
    this.onPaymentProcessed,
  });

  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> {
  String? _selectedPaymentMethod;
  
  // Modern minimalist color palette
  static const Color primaryColor = Color(0xFF4361EE); // Primary blue
  static const Color successColor = Color(0xFF06D6A0); // Success green
  static const Color dangerColor = Color(0xFFEF476F); // Danger red
  static const Color backgroundColor = Color(0xFFF8F9FA); // Light background
  static const Color surfaceColor = Colors.white; // Card surface
  static const Color textPrimary = Color(0xFF212529); // Primary text
  static const Color textSecondary = Color(0xFF6C757D); // Secondary text
  static const Color borderColor = Color(0xFFE9ECEF); // Border color
  static const Color hoverColor = Color(0xFFE9F5FF); // Hover color

  String _getDisplayPaymentMethod(String method) {
    switch (method) {
      case 'CARTA':
        return 'Carta di Credito';
      case 'CONTANTE':
        return 'Contanti';
      case 'TICKET':
        return 'Buono';
      case 'SATISPAY':
        return 'Satispay';
      case 'TRANSFER':
        return 'Bonifico';
      case 'MOBILE':
        return 'Pagamento Mobile';
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          left: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Minimalist header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Back button for mobile
                    if (widget.onCloseCart != null)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          onPressed: widget.onCloseCart,
                          icon: const Icon(Icons.arrow_back_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: hoverColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(6),
                          ),
                          iconSize: 18,
                        ),
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ordine Corrente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          '${widget.totalItems} articolo${widget.totalItems != 1 ? 'i' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Keypad button
                    if (widget.onOpenKeypad != null)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          onPressed: widget.onOpenKeypad,
                          icon: const Icon(Icons.dialpad_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: hoverColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(8),
                          ),
                          tooltip: 'Apri tastiera',
                          iconSize: 18,
                        ),
                      ),
                    // Clear cart button
                    if (widget.cartItems.isNotEmpty)
                      IconButton(
                        onPressed: () => _showClearCartDialog(),
                        icon: const Icon(Icons.delete_outline_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: dangerColor.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(8),
                          foregroundColor: dangerColor,
                        ),
                        iconSize: 18,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Cart content
          Expanded(
            child: widget.cartItems.isEmpty
                ? _buildEmptyState()
                : _buildCartItems(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: surfaceColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.1),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 40,
                color: primaryColor.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Carrello Vuoto',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aggiungi articoli per iniziare',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (widget.onOpenKeypad != null)
              ElevatedButton.icon(
                onPressed: widget.onOpenKeypad,
                icon: const Icon(Icons.dialpad_rounded, size: 16),
                label: const Text(
                  'Apri Tastiera',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItems() {
    return Column(
      children: [
        // Cart Items List
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: widget.cartItems.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = widget.cartItems[index];
                return _buildCartItem(item);
              },
            ),
          ),
        ),

        // Order Summary
        _buildOrderSummary(),
      ],
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Dismissible(
      key: Key(item.product.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: dangerColor,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const Icon(
          Icons.delete_forever_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: dangerColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rimuovi Articolo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            content: Text(
              'Rimuovere "${item.product.name}" dall\'ordine?',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: textSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: dangerColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Rimuovi'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => widget.onRemoveItem(item.product.id),
      child: CartItemTile(
        item: item,
        onUpdateQuantity: widget.onUpdateQuantity,
        onRemove: widget.onRemoveItem,
        colors: _CartColors(
          primary: primaryColor,
          success: successColor,
          surface: surfaceColor,
          border: borderColor,
          hover: hoverColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final total = widget.totalAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Total Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTALE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              Text(
                '€${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payment Method Section
          if (_selectedPaymentMethod != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: successColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: successColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.payment_rounded,
                    color: successColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pagamento',
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _getDisplayPaymentMethod(_selectedPaymentMethod!),
                          style: TextStyle(
                            fontSize: 14,
                            color: successColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showPaymentMethodModal(context),
                    icon: Icon(
                      Icons.edit_rounded,
                      color: textSecondary,
                      size: 16,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action Buttons
          Row(
            children: [
              // Print Button
              if (widget.onPrint != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onPrint,
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text('Stampa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: surfaceColor,
                      foregroundColor: textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: borderColor, width: 1),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              if (widget.onPrint != null) const SizedBox(width: 8),
              // Payment/Process Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectedPaymentMethod != null
                      ? () => _processPayment(total)
                      : () => _showPaymentMethodModal(context),
                  icon: Icon(
                    _selectedPaymentMethod != null
                        ? Icons.check_circle_rounded
                        : Icons.payment_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _selectedPaymentMethod != null
                        ? 'Pagare'
                        : 'Pagamento',
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedPaymentMethod != null
                        ? successColor
                        : primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        icon: Icon(
          Icons.delete_forever_rounded,
          color: dangerColor,
          size: 36,
        ),
        title: Text(
          'Svuota Ordine',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Rimuovere tutti gli articoli dall\'ordine?',
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: borderColor),
                  ),
                  child: const Text('Annulla'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onClearCart();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dangerColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Svuota'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Metodo di Pagamento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Payment options
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.9,
              children: [
                _buildCompactPaymentOption(
                  icon: Icons.credit_card_rounded,
                  title: 'Carta',
                  value: 'CARTA',
                  color: primaryColor,
                ),
                _buildCompactPaymentOption(
                  icon: Icons.money_rounded,
                  title: 'Contanti',
                  value: 'CONTANTE',
                  color: successColor,
                ),
                _buildCompactPaymentOption(
                  icon: Icons.receipt_long_rounded,
                  title: 'Buono',
                  value: 'TICKET',
                  color: Color(0xFFFFD166),
                ),
                _buildCompactPaymentOption(
                  icon: Icons.phone_android_rounded,
                  title: 'Satispay',
                  value: 'SATISPAY',
                  color: Color(0xFF3A0CA3),
                ),
                _buildCompactPaymentOption(
                  icon: Icons.account_balance_rounded,
                  title: 'Bonifico',
                  value: 'TRANSFER',
                  color: Color(0xFF4CC9F0),
                ),
                _buildCompactPaymentOption(
                  icon: Icons.wallet_rounded,
                  title: 'Mobile',
                  value: 'MOBILE',
                  color: Color(0xFF7209B7),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactPaymentOption({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPaymentMethod = value);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 25.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(double total) async {
    final paymentMethod = _selectedPaymentMethod ?? 'CONTANTE';

    if (widget.onPaymentProcessed != null) {
      await widget.onPaymentProcessed!(paymentMethod);
    }

    final items = widget.cartItems
        .map((cartItem) => {
          'name': cartItem.product.name,
          'price': cartItem.product.price,
          'quantity': cartItem.quantity,
        })
        .toList();

    final printingService = PrintingService();
    await printingService.printEpsonReceiptAutomatic(
      items,
      total,
      paymentMethod,
    );

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: successColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: successColor,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ordine Completato!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hoverColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '€${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: successColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDisplayPaymentMethod(paymentMethod),
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onClearCart();
                      setState(() => _selectedPaymentMethod = null);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Nuovo Ordine',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

class _CartColors {
  final Color primary;
  final Color success;
  final Color surface;
  final Color border;
  final Color hover;
  final Color textPrimary;
  final Color textSecondary;

  const _CartColors({
    required this.primary,
    required this.success,
    required this.surface,
    required this.border,
    required this.hover,
    required this.textPrimary,
    required this.textSecondary,
  });
}

class CartItemTile extends StatelessWidget {
  final CartItem item;
  final Function(String, int) onUpdateQuantity;
  final Function(String) onRemove;
  final _CartColors colors;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onUpdateQuantity,
    required this.onRemove,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border, width: 1),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product name (bigger text)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: TextStyle(
                    fontSize: 16, // Increased from 13
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Price (bigger text, single price - total price only)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '€${item.total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18, // Increased from 14
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Quantity controller (larger, better placed)
          Container(
            decoration: BoxDecoration(
              color: colors.hover,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Decrease button
                Material(
                  color: Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  child: InkWell(
                    onTap: () =>
                        onUpdateQuantity(item.product.id, item.quantity - 1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    child: Container(
                      width: 40, // Increased width
                      height: 40, // Increased height
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.remove_rounded,
                        size: 20, // Increased icon size
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
                
                // Quantity display
                Container(
                  width: 44, // Wider display
                  height: 40, // Taller display
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      vertical: BorderSide(color: colors.border),
                    ),
                    color: colors.surface,
                  ),
                  child: Text(
                    item.quantity.toString(),
                    style: TextStyle(
                      fontSize: 16, // Increased from 13
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                
                // Increase button
                Material(
                  color: Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  child: InkWell(
                    onTap: () =>
                        onUpdateQuantity(item.product.id, item.quantity + 1),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    child: Container(
                      width: 40, // Increased width
                      height: 40, // Increased height
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.add_rounded,
                        size: 20, // Increased icon size
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}