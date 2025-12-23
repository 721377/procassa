// screens/pos_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:procassa/screens/statistiche_screen.dart';
import 'package:procassa/screens/transazioni_screen.dart';
import 'package:procassa/widgets/numeric_keyboard.dart';
import '../models.dart';
import '../widgets/cart_panel.dart';
import '../widgets/product_card.dart';
import '../services/cart_functions.dart';
import '../services/database_service.dart';
import '../services/printing_service.dart';
import '../services/payment_service.dart';
import 'stampanti_screen.dart';
import 'impostazioni_screen.dart';
import 'anagrafica_screen.dart';
import 'articoli_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final DatabaseService _db = DatabaseService();
  final PrintingService _printingService = PrintingService();
  final PaymentService _paymentService = PaymentService();

  List<Categoria> categories = [];
  List<Articolo> products = [];
  bool _isLoading = true;

  final List<CartItem> _cartItems = [];
  int? _selectedCategoriaId;
  final TextEditingController _searchController = TextEditingController();
  late bool _showCart;
  String _keypadFirstNumber = '';
  String _keypadSecondNumber = '';
  bool _keypadXPressed = false;
  bool _showKeypad = false;
  bool _keypadModeActive = false;
  final String _selectedMenu = 'pos';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _selectedPaymentMethod;
  static const Color surfaceColor = Colors.white; // Card surface
  static const Color textSecondary = Color(0xFF6C757D); // Secondary text
// Hover color

  @override
  void initState() {
    super.initState();
    _showCart = false;
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final categorie = await _db.getCategorias();
      final articoli = await _db.getArticoli();

      if (mounted) {
        setState(() {
          categories = categorie;
          products = articoli;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel caricamento: $e')),
        );
      }
    }
  }

  bool get _isSmallScreen => MediaQuery.of(context).size.width < 768;
  bool get _isMediumScreen =>
      MediaQuery.of(context).size.width >= 768 &&
      MediaQuery.of(context).size.width < 1024;
  bool get _isLargeScreen => MediaQuery.of(context).size.width >= 1024;

  double get totalAmount => _cartItems.fold(0, (sum, item) => sum + item.total);
  int get totalItems => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  void _addToCart(Product product, {int quantity = 1}) {
    setState(() {
      CartFunctions.addToCart(_cartItems, product, quantity: quantity);
    });
  }

  void _addToCartWithCustomPrice(Product product, double price) {
    setState(() {
      CartFunctions.addToCartWithCustomPrice(_cartItems, product, price);
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      CartFunctions.removeFromCart(_cartItems, productId);
      _clearKeypad();
    });
  }

  void _updateQuantity(String productId, int newQuantity) {
    setState(() {
      CartFunctions.updateQuantity(_cartItems, productId, newQuantity);
      _clearKeypad();
    });
  }

  void _clearCart() {
    setState(() {
      CartFunctions.clearCart(_cartItems);
      _clearKeypad();
    });
  }

  void _handleNumberInput(String number) {
    setState(() {
      if (_keypadXPressed) {
        _keypadSecondNumber += number;
      } else {
        _keypadFirstNumber += number;
      }
    });
  }

  void _clearKeypad() {
    setState(() {
      _keypadFirstNumber = '';
      _keypadSecondNumber = '';
      _keypadXPressed = false;
    });
  }

  void _handleBackspace() {
    setState(() {
      if (_keypadXPressed) {
        if (_keypadSecondNumber.isNotEmpty) {
          _keypadSecondNumber =
              _keypadSecondNumber.substring(0, _keypadSecondNumber.length - 1);
        }
      } else {
        if (_keypadFirstNumber.isNotEmpty) {
          _keypadFirstNumber =
              _keypadFirstNumber.substring(0, _keypadFirstNumber.length - 1);
        }
      }
    });
  }

  void _handleXPress() {
    setState(() {
      if (_keypadFirstNumber.isNotEmpty && !_keypadXPressed) {
        _keypadXPressed = true;
      }
    });
  }

  void _handleProductTapWithKeypad(Articolo articolo) {
    final hasFirstNumber = _keypadFirstNumber.isNotEmpty;
    final hasSecondNumber = _keypadSecondNumber.isNotEmpty;

    if (!hasFirstNumber) {
      _addToCartArticolo(articolo);
    } else if (_keypadXPressed && hasSecondNumber) {
      final quantity = int.tryParse(_keypadFirstNumber) ?? 1;
      final price = double.tryParse(_keypadSecondNumber) ?? articolo.prezzo;

      final product = Product(
        id: articolo.id.toString(),
        name: articolo.descrizione,
        category: articolo.categoriaId.toString(),
        price: price,
        description: articolo.descrizione,
      );

      setState(() {
        CartFunctions.addToCart(_cartItems, product, quantity: quantity);
      });
      _clearKeypad();
    } else if (_keypadXPressed && !hasSecondNumber) {
      final quantity = int.tryParse(_keypadFirstNumber) ?? 1;
      _addToCartArticolo(articolo, quantity: quantity);
      _clearKeypad();
    } else if (!_keypadXPressed && hasFirstNumber) {
      final price = double.tryParse(_keypadFirstNumber) ?? articolo.prezzo;

      final product = Product(
        id: articolo.id.toString(),
        name: articolo.descrizione,
        category: articolo.categoriaId.toString(),
        price: price,
        description: articolo.descrizione,
      );

      setState(() {
        CartFunctions.addToCart(_cartItems, product, quantity: 1);
      });
      _clearKeypad();
    }
  }

  Future<void> _handlePrint() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    try {
      final stampanti = await _db.getStampanti();

      if (stampanti.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No printers configured')),
          );
        }
        return;
      }

      final orderPrinters =
          stampanti.where((p) => p.printerCategory == 'Order').toList();

      if (orderPrinters.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No order printer configured'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
        return;
      }

      Stampante selectedPrinter = orderPrinters.firstWhere(
        (p) => p.isDefault == true,
        orElse: () => orderPrinters.first,
      );

      if (orderPrinters.length > 1 && mounted) {
        selectedPrinter = await showDialog<Stampante>(
              context: context,
              builder: (context) => StatefulBuilder(
                builder: (context, setState) => Dialog(
                  backgroundColor: Colors.white,
                  insetPadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Select Printer',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[900],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(Icons.close_rounded,
                                    size: 20, color: Colors.grey[600]),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose a printer for your order',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Printer List
                          Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                children: orderPrinters.map((printer) {
                                  final subtitle = printer.printerModel ==
                                          'Sunmi Pro'
                                      ? 'Sunmi Pro (Internal)'
                                      : (printer.orderPrinterType == 'IP'
                                          ? '${printer.indirizzoIp}:${printer.porta}'
                                          : printer.bluetoothAddress ??
                                              'Bluetooth');

                                  final isSelected = selectedPrinter == printer;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Material(
                                      color: isSelected
                                          ? Colors.blue.withOpacity(0.08)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            selectedPrinter = printer;
                                          });
                                          Navigator.pop(context, printer);
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          child: Row(
                                            children: [
                                              // Selection indicator
                                              Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? Colors.blue
                                                        : Colors.grey[400]!,
                                                    width: isSelected ? 6 : 2,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),

                                              // Printer info
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      printer.nome,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.grey[900],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      subtitle,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Status indicator
                                              if (isSelected)
                                                Icon(
                                                  Icons.check_circle_rounded,
                                                  color: Colors.blue,
                                                  size: 20,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),

                          // Cancel Button
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ) ??
            selectedPrinter;
      }

      final items = _cartItems
          .map((cartItem) => {
                'name': cartItem.product.name,
                'quantity': cartItem.quantity,
                'price': cartItem.product.price,
              })
          .toList();

      final subtotal = _cartItems.fold<double>(
        0.0,
        (sum, item) => sum + (item.product.price * item.quantity),
      );

      bool success = false;

      if (selectedPrinter.printerModel == 'Sunmi Pro') {
        success = await _printingService.printOrderViaSunmiPro(
          items,
          subtotal,
          8.0,
          businessName: selectedPrinter.nome,
        );
      } else if (selectedPrinter.orderPrinterType == 'Bluetooth') {
        success = await _printingService.printCommandViaBluetooth(
          selectedPrinter.bluetoothAddress ?? '',
          items,
          subtotal,
          8.0,
          businessName: selectedPrinter.nome,
        );
      } else {
        success = await _printingService.printCommand(
          selectedPrinter.indirizzoIp,
          items,
          subtotal,
          8.0,
          port: selectedPrinter.porta,
          businessName: selectedPrinter.nome,
        );
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order printed successfully'),
              backgroundColor: Color(0xFF059669),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to print order'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _showPaymentMethodModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Metodo di Pagamento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildPaymentOption('CARTA', Icons.credit_card_rounded, const Color(0xFF4361EE)),
                  _buildPaymentOption('CONTANTE', Icons.money_rounded, const Color(0xFF06D6A0)),
                  _buildPaymentOption('TICKET', Icons.receipt_long_rounded, const Color(0xFFFFD166)),
                  _buildPaymentOption('SATISPAY', Icons.phone_android_rounded, const Color(0xFF3A0CA3)),
                  _buildPaymentOption('TRANSFER', Icons.account_balance_rounded, const Color(0xFF4CC9F0)),
                  _buildPaymentOption('MOBILE', Icons.wallet_rounded, const Color(0xFF7209B7)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String method, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPaymentMethod = method);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!, width: 1),
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
              child: Icon(icon, color: color, size: 25),
            ),
            const SizedBox(height: 8),
            Text(
              method == 'CARTA' ? 'Carta' :
              method == 'CONTANTE' ? 'Contanti' :
              method == 'TICKET' ? 'Buono' :
              method == 'SATISPAY' ? 'Satispay' :
              method == 'TRANSFER' ? 'Bonifico' :
              'Mobile',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
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
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    final paymentMethod = _selectedPaymentMethod ?? 'CONTANTE';

    final items = _cartItems.map((cartItem) {
      return {
        'name': cartItem.product.name,
        'price': cartItem.product.price,
        'quantity': cartItem.quantity,
      };
    }).toList();

    final responseBody = await _paymentService.printReceiptAndGetResponse(
      items,
      total,
      paymentMethod,
    );

    final errors = <String>[];
    bool hasPaperWarning = false;
    Map<String, String> statusSegments = {};
    Map<String, dynamic> fiscalData = {};
    int transactionId = 0;

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
          _cartItems,
        );

        if (transactionId > 0) {
          await _paymentService.updateTransactionWithFiscalData(
            transactionId,
            fiscalData,
          );
        }
      }
    }

    if (mounted) {
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
                          ? const Color(0xFF06D6A0).withOpacity(0.1)
                          : const Color(0xFFFCA5A5).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      (responseBody != null && errors.isEmpty)
                          ? Icons.check_circle_rounded
                          : Icons.warning_rounded,
                      color: (responseBody != null && errors.isEmpty)
                          ? const Color(0xFF06D6A0)
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
                      color: Color(0xFF212529),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (responseBody != null && errors.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F5FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '€${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF06D6A0),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _paymentService.getPaymentMethodLabel(paymentMethod),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6C757D),
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
                                  'La ricevuta non è stata stampata. La stampante non risponde.',
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
                        if (responseBody != null && errors.isEmpty) {
                          _clearCart();
                          setState(() => _selectedPaymentMethod = null);
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (responseBody != null && errors.isEmpty)
                                ? const Color(0xFF4361EE)
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

  void _addToCartArticolo(Articolo articolo, {int quantity = 1}) {
    setState(() {
      final product = Product(
        id: articolo.id.toString(),
        name: articolo.descrizione,
        category: articolo.categoriaId.toString(),
        price: articolo.prezzo,
        description: articolo.descrizione,
        iva: articolo.iva,
      );
      CartFunctions.addToCart(_cartItems, product, quantity: quantity);
    });
  }

  void _addToCartArticoloWithCustomPrice(Articolo articolo, double price) {
    setState(() {
      final product = Product(
        id: articolo.id.toString(),
        name: articolo.descrizione,
        category: articolo.categoriaId.toString(),
        price: price,
        description: articolo.descrizione,
        iva: articolo.iva,
      );
      CartFunctions.addToCartWithCustomPrice(_cartItems, product, price);
    });
  }

  // Future<void> _printPaymentReceipt(String paymentMethod) async {
  //   try {
  //     final stampanti = await _db.getStampanti();

  //     final receiptPrinters = stampanti
  //         .where((p) => p.printerCategory == 'Receipt')
  //         .toList();

  //     if (receiptPrinters.isEmpty) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('No receipt printer configured'),
  //             backgroundColor: Color(0xFFDC2626),
  //           ),
  //         );
  //       }
  //       return;
  //     }

  //     final selectedReceiptPrinter = receiptPrinters.firstWhere(
  //       (p) => p.isDefault == true,
  //       orElse: () => receiptPrinters.first,
  //     );

  //     final totalAmount = _cartItems.fold<double>(
  //       0.0,
  //       (sum, item) => sum + (item.product.price * item.quantity),
  //     );

  //     final items = _cartItems
  //         .map((cartItem) => {
  //               'name': cartItem.product.name,
  //               'quantity': cartItem.quantity,
  //               'price': cartItem.product.price,
  //             })
  //         .toList();

  //     final success = await _printingService.printEpsonReceiptAutomatic(
  //       selectedReceiptPrinter.indirizzoIp,
  //       paymentMethod,
  //       totalAmount,
  //       8.0,
  //       port: selectedReceiptPrinter.porta,
  //       items: items,
  //       printerProtocol: selectedReceiptPrinter.tipoProtocollo,
  //     );

  //     if (mounted && !success) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Failed to print receipt'),
  //           backgroundColor: Color(0xFFDC2626),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Error: $e'),
  //           backgroundColor: const Color(0xFFDC2626),
  //         ),
  //       );
  //     }
  //   }
  // }

  void _toggleCart() {
    setState(() {
      _showCart = !_showCart;
      if (_showCart) {
        // Close keypad if it's open
        _showKeypad = false;
        _keypadModeActive = false;
      }
    });
  }

  void _toggleKeypad() {
    setState(() {
      _showKeypad = !_showKeypad;
      _keypadModeActive = _showKeypad;
      if (_showKeypad) {
        // Close cart if it's open
        _showCart = false;
      }
      if (!_showKeypad) {
        _clearKeypad();
      }
    });
  }

  void _exitKeypadMode() {
    setState(() {
      _showKeypad = false;
      _keypadModeActive = false;
      _clearKeypad();
    });
  }

  List<Articolo> get filteredProducts {
    if (_selectedCategoriaId == null) return products;
    return products
        .where((p) => p.categoriaId == _selectedCategoriaId)
        .toList();
  }

  int _calculateGridColumns() {
    if (_isSmallScreen) return 3;
    if (_isMediumScreen) return 4;
    if (_isLargeScreen) return 6;
    return 3;
  }

  void _navigateToAnagrafica() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnagraficaScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final filteredList = filteredProducts.where((articolo) {
      return articolo.descrizione
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          articolo.codice
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
    }).toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _isSmallScreen
            ? IconButton(
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                icon: const Icon(Icons.menu, color: Color(0xFF6B7280)),
              )
            : null,
        title: _isSmallScreen
            ? SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  cursorColor: const Color(0xFF2D6FF1),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    prefixIcon: const Icon(Icons.search,
                        color: Color(0xFF9CA3AF), size: 18),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          const BorderSide(color: Color(0xFF2D6FF1), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    cursorColor: const Color(0xFF2D6FF1),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      prefixIcon: const Icon(Icons.search,
                          color: Color(0xFF9CA3AF), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: const BorderSide(
                            color: Color(0xFF2D6FF1), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
              ),
        actions: [
          // Refresh button
          IconButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadData();
            },
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF6B7280),
              size: 24,
            ),
            tooltip: 'Refresh',
          ),
          // Cart icon with badge
          if (!_isSmallScreen || (_isSmallScreen && !_showCart))
            Stack(
              children: [
                IconButton(
                  onPressed: _toggleCart,
                  icon: Icon(
                    Icons.shopping_cart_outlined,
                    color: _showCart
                        ? const Color(0xFF2D6FF1)
                        : const Color(0xFF6B7280),
                    size: 28,
                  ),
                  iconSize: 28,
                  tooltip: 'Cart',
                ),
                if (totalItems > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: GestureDetector(
                      onTap: _toggleCart,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 22,
                          minHeight: 22,
                        ),
                        child: Text(
                          totalItems.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          // Keypad Icon
          IconButton(
            onPressed: _toggleKeypad,
            icon: Icon(
              Icons.dialpad,
              color: _showKeypad
                  ? const Color(0xFF2D6FF1)
                  : const Color(0xFF6B7280),
              size: 28,
            ),
            iconSize: 28,
            tooltip: 'Numeric Keypad',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBody(filteredList),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF2D6FF1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'POS Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Gestione e Impostazioni',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.list_alt_outlined,
                  text: 'Anagrafica Articoli e Categorie',
                  selected: _selectedMenu == 'articoli',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToAnagrafica();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.print_outlined,
                  text: 'Configurazione Stampante',
                  selected: _selectedMenu == 'stampante',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const StampantiScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.swap_horiz,
                  text: 'Transazioni',
                  selected: _selectedMenu == 'Transazioni',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TransazioniScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.bar_chart_outlined,
                  text: 'Statistiche',
                  selected: _selectedMenu == 'statistiche',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const StatisticheScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  text: 'Impostazioni',
                  selected: _selectedMenu == 'impostazioni',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ImpostazioniScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? const Color(0xFF2D6FF1) : const Color(0xFF6B7280),
      ),
      title: Text(
        text,
        style: TextStyle(
          color: selected ? const Color(0xFF111827) : const Color(0xFF6B7280),
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      selected: selected,
      onTap: onTap,
    );
  }

  Widget _buildBody(List<Articolo> filteredList) {
    // Mobile layout
    if (_isSmallScreen) {
      return Stack(
        children: [
          if (_showKeypad)
            _buildMobileSplitView(filteredList)
          else
            _buildProductsPanel(filteredList),
          if (_showCart) _buildMobileCartView(),
        ],
      );
    }

    // Desktop layout - Wide screen (Vertical split: Products + Cart right with integrated keypad)
    if (_isLargeScreen) {
      return Row(
        children: [
          // Products Panel (Left)
          Expanded(
            flex: 3,
            child: _buildProductsPanel(filteredList),
          ),

          // Cart Panel (Right - with integrated keypad)
          if (_showCart)
            Container(
              width: 420,
              constraints: const BoxConstraints(
                maxWidth: 420,
                minWidth: 420,
              ),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
              ),
              child: CartPanel(
                cartItems: _cartItems,
                totalAmount: totalAmount,
                totalItems: totalItems,
                onUpdateQuantity: _updateQuantity,
                onRemoveItem: _removeFromCart,
                onClearCart: _clearCart,
                keypadNumber: '',
                onNumberTap: _handleNumberInput,
                onClear: _clearKeypad,
                onBackspace: _handleBackspace,
                onXTap: _handleXPress,
                xPressed: false,
                onCloseCart: () => setState(() {
                  _showCart = false;
                }),
                onOpenKeypad: _toggleKeypad,
                onPrint: _handlePrint,
              ),
            ),
        ],
      );
    }

    // Medium screen layout - Cart on right with Keypad above or below
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Products Panel
        Expanded(
          flex: _showKeypad ? 2 : 3,
          child: _buildProductsPanel(filteredList),
        ),

        // Keypad or Cart Panel (Cart takes priority)
        if (_showCart)
          Container(
            width: 380,
            constraints: const BoxConstraints(
              maxWidth: 380,
              minWidth: 380,
            ),
            child: CartPanel(
              cartItems: _cartItems,
              totalAmount: totalAmount,
              totalItems: totalItems,
              onUpdateQuantity: _updateQuantity,
              onRemoveItem: _removeFromCart,
              onClearCart: _clearCart,
              keypadNumber: '',
              onNumberTap: _handleNumberInput,
              onClear: _clearKeypad,
              onBackspace: _handleBackspace,
              onXTap: _handleXPress,
              xPressed: false,
              onCloseCart: () => setState(() {
                _showCart = false;
              }),
              onOpenKeypad: _toggleKeypad,
              onPrint: _handlePrint,
            ),
          )
        else if (_showKeypad)
          Container(
            width: 380,
            constraints: const BoxConstraints(
              maxWidth: 380,
              minWidth: 380,
            ),
            // child: _buildDesktopKeypadPanel(),
          ),
      ],
    );
  }

  Widget _buildMobileCartView() {
    return CartPanel(
      cartItems: _cartItems,
      totalAmount: totalAmount,
      totalItems: totalItems,
      onUpdateQuantity: _updateQuantity,
      onRemoveItem: _removeFromCart,
      onClearCart: _clearCart,
      keypadNumber: '',
      onNumberTap: _handleNumberInput,
      onClear: _clearKeypad,
      onBackspace: _handleBackspace,
      onXTap: _handleXPress,
      xPressed: false,
      onCloseCart: () => setState(() {
        _showCart = false;
      }),
      onOpenKeypad: _toggleKeypad,
      onPrint: _handlePrint,
      // onPaymentProcessed: _printPaymentReceipt,
    );
  }

  Widget _buildMobileSplitView(List<Articolo> filteredList) {
    return Column(
      children: [
        // Products Panel (Top)
        Expanded(
          flex: 2,
          child: _buildProductsPanel(filteredList),
        ),

        // Divider
        Container(
          height: 1,
          color: Colors.grey[300],
        ),

        // Keypad Panel (Bottom)
        Expanded(
          flex: 2,
          child: _buildMobileKeypadPanel(),
        ),
      ],
    );
  }

  Widget _buildMobileKeypadPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [  
          // Keypad
          Expanded(
            child: NumericKeypad(
              onNumberTap: _handleNumberInput,
              onClear: _clearKeypad,
              onBackspace: _handleBackspace,
              onXTap: _handleXPress,
              onPayment: _cartItems.isNotEmpty && _selectedPaymentMethod != null
                  ? () => _processPayment(totalAmount)
                  : null,
              onPreAccount: () {},
              totalAmount: totalAmount,
              selectedPaymentMethod: _selectedPaymentMethod,
              onShowPaymentModal: () => _showPaymentMethodModal(context),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildProductsPanel(List<Articolo> filteredList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Categories - Minimalist Design
        SizedBox(
          height: _isSmallScreen ? 52 : 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length + 1, // +1 for "All" category
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                // "All" category
                final isSelected = _selectedCategoriaId == null;
                return _buildCategoryChip(
                  text: 'All',
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedCategoriaId = null;
                    });
                  },
                );
              }

              final categoria = categories[index - 1];
              final isSelected = _selectedCategoriaId == categoria.id;

              return _buildCategoryChip(
                text: categoria.descrizione,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedCategoriaId = categoria.id;
                  });
                },
              );
            },
          ),
        ),
        //ui/ux to display the cat details /dynamic price qta based on the key pad
        // Item Count and Mode Indicator
        // Padding(
        //   padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: [
        //       Text(
        //         '${filteredList.length} Articol${filteredList.length > 1 ? 'i' : 'o'}',
        //         style: const TextStyle(
        //           fontSize: 14,
        //           color: Color(0xFF6B7280),
        //         ),
        //       ),
        //       // if (_keypadModeActive)
        //       //   Container(
        //       //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        //       //     decoration: BoxDecoration(
        //       //       color: const Color(0xFF2D6FF1).withOpacity(0.1),
        //       //       borderRadius: BorderRadius.circular(8),
        //       //       border:
        //       //           Border.all(color: const Color(0xFF2D6FF1).withOpacity(0.2)),
        //       //     ),
        //       //     // child: Row(
        //       //     //   children: [
        //       //     //     Icon(Icons.touch_app, size: 14, color: const Color(0xFF2D6FF1)),
        //       //     //     const SizedBox(width: 6),
        //       //     //     Text(
        //       //     //       'Tap to apply',
        //       //     //       style: const TextStyle(
        //       //     //         fontSize: 12,
        //       //     //         color: Color(0xFF2D6FF1),
        //       //     //         fontWeight: FontWeight.w600,
        //       //     //       ),
        //       //     //     ),
        //       //     //   ],
        //       //     // ),
        //       //   ),
        //     ],
        //   ),
        // ),

        // Products Grid
        Expanded(
          child: filteredList.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: Color(0xFFD1D5DB),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No products found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _calculateGridColumns(),
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: _isSmallScreen ? 1.25 : 1.35,
                  ),
                  itemCount: filteredList.length + 1,
                  itemBuilder: (context, index) {
                    if (index == filteredList.length) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AnagraficaScreen(),
                            ),
                          );
                        },
                        child: CustomPaint(
                          painter: DashedBorderPainter(
                            color: Color.fromARGB(255, 106, 130, 238),
                            strokeWidth: 2,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.add_rounded,
                              size: 38,
                              color: Color.fromARGB(255, 106, 130, 238),
                            ),
                          ),
                        ),
                      );
                    }

                    final articolo = filteredList[index];
                    final productId = articolo.id.toString();

                    final isInCart =
                        _cartItems.any((item) => item.product.id == productId);

                    CartItem? cartItem;
                    try {
                      cartItem = _cartItems.firstWhere(
                        (item) => item.product.id == productId,
                      );
                    } catch (_) {
                      cartItem = null;
                    }

                    final displayProduct = Product(
                      id: productId,
                      name: articolo.descrizione,
                      category: articolo.categoriaId.toString(),
                      price: articolo.prezzo,
                      description: articolo.descrizione,
                      iva: articolo.iva,
                    );

                    String? selectedPrice;
                    if (_keypadFirstNumber.isNotEmpty) {
                      if (_keypadXPressed && _keypadSecondNumber.isNotEmpty) {
                        selectedPrice = 'Qtà: $_keypadFirstNumber • €$_keypadSecondNumber';
                      } else if (_keypadXPressed) {
                        selectedPrice = 'Qtà: $_keypadFirstNumber';
                      } else {
                        selectedPrice = '€$_keypadFirstNumber';
                      }
                    }

                    return ProductCard(
                      product: displayProduct,
                      onTap: () => _handleProductTapWithKeypad(articolo),
                      isInCart: isInCart,
                      quantity: cartItem?.quantity,
                      selectedPrice: selectedPrice,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _isSmallScreen ? 16 : 20,
          vertical: _isSmallScreen ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF2D6FF1) : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          // Use Row with center alignment
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: _isSmallScreen ? 14 : 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF2D6FF1)
                    : const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    this.dashWidth = 5,
    this.dashSpace = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(12),
        ),
      );

    ui.PathMetrics pathMetrics = path.computeMetrics();
    for (ui.PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        double nextDist = distance + dashWidth;
        canvas.drawPath(
          pathMetric.extractPath(distance, nextDist),
          paint,
        );
        distance = nextDist + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace;
  }
}
