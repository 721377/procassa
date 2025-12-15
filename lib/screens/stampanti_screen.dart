import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models.dart';
import '../services/database_service.dart';
import '../services/printing_service.dart';

class StampantiScreen extends StatefulWidget {
  const StampantiScreen({super.key});

  @override
  State<StampantiScreen> createState() => _StampantiScreenState();
}

class _StampantiScreenState extends State<StampantiScreen> {
  final DatabaseService _db = DatabaseService();
  final PrintingService _printingService = PrintingService();
  late Future<List<Stampante>> _stampanti;

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portaController = TextEditingController();
  final TextEditingController _bluetoothAddressController =
      TextEditingController();

  // Bluetooth related variables
  List<BluetoothDevice> _availableDevices = [];
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  BluetoothDevice? _selectedBluetoothDevice;

  Stampante? _editingStampante;
  String? _selectedProtocollo;
  String? _selectedPrinterCategory;
  String? _selectedOrderPrinterType;
  String? _selectedPrinterModel;
  bool _isDefaultPrinter = false;
  final List<String?> _protocolli = ['standar', 'Epson', 'XON/XOFF', 'Custom'];
  final List<String> _printerModels = ['Generic', 'Sunmi Pro'];

  @override
  void initState() {
    super.initState();
    _stampanti = _db.getStampanti();
    _checkBluetoothState();
    _loadConnectedDevices();
  }

  Future<void> _loadConnectedDevices() async {
    try {
      final connectedDevices = await FlutterBluePlus.connectedDevices;
      if (mounted && connectedDevices.isNotEmpty) {
        setState(() {
          for (var device in connectedDevices) {
            final deviceName = device.platformName.toLowerCase();
            
            final isPrinter = deviceName.contains('printer') ||
                deviceName.contains('thermal') ||
                deviceName.contains('receipt') ||
                deviceName.contains('sunmi') ||
                deviceName.contains('epson') ||
                deviceName.contains('pos') ||
                deviceName.contains('print');
            
            if (isPrinter && !_availableDevices.any((d) => d.remoteId == device.remoteId)) {
              _availableDevices.add(device);
            }
          }
        });
        print('Loaded printer devices from connected devices');
      }
    } catch (e) {
      print('Error loading connected devices: $e');
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _nomeController.dispose();
    _ipController.dispose();
    _portaController.dispose();
    _bluetoothAddressController.dispose();
    super.dispose();
  }

  Future<void> _checkBluetoothState() async {
    bool isSupported = await FlutterBluePlus.isSupported;
    if (isSupported && mounted) {
    }
  }

  Future<void> _startScan() async {
    if (_isScanning) return;

    try {
      BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Accendi il Bluetooth per cercare dispositivi'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }



      setState(() {
        _isScanning = true;
        _availableDevices.clear();
      });

      await _loadConnectedDevices();

      _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        if (!mounted) return;

        print('Scan results received: ${results.length} devices');
        
        setState(() {
          for (var result in results) {
            final device = result.device;
            final deviceName = device.platformName.toLowerCase();
            
            final isPrinter = deviceName.contains('printer') ||
                deviceName.contains('thermal') ||
                deviceName.contains('receipt') ||
                deviceName.contains('sunmi') ||
                deviceName.contains('epson') ||
                deviceName.contains('pos') ||
                deviceName.contains('print');
            
            if (isPrinter && !_availableDevices.any((d) => d.remoteId == device.remoteId)) {
              print('Found printer device: ${device.platformName} (${device.remoteId})');
              _availableDevices.add(device);
            }
          }
        });
      }, onError: (e) {
        print('Scan error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore nella scansione: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });

      print('Starting Bluetooth scan...');
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        continuousUpdates: true,
        removeIfGone: const Duration(seconds: 5),
      );
      print('Scan started successfully');

      await Future.delayed(const Duration(seconds: 15));
      await _stopScan();

    } catch (e) {
      print('Error starting scan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isScanning = false);
    }
  }

  Future<void> _stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      _scanSubscription = null;
      setState(() => _isScanning = false);
    } catch (e) {
      // Ignore errors when stopping
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      final deviceName = device.platformName;
      
      setState(() {
        _selectedBluetoothDevice = device;
        _bluetoothAddressController.text = device.remoteId.toString();
        _nomeController.text = deviceName;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selezionato: $deviceName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetForm() {
    _nomeController.clear();
    _ipController.clear();
    _portaController.clear();
    _bluetoothAddressController.clear();
    _selectedProtocollo = null;
    _selectedPrinterCategory = null;
    _selectedOrderPrinterType = null;
    _selectedPrinterModel = null;
    _isDefaultPrinter = false;
    _editingStampante = null;
    _selectedBluetoothDevice = null;
  }

  void _openDialog({Stampante? stampante}) {
    if (stampante != null) {
      _nomeController.text = stampante.nome;
      _ipController.text = stampante.indirizzoIp;
      _portaController.text = stampante.porta.toString();
      _selectedProtocollo = stampante.tipoProtocollo;
      _selectedPrinterCategory = stampante.printerCategory;
      _selectedPrinterModel = stampante.printerModel;
      _selectedOrderPrinterType = stampante.printerModel == 'Sunmi Pro' 
          ? 'Sunmi Pro'
          : stampante.orderPrinterType;
      _bluetoothAddressController.text = stampante.bluetoothAddress ?? '';
      _isDefaultPrinter = stampante.isDefault ?? false;
      _editingStampante = stampante;
      _selectedBluetoothDevice = null;
    } else {
      _resetForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black.withOpacity(0.4),
          child: GestureDetector(
            onTap: () {},
            child: DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) => StatefulBuilder(
                builder: (context, setDialogState) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              stampante != null
                                  ? 'Modifica Stampante'
                                  : 'Nuova Stampante',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                _stopScan();
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.close_rounded),
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTextField(
                                controller: _nomeController,
                                label: 'Nome Stampante',
                                icon: Icons.print_rounded,
                              ),
                              const SizedBox(height: 20),
                              _buildPrinterCategoryDropdown(setDialogState),
                              const SizedBox(height: 20),
                              if (_selectedPrinterCategory == 'Receipt')
                                _buildReceiptPrinterForm(setDialogState)
                              else if (_selectedPrinterCategory == 'Order')
                                _buildOrderPrinterForm(setDialogState)
                              else
                                Container(),
                              const SizedBox(height: 20),
                              _buildDefaultPrinterCheckbox(setDialogState),
                              const SizedBox(height: 40),
                              _buildActionButtons(context, stampante),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 16),
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: icon != null
                ? Icon(icon, color: const Color(0xFF2D6FF1))
                : null,
            suffixIcon: readOnly && onTap != null
                ? const Icon(Icons.search_rounded, color: Colors.grey)
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF2D6FF1),
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrinterCategoryDropdown(StateSetter setDialogState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo di Stampante',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              isExpanded: true,
              value: _selectedPrinterCategory,
              icon: const Icon(Icons.arrow_drop_down_rounded),
              iconSize: 24,
              elevation: 0,
              style: const TextStyle(fontSize: 16, color: Colors.black),
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              hint: const Text(
                'Seleziona il tipo di stampante',
                style: TextStyle(color: Colors.grey),
              ),
              onChanged: (value) {
                setDialogState(() {
                  _selectedPrinterCategory = value;
                  _selectedOrderPrinterType = null;
                  _selectedBluetoothDevice = null;
                  _bluetoothAddressController.clear();
                  _stopScan();
                });
              },
              items: ['Receipt', 'Order'].map((category) {
                return DropdownMenuItem<String?>(
                  value: category,
                  child: Text(
                    category == 'Receipt'
                        ? 'Stampante Ricevuta'
                        : 'Stampante Ordine',
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ricevuta: Per stampe di pagamento | Ordine: Per stampe ordini',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptPrinterForm(StateSetter setDialogState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _ipController,
          label: 'Indirizzo IP',
          hintText: '192.168.1.100',
          icon: Icons.language_rounded,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _portaController,
          label: 'Porta',
          hintText: '9100',
          icon: Icons.signpost_rounded,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        _buildProtocolDropdown(setDialogState),
      ],
    );
  }

  Widget _buildOrderPrinterForm(StateSetter setDialogState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPrinterModelDropdown(setDialogState),
        const SizedBox(height: 20),
        if (_selectedPrinterModel != 'Sunmi Pro') ...[
          Text(
            'Metodo di Connessione',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                isExpanded: true,
                value: _selectedOrderPrinterType,
                icon: const Icon(Icons.arrow_drop_down_rounded),
                iconSize: 24,
                elevation: 0,
                style: const TextStyle(fontSize: 16, color: Colors.black),
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                hint: const Text(
                  'Seleziona il metodo di connessione',
                  style: TextStyle(color: Colors.grey),
                ),
                onChanged: (value) async {
                  setDialogState(() {
                    _selectedOrderPrinterType = value;
                    _selectedBluetoothDevice = null;
                    _bluetoothAddressController.clear();
                  });
                  
                  if (value == 'Bluetooth') {
                    await _startScan();
                    if (mounted) {
                      setDialogState(() {});
                    }
                  } else {
                    await _stopScan();
                  }
                },
                items: ['IP', 'Bluetooth'].map((type) {
                  return DropdownMenuItem<String?>(
                    value: type,
                    child: Text(
                      type,
                      style: const TextStyle(color: Colors.black),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_selectedOrderPrinterType == 'IP') ...[
            _buildTextField(
              controller: _ipController,
              label: 'Indirizzo IP',
              hintText: '192.168.1.100',
              icon: Icons.language_rounded,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _portaController,
              label: 'Porta',
              hintText: '9100',
              icon: Icons.signpost_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            _buildProtocolDropdown(setDialogState),
          ] else if (_selectedOrderPrinterType == 'Bluetooth') ...[
            _buildBluetoothDeviceSelection(setDialogState),
          ]
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Stampante interna - Nessuna configurazione richiesta',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildBluetoothDeviceSelection(StateSetter setDialogState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_availableDevices.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stampanti Bluetooth Disponibili',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              TextButton.icon(
                onPressed: _isScanning ? null : _startScan,
                icon: Icon(
                  _isScanning ? Icons.hourglass_empty_rounded : Icons.refresh_rounded,
                  size: 18,
                ),
                label: Text(
                  _isScanning ? 'Ricerca...' : 'Ricerca di nuovo',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _availableDevices.length,
              separatorBuilder: (context, index) => Divider(
                height: 0,
                color: Colors.grey[200],
              ),
              itemBuilder: (context, index) {
                final device = _availableDevices[index];
                final deviceName = device.platformName;
                final isSelected = _bluetoothAddressController.text == device.remoteId.toString();
                final isLikelyPrinter = deviceName.toLowerCase().contains('printer') ||
                    deviceName.toLowerCase().contains('pos') ||
                    deviceName.toLowerCase().contains('print') ||
                    deviceName.toLowerCase().contains('sunmi');

                return Material(
                  color: isSelected ? Colors.blue[50] : Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setDialogState(() {
                        _selectedBluetoothDevice = device;
                        _bluetoothAddressController.text = device.remoteId.toString();
                        _nomeController.text = deviceName;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isLikelyPrinter
                                ? Icons.print_rounded
                                : Icons.bluetooth_rounded,
                            color: isLikelyPrinter
                                ? Colors.blue
                                : (isSelected ? Colors.blue : Colors.grey),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  deviceName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  device.remoteId.toString(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.blue,
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ] else if (_isScanning) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  'Ricerca stampanti Bluetooth...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Nessun dispositivo Bluetooth trovato',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Divider or label for manual entry
        if (_availableDevices.isNotEmpty || _isScanning)
          Divider(
            color: Colors.grey[300],
            thickness: 1,
            height: 24,
          ),
        // Selected device info
        if (_selectedBluetoothDevice != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dispositivo Selezionato',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        _nomeController.text,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        _bluetoothAddressController.text,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setDialogState(() {
                      _selectedBluetoothDevice = null;
                      _bluetoothAddressController.clear();
                    });
                  },
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        if (_selectedBluetoothDevice != null) const SizedBox(height: 16),
        // Manual entry option
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'O Inserisci Manualmente',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bluetoothAddressController,
              decoration: InputDecoration(
                hintText: 'XX:XX:XX:XX:XX:XX',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(
                  Icons.bluetooth_rounded,
                  color: Color(0xFF2D6FF1),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2D6FF1),
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                setDialogState(() {
                  if (value.isNotEmpty) {
                    _selectedBluetoothDevice = null;
                  }
                });
              },
            ),
            const SizedBox(height: 4),
            Text(
              'Formato: XX:XX:XX:XX:XX:XX',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showBluetoothDeviceSelector() {
    int _selectedTabIndex = 0;
    final manualAddressController = TextEditingController();
    final manualNameController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black.withOpacity(0.4),
          child: GestureDetector(
            onTap: () {},
            child: DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) => StatefulBuilder(
                builder: (context, setState) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Seleziona Stampante Bluetooth',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTabIndex = 0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: _selectedTabIndex == 0
                                            ? Colors.blue
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_rounded,
                                        size: 18,
                                        color: _selectedTabIndex == 0
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Dispositivi Trovati',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _selectedTabIndex == 0
                                              ? Colors.blue
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTabIndex = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: _selectedTabIndex == 1
                                            ? Colors.blue
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.edit_rounded,
                                        size: 18,
                                        color: _selectedTabIndex == 1
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Inserisci Manuale',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _selectedTabIndex == 1
                                              ? Colors.blue
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _selectedTabIndex == 0
                            ? _buildScannedDevicesList(scrollController)
                            : _buildManualEntryForm(
                                manualNameController,
                                manualAddressController,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScannedDevicesList(ScrollController scrollController) {
    return _availableDevices.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bluetooth_disabled_rounded,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  _isScanning ? 'Ricerca in corso...' : 'Nessun dispositivo trovato',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                if (!_isScanning)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton.icon(
                      onPressed: _startScan,
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Cerca dispositivi'),
                    ),
                  ),
              ],
            ),
          )
        : ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _availableDevices.length,
            itemBuilder: (context, index) {
              final device = _availableDevices[index];
              final deviceName = device.platformName;
              final isLikelyPrinter = deviceName.toLowerCase().contains('printer') ||
                  deviceName.toLowerCase().contains('pos') ||
                  deviceName.toLowerCase().contains('print') ||
                  deviceName.toLowerCase().contains('sunmi');

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: Icon(
                    isLikelyPrinter
                        ? Icons.print_rounded
                        : Icons.bluetooth_rounded,
                    color: isLikelyPrinter ? Colors.blue : Colors.grey,
                  ),
                  title: Text(
                    deviceName,
                    style: TextStyle(
                      fontWeight: isLikelyPrinter
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    device.remoteId.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey[400],
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _connectToDevice(device);
                  },
                ),
              );
            },
          );
  }

  Widget _buildManualEntryForm(
    TextEditingController nameController,
    TextEditingController addressController,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Inserisci l\'indirizzo Bluetooth del dispositivo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nome Stampante',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Es. Stampante Cucina',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(
                    Icons.print_rounded,
                    color: Color(0xFF2D6FF1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2D6FF1),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Indirizzo Bluetooth',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  hintText: 'XX:XX:XX:XX:XX:XX',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(
                    Icons.bluetooth_rounded,
                    color: Color(0xFF2D6FF1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2D6FF1),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Formato: XX:XX:XX:XX:XX:XX (es. 00:1A:7D:DA:71:13)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              if (addressController.text.isNotEmpty) {
                setState(() {
                  _bluetoothAddressController.text = addressController.text;
                  if (nameController.text.isNotEmpty) {
                    _nomeController.text = nameController.text;
                  }
                  _selectedBluetoothDevice = null;
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Inserisci l\'indirizzo Bluetooth'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.check_rounded),
            label: const Text(
              'Conferma',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolDropdown(StateSetter setDialogState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Protocollo (Opzionale)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              isExpanded: true,
              value: _selectedProtocollo,
              icon: const Icon(Icons.arrow_drop_down_rounded),
              iconSize: 24,
              elevation: 0,
              style: const TextStyle(fontSize: 16, color: Colors.black),
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              hint: const Text(
                'Nessun protocollo specificato',
                style: TextStyle(color: Colors.grey),
              ),
              onChanged: (value) {
                setDialogState(() {
                  _selectedProtocollo = value;
                });
              },
              items: _protocolli.map((proto) {
                return DropdownMenuItem<String?>(
                  value: proto,
                  child: Text(
                    proto ?? 'Nessuno',
                    style: TextStyle(
                      color: proto == null ? Colors.grey[600] : Colors.black,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Solo per stampanti speciali. Lascia vuoto per stampanti standard.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildPrinterModelDropdown(StateSetter setDialogState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modello Stampante',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              isExpanded: true,
              value: _selectedPrinterModel,
              icon: const Icon(Icons.arrow_drop_down_rounded),
              iconSize: 24,
              elevation: 0,
              style: const TextStyle(fontSize: 16, color: Colors.black),
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              hint: const Text(
                'Seleziona il modello',
                style: TextStyle(color: Colors.grey),
              ),
              onChanged: (value) {
                setDialogState(() {
                  _selectedPrinterModel = value;
                });
              },
              items: _printerModels.map((model) {
                return DropdownMenuItem<String?>(
                  value: model,
                  child: Text(
                    model,
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultPrinterCheckbox(StateSetter setDialogState) {
    return Row(
      children: [
        Checkbox(
          value: _isDefaultPrinter,
          onChanged: (value) {
            setDialogState(() {
              _isDefaultPrinter = value ?? false;
            });
          },
          activeColor: const Color(0xFF2D6FF1),
        ),
        const SizedBox(width: 8),
        Text(
          'Usa come stampante predefinita',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Stampante? stampante) {
    final isSunmiPro = _selectedPrinterModel == 'Sunmi Pro' && _selectedPrinterCategory == 'Order';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isSunmiPro) ...[
          ElevatedButton.icon(
            onPressed: () async {
              final success = await _printingService.testPrintSunmiPro(
                businessName: _nomeController.text.isNotEmpty ? _nomeController.text : null,
              );
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Stampa di prova inviata' : 'Errore nella stampa di prova',
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.print_rounded),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            label: const Text(
              'Stampa di Prova',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _stopScan();
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: Text(
                  'Annulla',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  if (_nomeController.text.isEmpty ||
                      _selectedPrinterCategory == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Compila tutti i campi obbligatori'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    return;
                  }

                  if (_selectedPrinterCategory == 'Receipt') {
                    if (_ipController.text.isEmpty ||
                        _portaController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                              'Inserisci IP e Porta per la stampante ricevuta'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                      return;
                    }
                  } else if (_selectedPrinterCategory == 'Order') {
                    if (_selectedPrinterModel != 'Sunmi Pro') {
                      if (_selectedOrderPrinterType == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Seleziona il metodo di connessione'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                        return;
                      }
                      if (_selectedOrderPrinterType == 'IP' &&
                          (_ipController.text.isEmpty ||
                              _portaController.text.isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Inserisci IP e Porta per la stampante ordine'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                        return;
                      }
                      if (_selectedOrderPrinterType == 'Bluetooth' &&
                          _bluetoothAddressController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Seleziona una stampante Bluetooth'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                        return;
                      }
                    }
                  }

                  try {
                    int porta = 0;
                    if (_portaController.text.isNotEmpty) {
                      porta = int.parse(_portaController.text);
                    }

                    final isSunmiPro = _selectedPrinterModel == 'Sunmi Pro';
                    
                    final printerType = isSunmiPro 
                        ? 'Sunmi'
                        : (_selectedOrderPrinterType == 'Bluetooth' ? 'Bluetooth' : 'Network');
                    
                    final orderPrinterType = isSunmiPro ? 'Sunmi Pro' : _selectedOrderPrinterType;

                    if (_editingStampante != null) {
                      final updated = Stampante(
                        id: _editingStampante!.id,
                        nome: _nomeController.text,
                        indirizzoIp: isSunmiPro ? '' : _ipController.text,
                        porta: isSunmiPro ? 0 : porta,
                        tipoProtocollo: _selectedProtocollo ?? 'standard',
                        printerType: printerType,
                        printerCategory: _selectedPrinterCategory,
                        orderPrinterType: orderPrinterType,
                        bluetoothAddress: isSunmiPro 
                            ? null 
                            : (_bluetoothAddressController.text.isEmpty
                                ? null
                                : _bluetoothAddressController.text),
                        isDefault: _isDefaultPrinter,
                        printerModel: _selectedPrinterModel,
                      );
                      await _db.updateStampante(updated);
                    } else {
                      final newStampante = Stampante(
                        nome: _nomeController.text,
                        indirizzoIp: isSunmiPro ? '' : _ipController.text,
                        porta: isSunmiPro ? 0 : porta,
                        tipoProtocollo: _selectedProtocollo ?? 'standard',
                        printerType: printerType,
                        printerCategory: _selectedPrinterCategory,
                        orderPrinterType: orderPrinterType,
                        bluetoothAddress: isSunmiPro 
                            ? null 
                            : (_bluetoothAddressController.text.isEmpty
                                ? null
                                : _bluetoothAddressController.text),
                        isDefault: _isDefaultPrinter,
                        printerModel: _selectedPrinterModel,
                      );
                      await _db.insertStampante(newStampante);
                    }

                    _resetForm();
                    _stopScan();
                    setState(() {
                      _stampanti = _db.getStampanti();
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          stampante != null
                              ? 'Stampante modificata'
                              : 'Stampante aggiunta',
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: const Color(0xFF2D6FF1),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Errore: $e'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6FF1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Salva',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _deleteStampante(Stampante stampante) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: Colors.orange,
              ),
              const SizedBox(height: 20),
              const Text(
                'Elimina Stampante',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sei sicuro di voler eliminare "${stampante.nome}"? Questa azione non può essere annullata.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Annulla'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _db.deleteStampante(stampante.id!);
                        setState(() {
                          _stampanti = _db.getStampanti();
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Stampante eliminata'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: const Color(0xFF2D6FF1),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Elimina',
                        style: TextStyle(color: Colors.white),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stampanti'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        shadowColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => _openDialog(),
            icon: const Icon(Icons.add_rounded),
            color: const Color(0xFF2D6FF1),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[50],
        child: FutureBuilder<List<Stampante>>(
          future: _stampanti,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2D6FF1),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Errore nel caricamento',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            final stampanti = snapshot.data ?? [];

            if (stampanti.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.print_outlined,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Nessuna stampante configurata',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aggiungi una stampante per iniziare',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => _openDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6FF1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Aggiungi Stampante'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: stampanti.length,
              itemBuilder: (context, index) {
                final stampante = stampanti[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D6FF1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        stampante.printerType == 'Bluetooth'
                            ? Icons.bluetooth_rounded
                            : stampante.printerType == 'Sunmi'
                                ? Icons.smartphone_rounded
                                : Icons.print_rounded,
                        color: const Color(0xFF2D6FF1),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          stampante.nome,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (stampante.isDefault == true) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Text(
                              'Default',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (stampante.printerCategory != null)
                            Row(
                              children: [
                                Icon(
                                  stampante.printerCategory == 'Receipt'
                                      ? Icons.receipt_long_rounded
                                      : Icons.local_shipping_rounded,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    stampante.printerCategory == 'Receipt'
                                        ? 'Stampante Ricevuta'
                                        : 'Stampante Ordine',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          if (stampante.printerCategory == 'Order' &&
                              stampante.printerModel != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.devices_rounded,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    stampante.printerModel ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (stampante.printerCategory == 'Order' &&
                              stampante.orderPrinterType != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  stampante.orderPrinterType == 'IP'
                                      ? Icons.wifi_rounded
                                      : stampante.orderPrinterType == 'Bluetooth'
                                          ? Icons.bluetooth_rounded
                                          : Icons.smartphone_rounded,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    stampante.orderPrinterType ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (stampante.orderPrinterType == 'IP' ||
                              stampante.printerCategory == 'Receipt') ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.language_rounded,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${stampante.indirizzoIp}:${stampante.porta}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (stampante.orderPrinterType == 'Bluetooth' &&
                              stampante.bluetoothAddress != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.bluetooth_rounded,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    stampante.bluetoothAddress ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (stampante.tipoProtocollo.isNotEmpty &&
                              stampante.tipoProtocollo != 'standard') ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.settings_rounded,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Protocollo: ${stampante.tipoProtocollo}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit_rounded,
                            color: Colors.grey[600],
                          ),
                          onPressed: () => _openDialog(stampante: stampante),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red[400],
                          ),
                          onPressed: () => _deleteStampante(stampante),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}