import 'package:flutter/material.dart';
import '../models.dart';
import '../services/printing_service.dart';
import '../services/database_service.dart';
import '../services/payment_service.dart';
import '../services/iva_handler.dart';
import 'numeric_keyboard.dart';

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
  final Function(double, CartItem?)? onApplyDiscount;
  final double totalDiscount;

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
    this.onApplyDiscount,
    this.totalDiscount = 0,
  });

  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> {
  String? _selectedPaymentMethod;
  final PaymentService _paymentService = PaymentService();
  bool _isProcessingPayment = false;
  final ScrollController _scrollController = ScrollController();
  bool _hasMoreBelow = false;
  bool _hasMoreAbove = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    // Initial check after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScroll());
  }

  @override
  void didUpdateWidget(CartPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-check scroll when items change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // If an item was added or an item was updated (e.g. quantity changed)
      // we scroll to the bottom to show the "active" part of the cart
      _scrollToBottom();
      _checkScroll();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Delay slightly to ensure layout is complete
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    _checkScroll();
  }

  void _checkScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    final hasMoreBelow = maxScroll > currentScroll + 10;
    final hasMoreAbove = currentScroll > 10;

    if (hasMoreBelow != _hasMoreBelow || hasMoreAbove != _hasMoreAbove) {
      setState(() {
        _hasMoreBelow = hasMoreBelow;
        _hasMoreAbove = hasMoreAbove;
      });
    }
  }

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

  bool get _isWideScreen => MediaQuery.of(context).size.width >= 768;

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

void _showDiscountModal({CartItem? preselectedItem, bool isTotal = false}) {
  if (widget.onApplyDiscount == null || widget.cartItems.isEmpty) return;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      CartItem? selectedItem = preselectedItem;
      String discountValue = '';
      bool isTotalDiscount = isTotal || preselectedItem == null;

      if (isTotalDiscount && widget.totalDiscount > 0) {
        discountValue = widget.totalDiscount.toStringAsFixed(0);
      } else if (!isTotalDiscount &&
          selectedItem != null &&
          selectedItem.discount > 0) {
        discountValue = selectedItem.discount.toStringAsFixed(0);
      }

      return StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420), // Added constraint
              padding: const EdgeInsets.all(20), // Reduced padding
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Applica Sconto',
                          style: TextStyle(
                            fontSize: 18, // Reduced
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.close, size: 16),
                          ),
                          style: IconButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16), // Reduced

                    // Discount Type Selector
                    Container(
                      height: 40, // Reduced
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () =>
                                  setModalState(() => isTotalDiscount = true),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isTotalDiscount
                                      ? const Color(0xFF4361EE)
                                      : Colors.transparent,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    bottomLeft: Radius.circular(8),
                                  ),
                                  border: isTotalDiscount
                                      ? null
                                      : Border(
                                          right: BorderSide(
                                            color: Colors.grey.shade200,
                                            width: 1,
                                          ),
                                        ),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Totale',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isTotalDiscount
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setModalState(() {
                                isTotalDiscount = false;
                                selectedItem ??= widget.cartItems.isNotEmpty
                                    ? widget.cartItems.first
                                    : null;
                              }),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: !isTotalDiscount
                                      ? const Color(0xFF4361EE)
                                      : Colors.transparent,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Articolo',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: !isTotalDiscount
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: !isTotalDiscount ? 44 : 0,
                      margin: EdgeInsets.only(top: !isTotalDiscount ? 10 : 0),
                      child: Visibility(
                        visible: !isTotalDiscount,
                        child: Container(
                          height: 40, // Reduced
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                            color: Colors.white,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<CartItem>(
                              value: selectedItem,
                              items: widget.cartItems.map((item) {
                                return DropdownMenuItem(
                                  value: item,
                                  child: Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setModalState(() => selectedItem = val),
                              isExpanded: true,
                              hint: Text(
                                'Seleziona articolo',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                              style: const TextStyle(color: Colors.black87),
                              icon: Icon(Icons.arrow_drop_down,
                                  size: 18, color: Colors.grey.shade600),
                              iconSize: 20,
                              dropdownColor: Colors.white,
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Current Discount Display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'SCONTO APPLICATO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            discountValue.isEmpty ? '0%' : '$discountValue%',
                            style: const TextStyle(
                              fontSize: 28, // Reduced
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4361EE),
                              height: 1.2,
                            ),
                          ),
                          if (discountValue.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                isTotalDiscount
                                    ? 'Sconto totale'
                                    : 'Sconto articolo',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Keypad Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.6, // Adjusted for better fit
                        crossAxisSpacing: 8, // Reduced
                        mainAxisSpacing: 8, // Reduced
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        String label = '';
                        IconData? icon;
                        Color bgColor = Colors.white;
                        Color textColor = Colors.grey.shade900;
                        double fontSize = 16; // Reduced

                        if (index < 9) {
                          label = '${index + 1}';
                        } else if (index == 9) {
                          label = 'C';
                          bgColor = Colors.red.shade50;
                          textColor = Colors.red;
                          fontSize = 14;
                        } else if (index == 10) {
                          label = '0';
                        } else if (index == 11) {
                          icon = Icons.backspace_outlined;
                          bgColor = Colors.grey.shade100;
                          textColor = Colors.grey.shade700;
                        }

                        return Material(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                          elevation: 0.5,
                          shadowColor: Colors.black.withOpacity(0.03),
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                if (label == 'C') {
                                  discountValue = '';
                                } else if (icon != null) {
                                  if (discountValue.isNotEmpty) {
                                    discountValue = discountValue.substring(
                                        0, discountValue.length - 1);
                                  }
                                } else if (label.isNotEmpty &&
                                    discountValue.length < 3) {
                                  discountValue += label;
                                  if (double.parse(discountValue) > 100) {
                                    discountValue = '100';
                                  }
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 0.8,
                                ),
                              ),
                              child: Center(
                                child: icon != null
                                    ? Icon(icon,
                                        size: 18, // Reduced
                                        color: textColor)
                                    : Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Buttons Section - Now visible and properly sized
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40, // Compact size
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                    color: Colors.grey.shade300, width: 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text(
                                'Annulla',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 40, // Compact size
                            child: ElevatedButton(
                              onPressed: () {
                                double d = double.tryParse(discountValue) ?? 0;
                                if (isTotalDiscount) {
                                  widget.onApplyDiscount?.call(d, null);
                                  Navigator.pop(context);
                                } else if (selectedItem != null) {
                                  widget.onApplyDiscount
                                      ?.call(d, selectedItem);
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4361EE),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text(
                                'Applica',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
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
            decoration: const BoxDecoration(
              color: surfaceColor,
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
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
                        const Text(
                          'Ordine Corrente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          '${widget.totalItems} articol${widget.totalItems != 1 ? 'i' : 'o'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
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
          ),

          // Cart content
          Expanded(
            child: widget.cartItems.isEmpty
                ? _buildEmptyState()
                : _buildCartItems(),
          ),

          // Keypad (Bottom - for wide screens)
          if (_isWideScreen)
            Container(
              height: 420, // Increased from 360
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: borderColor, width: 1)),
              ),
              child: NumericKeypad(
                onNumberTap: widget.onNumberTap,
                onClear: widget.onClear,
                onBackspace: widget.onBackspace,
                onXTap: widget.onXTap,
                onPayment: () => _processPayment(widget.totalAmount),
                onPreAccount: widget.onPrint,
                totalAmount: widget.totalAmount,
                selectedPaymentMethod:
                    (widget.cartItems.isEmpty) ? null : _selectedPaymentMethod,
                onShowPaymentModal: () => _showPaymentMethodModal(context),
                onTotalLongPress: () => _showDiscountModal(isTotal: true),
              ),
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
            const Text(
              'Carrello Vuoto',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aggiungi articoli per iniziare',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (!_isWideScreen) ...[
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
            ]
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
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  itemCount: widget.cartItems.length,
                  itemBuilder: (context, index) {
                    final item = widget.cartItems[index];
                    return Column(
                      children: [
                        _buildCartItem(item),
                        // Add bottom border separator for all items except the last one
                        if (index < widget.cartItems.length - 1)
                          Container(
                            height: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            color: borderColor.withOpacity(0.5),
                          ),
                      ],
                    );
                  },
                ),
              ),
              
              // Scroll Up Indicator Tag
              if (_hasMoreAbove && _isWideScreen)
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: () {
                      _scrollController.animateTo(
                        _scrollController.offset - 100,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
                    child: AnimatedOpacity(
                      opacity: _hasMoreAbove ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(139, 67, 98, 238),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 5,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_up_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),

              // Scroll Down Indicator Tag
              if (_hasMoreBelow && _isWideScreen)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: () {
                      _scrollController.animateTo(
                        _scrollController.offset + 100,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
                    child: AnimatedOpacity(
                      opacity: _hasMoreBelow ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(139, 67, 98, 238),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 5,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Order Summary (only show if NOT wide screen, since keypad is shown on wide screens)
        if (!_isWideScreen) _buildOrderSummary(),
      ],
    );
  }

  void _showItemActionsModal(CartItem item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.product.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.percent_rounded,
                      label: 'Sconto',
                      color: primaryColor,
                      onTap: () {
                        Navigator.pop(context);
                        _showDiscountModal(preselectedItem: item, isTotal: false);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.delete_outline_rounded,
                      label: 'Rimuovi',
                      color: dangerColor,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onRemoveItem(item.product.id);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Dismissible(
      key: Key(item.product.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.8),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.more_horiz_rounded,
              color: Colors.white,
              size: 28,
            ),
            Text(
              'Azioni',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        _showItemActionsModal(item);
        return false;
      },
      child: CartItemTile(
        item: item,
        onUpdateQuantity: widget.onUpdateQuantity,
        onRemove: widget.onRemoveItem,
        colors: const _CartColors(
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
        border: const Border(top: BorderSide(color: borderColor, width: 1)),
        borderRadius: _isWideScreen
            ? BorderRadius.zero
            : const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
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
          // Total Display
           if (_selectedPaymentMethod != null)
            Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: successColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: successColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Metodo: ${_getDisplayPaymentMethod(_selectedPaymentMethod!)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: successColor,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _showPaymentMethodModal(context),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 20,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          GestureDetector(
            onLongPress: () => _showDiscountModal(isTotal: true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Column(
                children: [
                  if (widget.totalDiscount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotale',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                        Text(
                          '€${(total / (1 - (widget.totalDiscount / 100))).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sconto (${widget.totalDiscount.toStringAsFixed(0)}%)',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: successColor,
                          ),
                        ),
                        Text(
                          '- €${((total / (1 - (widget.totalDiscount / 100))) - total).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: successColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTALE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                      Text(
                        '€${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
            const SizedBox(height: 14),

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
                        side: const BorderSide(color: borderColor, width: 1.5),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              if (widget.onPrint != null) const SizedBox(width: 8),
              // Pagare Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectedPaymentMethod != null
                      ? () => _processPayment(total)
                      : () => _showPaymentMethodModal(context),
                  icon: Icon(
                    _selectedPaymentMethod != null
                        ? Icons.check_circle
                        : Icons.payment_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _selectedPaymentMethod != null ? 'Pagare' : 'Pagamento',
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
        icon: const Icon(
          Icons.delete_forever_rounded,
          color: dangerColor,
          size: 36,
        ),
        title: const Text(
          'Svuota Ordine',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
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
                    side: const BorderSide(color: borderColor),
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
      isScrollControlled:
          true, // Changed to true for better large screen handling
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: 600, // Limit width for larger screens
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Centered handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header with title and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Metodo di Pagamento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded,
                        color: textPrimary.withOpacity(0.6)),
                    iconSize: 24,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Responsive payment options grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 400 ? 4 : 3;
                  final childAspectRatio =
                      constraints.maxWidth > 400 ? 0.95 : 0.9;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                    padding: const EdgeInsets.only(bottom: 8),
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
                        color: const Color(0xFFFFD166),
                      ),
                      _buildCompactPaymentOption(
                        icon: Icons.phone_android_rounded,
                        title: 'Satispay',
                        value: 'SATISPAY',
                        color: const Color(0xFF3A0CA3),
                      ),
                      _buildCompactPaymentOption(
                        icon: Icons.account_balance_rounded,
                        title: 'Bonifico',
                        value: 'TRANSFER',
                        color: const Color(0xFF4CC9F0),
                      ),
                      _buildCompactPaymentOption(
                        icon: Icons.wallet_rounded,
                        title: 'Mobile',
                        value: 'MOBILE',
                        color: const Color(0xFF7209B7),
                      ),
                    ],
                  );
                },
              ),

              // Optional: Add a hint for scroll if needed
              if (MediaQuery.of(context).size.height < 500)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: borderColor.withOpacity(0.5),
                    size: 20,
                  ),
                ),
            ],
          ),
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
              style: const TextStyle(
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
    if (_isProcessingPayment) return;

    final paymentMethod = _selectedPaymentMethod ?? 'CONTANTE';
    setState(() => _isProcessingPayment = true);

    BuildContext? loaderContext;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          loaderContext = dialogContext;
          return Dialog(
            backgroundColor: surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Stampa in corso...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Attendere il completamento',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    final errors = <String>[];
    bool hasPaperWarning = false;
    Map<String, String> statusSegments = {};
    Map<String, dynamic> fiscalData = {};
    int transactionId = 0;
    String? responseBody;

    try {
      if (widget.onPaymentProcessed != null) {
        await widget.onPaymentProcessed!(paymentMethod);
      }

      final items = widget.cartItems.map((cartItem) {
        final itemMap = {
          'name': cartItem.product.name,
          'price': cartItem.product.price,
          'quantity': cartItem.quantity,
          'discount': cartItem.discount,
        };
        if (cartItem.product.iva != null) {
          final ivaCode = SimpleIvaManager.getCodeByRate(cartItem.product.iva!);
          if (ivaCode != null) {
            itemMap['ivaCode'] = ivaCode;
          }
        }
        return itemMap;
      }).toList();

      responseBody = await _paymentService.printReceiptAndGetResponse(
        items,
        total,
        paymentMethod,
        totalDiscount: widget.totalDiscount,
      );

      if (responseBody != null) {
        fiscalData = _paymentService.parsePrinterResponse(responseBody);
        statusSegments =
            (fiscalData['statusSegments'] as Map<String, String>?) ?? {};

        if (statusSegments.isNotEmpty) {
          _paymentService.validatePrinterStatus(statusSegments, errors);
          hasPaperWarning = _paymentService.checkPaperWarning(statusSegments);
        }

        if (hasPaperWarning && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Attenzione: Carta in esaurimento. Sostituire il rotolo al più presto.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }

        if (errors.isEmpty) {
          transactionId = await _paymentService.saveTransaction(
            total,
            paymentMethod,
            widget.cartItems,
            discount: widget.totalDiscount,
          );

          if (transactionId > 0) {
            await _paymentService.updateTransactionWithFiscalData(
              transactionId,
              fiscalData,
            );
          }

          widget.onClearCart();
          setState(() => _selectedPaymentMethod = null);
        }
      }
    } finally {
      if (loaderContext != null) {
        Navigator.of(loaderContext!).pop();
      }
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 420, // 👈 keeps dialog compact on large screens
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
                    color: (responseBody != null && errors.isEmpty)
                        ? successColor.withOpacity(0.1)
                        : const Color(0xFFFCA5A5).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    (responseBody != null && errors.isEmpty)
                        ? Icons.check_circle_rounded
                        : Icons.warning_rounded,
                    color: (responseBody != null && errors.isEmpty)
                        ? successColor
                        : const Color(0xFFDC2626),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  (responseBody != null && errors.isEmpty)
                      ? 'Ordine Completato!'
                      : 'Avvertenza Stampante',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                if (responseBody != null && errors.isEmpty)
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
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: successColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getDisplayPaymentMethod(paymentMethod),
                          style: const TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFDC2626),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (responseBody == null)
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Errore Stampa:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Lo scontrino non è stato stampato. La stampante non risponde.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                ),
                              ),
                              SizedBox(height: 12),
                            ],
                          ),
                        if (errors.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Errori Stampante:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  errors.join('\n'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (responseBody != null && errors.isEmpty)
                              ? primaryColor
                              : const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      (responseBody != null && errors.isEmpty)
                          ? 'Nuovo Ordine'
                          : 'Annulla',
                      style: const TextStyle(
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
      ),
    );
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
    final isPhone = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: const BoxDecoration(
        color: Colors.transparent,
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
                    fontSize: isPhone ? 13 : 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.discount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-${item.discount.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.success,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '€${(item.product.price * item.quantity).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                            color: colors.textSecondary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
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
                  fontSize: isPhone ? 15 : 18,
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
                  width: 44,
                  height: 40,
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
                      fontSize: isPhone ? 13 : 16,
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
