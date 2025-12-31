import 'package:flutter/material.dart';

class NumericKeypad extends StatefulWidget {
  final Function(String) onNumberTap;
  final VoidCallback onClear;
  final VoidCallback onBackspace;
  final VoidCallback onXTap;
  final VoidCallback? onPayment;
  final VoidCallback? onPreAccount;
  final bool isCompact;
  final double totalAmount;
  final String? selectedPaymentMethod;
  final VoidCallback? onShowPaymentModal;
  final VoidCallback? onTotalLongPress;

  const NumericKeypad({
    super.key,
    required this.onNumberTap,
    required this.onClear,
    required this.onBackspace,
    required this.onXTap,
    this.onPayment,
    this.onPreAccount,
    this.isCompact = false,
    required this.totalAmount,
    this.selectedPaymentMethod,
    this.onShowPaymentModal,
    this.onTotalLongPress,
  });

  @override
  State<NumericKeypad> createState() => _NumericKeypadState();
}

class _NumericKeypadState extends State<NumericKeypad> {
  String? _pressedKey;
  bool get _isWideScreen => MediaQuery.of(context).size.width >= 768;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 450;

        final buttonSpacing = isSmallScreen ? 2.5 : 4.0;
        final fontSize = isSmallScreen ? 22.0 : 24.0;
        final cornerRadius = 12.0;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(isSmallScreen ? 0 : 16),
            ),
          ),
      child: Column(
        children: [
          // Top Section: Total Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Total Display
                Expanded(
                  child: GestureDetector(
                    onLongPress: widget.onTotalLongPress,
                    child: Container(
                      height: 35,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4361EE).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF4361EE).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTALE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '€${widget.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4361EE),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (widget.selectedPaymentMethod != null) ...[
                  const SizedBox(width: 12),

                  // Payment Method Tag
                  GestureDetector(
                    onTap: widget.onShowPaymentModal,
                    child: Container(
                      height: 35,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06D6A0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF06D6A0).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: const Color(0xFF06D6A0),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getPaymentMethodLabel(widget.selectedPaymentMethod!),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF06D6A0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Main Keypad - Numeric Buttons
          Expanded(
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 9 : 12),
              child: Column(
                children: [
                  // Row 1: 7 8 9 C
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        _buildKey('7', buttonSpacing, fontSize, cornerRadius),
                        SizedBox(width: buttonSpacing),
                        _buildKey('8', buttonSpacing, fontSize, cornerRadius),
                        SizedBox(width: buttonSpacing),
                        _buildKey('9', buttonSpacing, fontSize, cornerRadius),
                        SizedBox(width: buttonSpacing),
                        _buildSpecialKey(
                          label: 'C',
                          backgroundColor: const Color(0xFFEF476F),
                          textColor: Colors.white,
                          onTap: widget.onClear,
                          spacing: buttonSpacing,
                          fontSize: fontSize - 2,
                          cornerRadius: cornerRadius,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: buttonSpacing),
                  
                  // Row 2 & 3: 4-6 and 1-3 with X spanning both
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    _buildKey('4', buttonSpacing, fontSize, cornerRadius),
                                    SizedBox(width: buttonSpacing),
                                    _buildKey('5', buttonSpacing, fontSize, cornerRadius),
                                    SizedBox(width: buttonSpacing),
                                    _buildKey('6', buttonSpacing, fontSize, cornerRadius),
                                  ],
                                ),
                              ),
                              SizedBox(height: buttonSpacing),
                              Expanded(
                                child: Row(
                                  children: [
                                    _buildKey('1', buttonSpacing, fontSize, cornerRadius),
                                    SizedBox(width: buttonSpacing),
                                    _buildKey('2', buttonSpacing, fontSize, cornerRadius),
                                    SizedBox(width: buttonSpacing),
                                    _buildKey('3', buttonSpacing, fontSize, cornerRadius),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: buttonSpacing),
                        _buildSpecialKey(
                          label: 'X',
                          backgroundColor: const Color(0xFF4361EE),
                          textColor: Colors.white,
                          onTap: widget.onXTap,
                          spacing: buttonSpacing,
                          fontSize: fontSize - 2,
                          cornerRadius: cornerRadius,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: buttonSpacing),
                  
                  // Row 4: 0 . 00
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildKey('0', buttonSpacing, fontSize, cornerRadius),
                        ),
                        SizedBox(width: buttonSpacing),
                        _buildSpecialKey(
                          label: '.',
                          backgroundColor: Colors.white,
                          textColor: Colors.grey.shade700,
                          onTap: () => widget.onNumberTap('.'),
                          spacing: buttonSpacing,
                          fontSize: fontSize,
                          cornerRadius: cornerRadius,
                        ),
                        SizedBox(width: buttonSpacing),
                        _buildSpecialKey(
                          label: '00',
                          backgroundColor: Colors.white,
                          textColor: Colors.grey.shade700,
                          onTap: () => widget.onNumberTap('00'),
                          spacing: buttonSpacing,
                          fontSize: fontSize - 2,
                          cornerRadius: cornerRadius,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Section: Preconto and Pagamento Buttons
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Preconto Button
                Expanded(
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: widget.onPreAccount,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 18,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'PRECONTO',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Payment Button (Pagamento/Pagare)
                Expanded(
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.only(left: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF06D6A0).withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: const Color(0xFF06D6A0),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: (_isWideScreen)?widget.selectedPaymentMethod != null
                            ? widget.onPayment
                            : widget.onShowPaymentModal:widget.onPayment,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.selectedPaymentMethod != null
                                    ? Icons.check_circle
                                    : Icons.payment,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.selectedPaymentMethod != null
                                    ? 'PAGARE'
                                    : 'PAGAMENTO',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
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
      },
    );
  }

  Widget _buildKey(
    String number,
    double spacing,
    double fontSize,
    double cornerRadius,
  ) {
    final isPressed = _pressedKey == number;

    return Expanded(
      child: Container(
        margin: EdgeInsets.all(spacing),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cornerRadius),
          boxShadow: [
            if (!isPressed)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Material(
          color: isPressed ? const Color(0xFFE5E7EB) : Colors.white,
          borderRadius: BorderRadius.circular(cornerRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(cornerRadius),
            onTapDown: (_) {
              setState(() => _pressedKey = number);
            },
            onTapUp: (_) {
              setState(() => _pressedKey = null);
              widget.onNumberTap(number);
            },
            onTapCancel: () {
              setState(() => _pressedKey = null);
            },
            child: Container(
              alignment: Alignment.center,
              child: Text(
                number,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey({
    String? label,
    IconData? icon,
    Color backgroundColor = Colors.white,
    Color textColor = const Color(0xFF111827),
    VoidCallback? onTap,
    double spacing = 4.0,
    double fontSize = 16.0,
    double cornerRadius = 8.0,
  }) {
    final isPressed = _pressedKey == label;

    return Expanded(
      child: Container(
        margin: EdgeInsets.all(spacing),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cornerRadius),
          boxShadow: [
            if (!isPressed && backgroundColor == Colors.white)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Material(
          color: isPressed
              ? (backgroundColor == Colors.white
                  ? const Color(0xFFE5E7EB)
                  : backgroundColor.withOpacity(0.8))
              : backgroundColor,
          borderRadius: BorderRadius.circular(cornerRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(cornerRadius),
            onTapDown: (_) {
              if (label != null) setState(() => _pressedKey = label);
            },
            onTapUp: (_) {
              setState(() => _pressedKey = null);
              onTap?.call();
            },
            onTapCancel: () {
              setState(() => _pressedKey = null);
            },
            onTap: onTap,
            child: Container(
              alignment: Alignment.center,
              child: icon != null
                  ? Icon(
                      icon,
                      color: textColor,
                      size: fontSize,
                    )
                  : Text(
                      label!,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'CARTA':
        return 'Carta';
      case 'CONTANTE':
        return 'Contanti';
      case 'TICKET':
        return 'Buono';
      case 'SATISPAY':
        return 'Satispay';
      case 'TRANSFER':
        return 'Bonifico';
      case 'MOBILE':
        return 'Mobile';
      default:
        return method;
    }
  }
}