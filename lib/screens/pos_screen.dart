// screens/pos_screen.dart
import 'package:flutter/material.dart';
import 'package:procassa/screens/statistiche_screen.dart';
import 'package:procassa/screens/transazioni_screen.dart';
import 'package:procassa/widgets/numeric_keyboard.dart';
import '../models.dart';
import '../widgets/cart_panel.dart';
import '../widgets/product_card.dart';
import '../services/cart_functions.dart';
import '../services/database_service.dart';
import '../services/printing_service.dart';
import 'stampanti_screen.dart';
import 'impostazioni_screen.dart';
import 'anagrafica_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final DatabaseService _db = DatabaseService();
  final PrintingService _printingService = PrintingService();

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
      final quantity = int.tryParse(_keypadFirstNumber) ?? 1;
      _addToCartArticolo(articolo, quantity: quantity);
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        const Text(
                          'Select Order Printer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Printer Options
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              children: orderPrinters.map((printer) {
                                final subtitle = printer.printerModel ==
                                        'Sunmi Pro'
                                    ? 'Sunmi Pro (Interno)'
                                    : (printer.orderPrinterType == 'IP'
                                        ? '${printer.indirizzoIp}:${printer.porta}'
                                        : printer.bluetoothAddress ??
                                            'Bluetooth');

                                final isSelected = selectedPrinter == printer;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedPrinter = printer;
                                    });
                                    Navigator.pop(context, printer);
                                  },
                                  child: Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.blue.shade50
                                          : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.grey.shade200,
                                        width: 1.2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_off,
                                          color: isSelected
                                              ? Colors.blue
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                printer.nome,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                subtitle,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
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

  void _addToCartArticolo(Articolo articolo, {int quantity = 1}) {
    setState(() {
      final product = Product(
        id: articolo.id.toString(),
        name: articolo.descrizione,
        category: articolo.categoriaId.toString(),
        price: articolo.prezzo,
        description: articolo.descrizione,
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
                        borderSide:
                            const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide:
                            const BorderSide(color: Color(0xFFE5E7EB)),
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

    // Desktop layout
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Products Panel
        Expanded(
          flex: _showKeypad ? 2 : (_showCart ? 3 : 4),
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
              // onPaymentProcessed: _printPaymentReceipt,
            ),
          )
        else if (_showKeypad)
          Container(
            width: 380,
            constraints: const BoxConstraints(
              maxWidth: 380,
              minWidth: 380,
            ),
            child: _buildDesktopKeypadPanel(),
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
          flex: 1,
          child: _buildProductsPanel(filteredList),
        ),

        // Divider
        Container(
          height: 1,
          color: Colors.grey[300],
        ),

        // Keypad Panel (Bottom)
        Expanded(
          flex: 1,
          child: _buildMobileKeypadPanel(),
        ),
      ],
    );
  }

  Widget _buildMobileKeypadPanel() {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: const Color(0xFFE5E7EB), width: 1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Center(
                      child: Text(
                        'Prezzo: ${_keypadFirstNumber.isEmpty ? '0' : _keypadFirstNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: const Color(0xFFE5E7EB), width: 1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Center(
                      child: Text(
                        _keypadXPressed
                            ? 'Prezzo: ${_keypadSecondNumber.isEmpty ? '0' : _keypadSecondNumber}'
                            : 'Qtà: ${_keypadFirstNumber.isEmpty ? '0' : _keypadFirstNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    onPressed: _toggleCart,
                    icon: const Icon(Icons.shopping_cart_outlined, size: 28),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Carrello',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.zero,
              child: NumericKeypad(
                onNumberTap: _handleNumberInput,
                onClear: _clearKeypad,
                onBackspace: _handleBackspace,
                onXTap: _handleXPress,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopKeypadPanel() {
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: const Color(0xFFE5E7EB), width: 1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Center(
                      child: Text(
                        'Prezzo: ${_keypadFirstNumber.isEmpty ? '0' : _keypadFirstNumber}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: const Color(0xFFE5E7EB), width: 1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Center(
                      child: Text(
                        _keypadXPressed
                            ? 'Prezzo: ${_keypadSecondNumber.isEmpty ? '0' : _keypadSecondNumber}'
                            : 'Qtà: ${_keypadFirstNumber.isEmpty ? '0' : _keypadFirstNumber}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.zero,
              child: NumericKeypad(
                onNumberTap: _handleNumberInput,
                onClear: _clearKeypad,
                onBackspace: _handleBackspace,
                onXTap: _handleXPress,
              ),
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
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
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
                    );

                    String? selectedPrice;
                    // if (_keypadFirstNumber.isNotEmpty) {
                    //   if (_keypadXPressed && _keypadSecondNumber.isNotEmpty) {
                    //     selectedPrice = '€$_keypadFirstNumber x$_keypadSecondNumber';
                    //   } else if (_keypadXPressed) {
                    //     selectedPrice = 'Qtà: $_keypadFirstNumber';
                    //   } else {
                    //     selectedPrice = '€$_keypadFirstNumber';
                    //   }
                    // }

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
