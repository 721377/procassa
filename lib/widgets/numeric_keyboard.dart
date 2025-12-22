import 'package:flutter/material.dart';

class NumericKeypad extends StatelessWidget {
  final Function(String) onNumberTap;
  final VoidCallback onClear;
  final VoidCallback onBackspace;
  final VoidCallback onXTap;
  final bool isCompact;

  const NumericKeypad({
    super.key,
    required this.onNumberTap,
    required this.onClear,
    required this.onBackspace,
    required this.onXTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 768;
    final buttonPadding = isSmallScreen ? 6.0 : 12.0;
    final fontSize = isSmallScreen ? 15.0 : 19.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isSmallScreen ? BorderRadius.circular(0) : BorderRadius.circular(8),
        border: isSmallScreen ? null : Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildKey('1', buttonPadding, fontSize),
              _buildKey('2', buttonPadding, fontSize),
              _buildKey('3', buttonPadding, fontSize),
            ],
          ),
          Row(
            children: [
              _buildKey('4', buttonPadding, fontSize),
              _buildKey('5', buttonPadding, fontSize),
              _buildKey('6', buttonPadding, fontSize),
            ],
          ),
          Row(
            children: [
              _buildKey('7', buttonPadding, fontSize),
              _buildKey('8', buttonPadding, fontSize),
              _buildKey('9', buttonPadding, fontSize),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _buildSpecialKey(
                  label: 'Canc',
                  backgroundColor: const Color(0xFFFEE2E2),
                  textColor: const Color(0xFFDC2626),
                  onTap: onClear,
                  padding: buttonPadding,
                  fontSize: fontSize - 2,
                ),
              ),
              Expanded(
                child: _buildKey('0', buttonPadding, fontSize),
              ),
              Expanded(
                child: _buildSpecialKey(
                  label: 'X',
                  backgroundColor: const Color(0xFFDEF7EC),
                  textColor: const Color(0xFF059669),
                  onTap: onXTap,
                  padding: buttonPadding,
                  fontSize: fontSize - 2,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _buildSpecialKey(
                  label: '.',
                  onTap: () => onNumberTap('.'),
                  padding: buttonPadding,
                  fontSize: fontSize,
                ),
              ),
              Expanded(
                child: _buildSpecialKey(
                  icon: Icons.backspace_outlined,
                  onTap: onBackspace,
                  padding: buttonPadding,
                  fontSize: fontSize,
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(1),
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String number, double padding, double fontSize) {
    return Expanded(
      child: Container(
      
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD1D5DB), width: 0.5),
        ),
        child: TextButton(
          onPressed: () => onNumberTap(number),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: padding),
            shape: const RoundedRectangleBorder(),
            backgroundColor: Colors.white,
          ),
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
    );
  }

  Widget _buildSpecialKey({
    String? label,
    IconData? icon,
    Color backgroundColor = Colors.white,
    Color textColor = const Color(0xFF111827),
    VoidCallback? onTap,
    double padding = 12.0,
    double fontSize = 16.0,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD1D5DB), width: 0.5),
         color: backgroundColor, 
      ),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: padding),
          shape: const RoundedRectangleBorder(),
          // backgroundColor: backgroundColor,
        ),
        child: icon != null
            ? Icon(icon, color: textColor, size: fontSize)
            : Text(
                label!,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
      ),
    );
  }
}