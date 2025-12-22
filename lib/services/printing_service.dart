// ignore_for_file: avoid_print

import 'dart:developer';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:esc_pos_printer_plus/esc_pos_printer_plus.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart' as esc_pos_utils;
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart' as bt_printer;
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import 'database_service.dart';

class PrintingService {
  final List<String> _devices = [];
  final bool _isDiscovering = false;
  final String _localIp = '';
  final String _wifiName = '';
  final String _ethernetIp = '';
  final int _port = 9100;
  String? _lastError;

  List<String> get devices => _devices;
  bool get isDiscovering => _isDiscovering;
  String get localIp => _localIp;
  String get wifiName => _wifiName;
  String get ethernetIp => _ethernetIp;
  String? get lastError => _lastError;

  Future<bool> printCommand(
    String printerIp,
    List<Map<String, dynamic>> items,
    double subtotal,
    double taxPercentage, {
    String? businessName,
    int? port,
  }) async {
    try {
      const paper = esc_pos_utils.PaperSize.mm80;
      final profile = await esc_pos_utils.CapabilityProfile.load();
      final printer = NetworkPrinter(paper, profile);

      final int printPort = port ?? _port;
      final PosPrintResult res =
          await printer.connect(printerIp, port: printPort);

      if (res != PosPrintResult.success) {
        log('Failed to connect: ${res.msg}');
        return false;
      }

      try {
        await _printCommandContent(
          printer,
          items,
          subtotal,
          taxPercentage,
          businessName: businessName,
        );
      } finally {
        printer.disconnect();
      }

      return true;
    } catch (e) {
      log('Error printing: $e');
      return false;
    }
  }

Future<bool> printCommandViaBluetooth(
  String bluetoothAddress,
  List<Map<String, dynamic>> items,
  double subtotal,
  double taxPercentage, {
  String? businessName,
}) async {
  try {
    // Build the text content
    final printContent = _buildPrintContent(
      items,
      subtotal,
      taxPercentage,
      businessName: businessName,
    );

    // Convert text to bytes
    final Uint8List bytes = Uint8List.fromList(printContent.codeUnits);

    // 1) Print the main content
    final success = await bt_printer.FlutterBluetoothPrinter.printBytes(
      address: bluetoothAddress,
      data: bytes,
      keepConnected: true, // keep connection for the next commands
      maxBufferSize: 512,
      delayTime: 120,
    );

    if (!success) return false;

    // 2) Feed 5 lines
    final Uint8List feed5 = Uint8List.fromList([0x1B, 0x69]);
    await bt_printer.FlutterBluetoothPrinter.printBytes(
      address: bluetoothAddress,
      data: feed5,
      keepConnected: false, // now we can close the connection
      maxBufferSize: 512,
      delayTime: 120,
    );

    // If you also want a cut command and your printer supports it, you can add:
    // final Uint8List cutCommand = Uint8List.fromList([0x1D, 0x56, 0x00]); // full cut
    // await bt_printer.FlutterBluetoothPrinter.printBytes(
    //   address: bluetoothAddress,
    //   data: cutCommand,
    //   keepConnected: false,
    //   maxBufferSize: 512,
    //   delayTime: 120,
    // );

    return true;
  } catch (e) {
    log("Error printing via Bluetooth: $e");
    return false;
  }
}




  Future<bool> printPaymentReceipt(
    String printerIp,
    String paymentMethod,
    double totalAmount,
    double taxPercentage, {
    String? businessName,
    int? port,
    List<Map<String, dynamic>>? items,
    String? printerProtocol,
  }) async {
    try {
      if (printerProtocol == 'Epson') {
        return await _printFiscalReceipt(
          printerIp,
          paymentMethod,
          totalAmount,
          taxPercentage,
          items: items,
          port: port,
        );
      }

      const paper = esc_pos_utils.PaperSize.mm80;
      final profile = await esc_pos_utils.CapabilityProfile.load();
      final printer = NetworkPrinter(paper, profile);

      final int printPort = port ?? _port;
      final PosPrintResult res =
          await printer.connect(printerIp, port: printPort);

      if (res != PosPrintResult.success) {
        log('Failed to connect: ${res.msg}');
        return false;
      }

      try {
        await _printPaymentReceiptContent(
          printer,
          paymentMethod,
          totalAmount,
          taxPercentage,
          businessName: businessName,
        );
      } finally {
        printer.disconnect();
      }

      return true;
    } catch (e) {
      log('Error printing receipt: $e');
      return false;
    }
  }

  Future<bool> _printFiscalReceipt(
    String printerIp,
    String paymentMethod,
    double totalAmount,
    double taxPercentage, {
    List<Map<String, dynamic>>? items,
    int? port,
  }) async {
    try {
      const paper = esc_pos_utils.PaperSize.mm80;
      final profile = await esc_pos_utils.CapabilityProfile.load();
      final printer = NetworkPrinter(paper, profile);

      final int printPort = port ?? _port;
      final PosPrintResult res =
          await printer.connect(printerIp, port: printPort);

      if (res != PosPrintResult.success) {
        log('Failed to connect to Epson printer: ${res.msg}');
        return false;
      }

      try {
        final itemsList = items ?? [];

        printer.text(
          'RICEVUTA FISCALE',
          styles: const esc_pos_utils.PosStyles(
            align: esc_pos_utils.PosAlign.center,
            height: esc_pos_utils.PosTextSize.size2,
            width: esc_pos_utils.PosTextSize.size2,
            bold: true,
          ),
        );

        final now = DateTime.now();
        final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

        printer.text(
          dateFormatter.format(now),
          styles: const esc_pos_utils.PosStyles(
            align: esc_pos_utils.PosAlign.center,
          ),
          linesAfter: 1,
        );

        printer.hr();

        for (final item in itemsList) {
          final name = item['name'] as String? ?? 'Item';
          final price = item['price'] as double? ?? 0.0;
          final quantity = item['quantity'] as int? ?? 1;
          final itemTotal = quantity * price;

          printer.text(name, styles: const esc_pos_utils.PosStyles(bold: true));
          printer.text(
            'Qty: $quantity x \$${price.toStringAsFixed(2)} = \$${itemTotal.toStringAsFixed(2)}',
          );
        }

        printer.hr();

        final tax = totalAmount * (taxPercentage / 100);

        printer.row([
          esc_pos_utils.PosColumn(
            text: 'Subtotale',
            width: 10,
            styles: const esc_pos_utils.PosStyles(bold: true),
          ),
          esc_pos_utils.PosColumn(
            text: '\$${totalAmount.toStringAsFixed(2)}',
            width: 2,
            styles: const esc_pos_utils.PosStyles(align: esc_pos_utils.PosAlign.right, bold: true),
          ),
        ]);

        printer.row([
          esc_pos_utils.PosColumn(
            text: 'IVA ${taxPercentage.toStringAsFixed(0)}%',
            width: 10,
            styles: const esc_pos_utils.PosStyles(bold: true),
          ),
          esc_pos_utils.PosColumn(
            text: '\$${tax.toStringAsFixed(2)}',
            width: 2,
            styles: const esc_pos_utils.PosStyles(align: esc_pos_utils.PosAlign.right, bold: true),
          ),
        ]);

        final total = totalAmount + tax;

        printer.row([
          esc_pos_utils.PosColumn(
            text: 'TOTALE',
            width: 10,
            styles: const esc_pos_utils.PosStyles(
              bold: true,
              height: esc_pos_utils.PosTextSize.size2,
              width: esc_pos_utils.PosTextSize.size2,
            ),
          ),
          esc_pos_utils.PosColumn(
            text: '\$${total.toStringAsFixed(2)}',
            width: 2,
            styles: const esc_pos_utils.PosStyles(
              align: esc_pos_utils.PosAlign.right,
              bold: true,
              height: esc_pos_utils.PosTextSize.size2,
              width: esc_pos_utils.PosTextSize.size2,
            ),
          ),
        ]);

        printer.hr();

        String paymentDisplay = 'CONTANTE';
        switch (paymentMethod.toUpperCase()) {
          case 'CARTA':
            paymentDisplay = 'CARTA DI CREDITO';
            break;
          case 'TICKET':
            paymentDisplay = 'TICKET';
            break;
          case 'MULTIPLE TICKETS':
            paymentDisplay = 'TICKET MULTIPLI';
            break;
          default:
            paymentDisplay = 'CONTANTE';
        }

        printer.text(
          'Pagamento: $paymentDisplay',
          styles: const esc_pos_utils.PosStyles(
            align: esc_pos_utils.PosAlign.center,
            bold: true,
          ),
          linesAfter: 2,
        );

        printer.cut();

        log('Fiscal receipt printed successfully');
        return true;
      } finally {
        printer.disconnect();
      }
    } catch (e) {
      log('Error printing fiscal receipt: $e');
      return false;
    }
  }

String _buildPrintContent(
  List<Map<String, dynamic>> items,
  double subtotal,
  double taxPercentage, {
  String? businessName,
}) {
  StringBuffer buffer = StringBuffer();

  buffer.writeln('\x1B\x21\x30         ORDINE             \x1B\x21\x00');
  buffer.writeln('-----------------------------------------------\n');

  for (final item in items) {
    final name = item['name'] as String? ?? 'Item';
    final quantity = item['quantity'] as int? ?? 1;
    final price = item['price'] as double? ?? 0.0;
    final total = quantity * price;

    final displayName = name.length > 18 ? name.substring(0, 18) : name;
    final padding = ' ' * (18 - displayName.length);
    buffer.writeln(
      '\x1B\x21\x11 ${quantity.toString().padLeft(3)}     X${total.toStringAsFixed(2).padLeft(8)}  $displayName  \x1B\x21\x00'
    );
    buffer.writeln('\n');
  }

  buffer.writeln('-----------------------------------------------');

  // Use \x80 for Euro symbol
  buffer.writeln('\x1B\x21\x13 TOTALE:                   \x80${subtotal.toStringAsFixed(2)} \x1B\x21\x00');

  buffer.writeln('-----------------------------------------------\n');

  final now = DateTime.now();
  final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
  buffer.writeln(dateFormatter.format(now));
  buffer.writeln('\n\n\n');

  return buffer.toString();
}


  Future<void> _printPaymentReceiptContent(
    NetworkPrinter printer,
    String paymentMethod,
    double totalAmount,
    double taxPercentage, {
    String? businessName,
  }) async {
    if (businessName != null && businessName.isNotEmpty) {
      printer.text(
        businessName,
        styles: const esc_pos_utils.PosStyles(
          align: esc_pos_utils.PosAlign.center,
          bold: true,
          height: esc_pos_utils.PosTextSize.size2,
          width: esc_pos_utils.PosTextSize.size2,
        ),
        linesAfter: 1,
      );
    }

    printer.hr();

    printer.text(
      'RICEVUTA PAGAMENTO',
      styles: const esc_pos_utils.PosStyles(
        align: esc_pos_utils.PosAlign.center,
        bold: true,
        height: esc_pos_utils.PosTextSize.size2,
      ),
      linesAfter: 1,
    );

    printer.hr();

    final tax = totalAmount * (taxPercentage / 100);
    final subtotal = totalAmount - tax;

    printer.row([
      esc_pos_utils.PosColumn(
        text: 'Subtotale',
        width: 10,
        styles: const esc_pos_utils.PosStyles(bold: true),
      ),
      esc_pos_utils.PosColumn(
        text: '\$${subtotal.toStringAsFixed(2)}',
        width: 2,
        styles: const esc_pos_utils.PosStyles(align: esc_pos_utils.PosAlign.right, bold: true),
      ),
    ]);

    printer.row([
      esc_pos_utils.PosColumn(
        text: 'IVA (${taxPercentage.toStringAsFixed(0)}%)',
        width: 10,
        styles: const esc_pos_utils.PosStyles(bold: true),
      ),
      esc_pos_utils.PosColumn(
        text: '\$${tax.toStringAsFixed(2)}',
        width: 2,
        styles: const esc_pos_utils.PosStyles(align: esc_pos_utils.PosAlign.right, bold: true),
      ),
    ]);

    printer.row([
      esc_pos_utils.PosColumn(
        text: 'TOTALE',
        width: 10,
        styles: const esc_pos_utils.PosStyles(bold: true, height: esc_pos_utils.PosTextSize.size2),
      ),
      esc_pos_utils.PosColumn(
        text: '\$${totalAmount.toStringAsFixed(2)}',
        width: 2,
        styles: const esc_pos_utils.PosStyles(
          align: esc_pos_utils.PosAlign.right,
          bold: true,
          height: esc_pos_utils.PosTextSize.size2,
        ),
      ),
    ]);

    printer.hr();

    printer.text(
      'Metodo Pagamento: $paymentMethod',
      styles: const esc_pos_utils.PosStyles(
        align: esc_pos_utils.PosAlign.center,
      ),
      linesAfter: 1,
    );

    final now = DateTime.now();
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    printer.text(
      dateFormatter.format(now),
      styles: const esc_pos_utils.PosStyles(
        align: esc_pos_utils.PosAlign.center,
      ),
      linesAfter: 2,
    );

    printer.cut();
  }

  Future<void> _printCommandContent(
    NetworkPrinter printer,
    List<Map<String, dynamic>> items,
    double subtotal,
    double taxPercentage, {
    String? businessName,
  }) async {
    if (businessName != null && businessName.isNotEmpty) {
      printer.text(
        businessName,
        styles: const esc_pos_utils.PosStyles(
          align: esc_pos_utils.PosAlign.center,
          bold: true,
          height: esc_pos_utils.PosTextSize.size2,
          width: esc_pos_utils.PosTextSize.size2,
        ),
        linesAfter: 1,
      );
    }

    printer.hr();

    printer.text(
      'ORDINE',
      styles: const esc_pos_utils.PosStyles(
        align: esc_pos_utils.PosAlign.center,
        bold: true,
        height: esc_pos_utils.PosTextSize.size2,
      ),
      linesAfter: 1,
    );

    printer.hr();

    printer.row([
      esc_pos_utils.PosColumn(
        text: 'Articolo',
        width: 8,
        styles: const esc_pos_utils.PosStyles(bold: true, width: esc_pos_utils.PosTextSize.size1),
      ),
      esc_pos_utils.PosColumn(
        text: 'Qty',
        width: 2,
        styles: const esc_pos_utils.PosStyles(bold: true, align: esc_pos_utils.PosAlign.center),
      ),
      esc_pos_utils.PosColumn(
        text: 'Prezzo',
        width: 2,
        styles: const esc_pos_utils.PosStyles(bold: true, align: esc_pos_utils.PosAlign.right),
      ),
    ]);

    printer.hr();

    for (final item in items) {
      final name = item['name'] as String? ?? 'Item';
      final quantity = item['quantity'] as int? ?? 1;
      final price = item['price'] as double? ?? 0.0;
      final total = quantity * price;

      printer.row([
        esc_pos_utils.PosColumn(
          text: name.length > 15 ? name.substring(0, 15) : name,
          width: 8,
        ),
        esc_pos_utils.PosColumn(
          text: quantity.toString(),
          width: 2,
          styles: const esc_pos_utils.PosStyles(align: esc_pos_utils.PosAlign.center),
        ),
        esc_pos_utils.PosColumn(
          text: '\$${total.toStringAsFixed(2)}',
          width: 2,
          styles: const esc_pos_utils.PosStyles(align: esc_pos_utils.PosAlign.right),
        ),
      ]);
    }

    printer.hr();

    printer.row([
      esc_pos_utils.PosColumn(
        text: 'Subtotale',
        width: 10,
        styles: const esc_pos_utils.PosStyles(bold: true),
      ),
      esc_pos_utils.PosColumn(
        text: '\$${subtotal.toStringAsFixed(2)}',
        width: 2,
        styles: const esc_pos_utils.PosStyles(align: esc_pos_utils.PosAlign.right, bold: true),
      ),
    ]);

    final tax = subtotal * (taxPercentage / 100);
    printer.row([
      esc_pos_utils.PosColumn(
        text: 'IVA (${taxPercentage.toStringAsFixed(0)}%)',
        width: 10,
        styles: const esc_pos_utils.PosStyles(bold: true),
      ),
      esc_pos_utils.PosColumn(
        text: '\$${tax.toStringAsFixed(2)}',
        width: 2,
        styles: const esc_pos_utils.PosStyles(align: esc_pos_utils.PosAlign.right, bold: true),
      ),
    ]);

    final total = subtotal + tax;
    printer.row([
      esc_pos_utils.PosColumn(
        text: 'TOTALE',
        width: 10,
        styles: const esc_pos_utils.PosStyles(bold: true, height: esc_pos_utils.PosTextSize.size2),
      ),
      esc_pos_utils.PosColumn(
        text: '\$${total.toStringAsFixed(2)}',
        width: 2,
        styles: const esc_pos_utils.PosStyles(
          align: esc_pos_utils.PosAlign.right,
          bold: true,
          height: esc_pos_utils.PosTextSize.size2,
        ),
      ),
    ]);

    printer.hr();

    final now = DateTime.now();
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    printer.text(
      dateFormatter.format(now),
      styles: const esc_pos_utils.PosStyles(
        align: esc_pos_utils.PosAlign.center,
      ),
      linesAfter: 2,
    );

    printer.cut();
  }

  Future<bool> printOrderViaSunmiPro(
    List<Map<String, dynamic>> items,
    double subtotal,
    double taxPercentage, {
    String? businessName,
    double doaFee = 0.0,
  }) async {
    try {
      await SunmiPrinter.bindingPrinter();

      await SunmiPrinter.initPrinter();

      await _printSunmiOrderContent(
        items,
        subtotal,
        taxPercentage,
        businessName: businessName,
        doaFee: doaFee,
      );

      return true;
    } catch (e) {
      log('Error printing via Sunmi Pro: $e');
      return false;
    }
  }

Future<void> _printSunmiOrderContent(
    List<Map<String, dynamic>> items,
    double subtotal,
    double taxPercentage, {
    String? businessName,
    double doaFee = 0.0,
  }) async {
    
    // Business name (optional)
    if (businessName != null && businessName.isNotEmpty) {
      await SunmiPrinter.printText(
        businessName,
        style: SunmiTextStyle(
          align: SunmiPrintAlign.CENTER,
          bold: true,
          fontSize: 37,
        ),
      );
      await SunmiPrinter.lineWrap(40);
    }

    // Items list in format: "1 X10,00 burger"
    for (final item in items) {
      final name = item['name'] as String? ?? 'Articolo';
      final quantity = item['quantity'] as int? ?? 1;
      final price = item['price'] as double? ?? 0.0;

      // Format line: "1 X10,00 burger"
      await SunmiPrinter.printText(
        '$quantity X${price.toStringAsFixed(2)}  $name',
        style: SunmiTextStyle(
          align: SunmiPrintAlign.LEFT,
          fontSize: 32,
          bold: true,
        ),
      );
      
      await SunmiPrinter.lineWrap(20); // Extra space between items
    }

    await SunmiPrinter.lineWrap(10);
    
    // Alternative for dashed line: print a line of hyphens
    await SunmiPrinter.printText(
      '--------------------------------',
      style: SunmiTextStyle(
        align: SunmiPrintAlign.CENTER,
        fontSize: 20,
      ),
    );
    
    await SunmiPrinter.lineWrap(6);

    // Grand total
    // final tax = subtotal * (taxPercentage / 100);
    // final total = subtotal + tax + doaFee;
    final total = subtotal;
    await SunmiPrinter.printText(
      'TOTALE:          €${total.toStringAsFixed(2)}',
      style: SunmiTextStyle(
        align: SunmiPrintAlign.LEFT,
        bold: true,
        fontSize: 32,
      ),
    );

    await SunmiPrinter.lineWrap(7);
    
    // Second dashed line
    await SunmiPrinter.printText(
      '--------------------------------',
      style: SunmiTextStyle(
        align: SunmiPrintAlign.CENTER,
        fontSize: 20,
      ),
    );
    
    await SunmiPrinter.lineWrap(
      6
    );

    // Date and time
    final now = DateTime.now();
    final dateFormatter = DateFormat('dd/MM/yy HH:mm');
    
    await SunmiPrinter.printText(
      dateFormatter.format(now),
      style: SunmiTextStyle(
        align: SunmiPrintAlign.CENTER,
        fontSize: 28,
      ),
    );

    await SunmiPrinter.lineWrap(22);
    await SunmiPrinter.cutPaper();
  }

  Future<bool> testPrintSunmiPro({String? businessName}) async {
    try {
      await SunmiPrinter.bindingPrinter();

      await SunmiPrinter.initPrinter();

      if (businessName != null && businessName.isNotEmpty) {
        await SunmiPrinter.printText(
          businessName,
          style: SunmiTextStyle(
            align: SunmiPrintAlign.CENTER,
            bold: true,
            fontSize: 30,
          ),
        );
        await SunmiPrinter.lineWrap(1);
      }

      await SunmiPrinter.line(type: 'dashed');

      await SunmiPrinter.printText(
        'STAMPA DI PROVA',
        style: SunmiTextStyle(
          align: SunmiPrintAlign.CENTER,
          bold: true,
          fontSize: 18,
        ),
      );
      await SunmiPrinter.lineWrap(2);

      await SunmiPrinter.line(type: 'dashed');

      final now = DateTime.now();
      final dateFormatter = DateFormat('dd/MM/yyyy HH:mm:ss');

      await SunmiPrinter.printText(
        'Data e Ora:',
        style: SunmiTextStyle(bold: true),
      );
      await SunmiPrinter.printText(dateFormatter.format(now));
      await SunmiPrinter.lineWrap(1);

      await SunmiPrinter.line(type: 'dashed');

      await SunmiPrinter.printText(
        'Stampante configurata correttamente',
        style: SunmiTextStyle(
          align: SunmiPrintAlign.CENTER,
        ),
      );

      await SunmiPrinter.lineWrap(4);
      await SunmiPrinter.cutPaper();

      return true;
    } catch (e) {
      log('Error in test print: $e');
      return false;
    }
  }

  Future<String?> printEpsonReceiptAutomatic(
    List<Map<String, dynamic>> items,
    double totalAmount,
    String paymentMethod, {
    String? tableInfo,
  }) async {
    try {
      print('Starting Epson receipt printing...');
      final printer = await _getEpsonReceiptPrinter();
      print('Epson printer details: $printer');
      if (printer == null) {
        log('Epson receipt printer not found in database');
        return null;
      }

      final receiptData = {
        'items': items,
        'total': totalAmount,
        'tableInfo': tableInfo,
        'date': DateTime.now().toIso8601String(),
        'paymentType': paymentMethod,
      };

      final xmlData = _generateFiscalXml(receiptData);
      print('exml data:  $xmlData');
      return await _sendXmlToEpsonPrinter(printer, xmlData);
    } catch (e) {
      log('Error printing Epson receipt: $e');
      return null;
    }
  }

  Future<Stampante?> _getEpsonReceiptPrinter() async {
    try {
      return await DatabaseService().getEpsonReceiptPrinter();
    } catch (e) {
      log('Error getting Epson printer: $e');
      return null;
    }
  }

  String _generateFiscalXml(Map<String, dynamic> receiptData) {
    final items = receiptData['items'] as List<Map<String, dynamic>>;
    final total = receiptData['total'] as double;
    final tableInfo = receiptData['tableInfo'] as String?;
    final date = receiptData['date'] as String?;
    final paymentType = receiptData['paymentType'] as String?;

    String itemsXml = '';
    for (final item in items) {
      final name = item['name'] as String? ?? 'Item';
      final price = item['price'] as double? ?? 0.0;
      final quantity = item['quantity'] as int? ?? 1;

      final formattedQty = quantity.toStringAsFixed(3).replaceAll('.', ',');
      final formattedPrice = price.toStringAsFixed(2).replaceAll('.', ',');

      itemsXml += '''
        <printRecItem operator="1" description="$name" quantity="$formattedQty" unitPrice="$formattedPrice" department="1" />
''';
    }

    final formattedDate =
        date?.split('T').first ?? DateTime.now().toIso8601String().split('T')[0];

    String paymentsXml = '';
    String paymentTypeCode = '0';
    String paymentDescription = 'CONTANTE';
    String indexCode = '0';

    if (paymentType != null) {
      switch (paymentType.toUpperCase()) {
        case 'CARTA':
          paymentTypeCode = '2';
          paymentDescription = 'CARTA';
          indexCode = '1';
          break;
        case 'TICKET':
          paymentTypeCode = '3';
          paymentDescription = 'TICKET';
          indexCode = '1';
          break;
        case 'SATISPAY':
          paymentTypeCode = '2';
          paymentDescription = 'CARTA';
          indexCode = '1';
        default:
          paymentTypeCode = '0';
          paymentDescription = 'CONTANTE';
          indexCode = '0';
      }
    }

    final formattedAmount = total.toStringAsFixed(2).replaceAll('.', ',');
    paymentsXml = '''
      <printRecTotal operator="1" description="$paymentDescription" payment="$formattedAmount" paymentType="$paymentTypeCode" index="$indexCode" />''';

    return '''<?xml version="1.0" encoding="utf-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
  <soapenv:Body>
    <printerFiscalReceipt>
      <beginFiscalReceipt operator="1" />
      $itemsXml
      <printRecMessage operator="1" message="$formattedDate" type="1" font="1" messageType="2" index="1" />
      $paymentsXml
      <endFiscalReceipt operator="1" />
    </printerFiscalReceipt>
  </soapenv:Body>
</soapenv:Envelope>''';
  }

  Future<String?> _sendXmlToEpsonPrinter(
      Stampante printer, String xmlData) async {
    try {
      final url = Uri.http(printer.indirizzoIp, '/cgi-bin/fpmate.cgi');

      print('ip adress : ${printer.indirizzoIp}');
      print('port : ${printer.porta}');
      log('Sending Epson XML to: $url');
      print('XML Data: $xmlData');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'text/xml'},
        body: xmlData,
      ).timeout(const Duration(seconds: 15));

      log('Epson printer response: ${response.statusCode}');
      print('Epson printer response status: ${response.statusCode}');
      print('Epson printer response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('Receipt printed successfully on Epson printer');
        return response.body;
      } else {
        log('Epson printer error: ${response.body}');
        return null;
      }
    } catch (e) {
      log('Error sending XML to Epson printer: $e');
      return null;
    }
  }

  String? extractPrinterStatusFromResponse(String responseBody) {
    try {
      final document = XmlDocument.parse(responseBody);
      final printerStatusElement = document.findAllElements('printerStatus').firstOrNull;
      if (printerStatusElement != null) {
        final printerStatus = printerStatusElement.innerText.trim();
        if (printerStatus.isNotEmpty && printerStatus.length >= 5) {
          log('Extracted printer status: $printerStatus');
          return printerStatus;
        }
      }
    } catch (e) {
      log('Error extracting printer status: $e');
    }
    return null;
  }

  Future<String?> printRefundReceipt({
    required String zRepNumber,
    required String fiscalReceiptNumber,
    required String receiptISODateTime,
    required String serialNumber,
    required List<Map<String, dynamic>> refundItems,
    required String paymentMethod,
    String? justification = 'Errore emissione',
  }) async {
    try {
      final printer = await _getEpsonReceiptPrinter();
      if (printer == null) {
        log('Epson receipt printer not found for refund');
        return null;
      }

      final refundXml = _generateRefundXml(
        zRepNumber: zRepNumber,
        fiscalReceiptNumber: fiscalReceiptNumber,
        receiptISODateTime: receiptISODateTime,
        serialNumber: serialNumber,
        refundItems: refundItems,
        paymentMethod: paymentMethod,
        justification: justification!,
      );
      print('Refund XML: $refundXml');

      log('Sending refund XML to Epson printer');
      return await _sendXmlToEpsonPrinter(printer, refundXml);
    } catch (e) {
      log('Error printing refund receipt: $e');
      return null;
    }
  }

String _generateRefundXml({
  required String zRepNumber,
  required String fiscalReceiptNumber,
  required String receiptISODateTime,
  required String serialNumber,
  required List<Map<String, dynamic>> refundItems,
  required String paymentMethod,
  required String justification,
}) {
  // Epson date format: DDMMYY
  final parsedDate = DateTime.parse(receiptISODateTime);
 final formattedDate = 
      '${parsedDate.day.toString().padLeft(2, '0')}'
      '${parsedDate.month.toString().padLeft(2, '0')}'
      '${parsedDate.year}';

  final paddedZRepNumber = zRepNumber.padLeft(4, '0');
  final paddedFiscalReceiptNumber = fiscalReceiptNumber.padLeft(4, '0');

  // Build refund header message with original receipt info
  final headerMessage ='VOID $paddedZRepNumber $paddedFiscalReceiptNumber $formattedDate $serialNumber';

  // Calculate total refund amount from all items
  // double totalRefundAmount = 0.0;
  
//   // Build printRecRefund elements for each item
//   String refundItemsXml = '';
//   for (final item in refundItems) {
//     final name = item['name'] as String? ?? 'Item';
//     final price = item['price'] as double? ?? 0.0;
//     final quantity = item['quantity'] as int? ?? 1;
    
//     totalRefundAmount += (price * quantity);
    
//     final formattedQty = quantity.toStringAsFixed(3).replaceAll('.', ',');
//     final formattedPrice = price.toStringAsFixed(2).replaceAll('.', ',');

//     refundItemsXml += '''
//       <printRecRefund operator="1" description="$name" quantity="$formattedQty" unitPrice="$formattedPrice" department="1" />
// ''';
//   }

  // final formattedTotalAmount = totalRefundAmount.toStringAsFixed(2).replaceAll('.', ',');

  // String paymentTypeCode = '0';
  // String paymentDescription = 'CONTANTI';
  // String indexCode = '0';

  // switch (paymentMethod.toUpperCase()) {
  //   case 'CARTA':
  //   case 'SATISPAY':
  //     paymentTypeCode = '2';
  //     paymentDescription = 'CARTA';
  //     indexCode = '1';
  //     break;

  //   case 'TICKET':
  //     paymentTypeCode = '3';
  //     paymentDescription = 'TICKET';
  //     indexCode = '1';
  //     break;

  //   default:
  //     paymentTypeCode = '0';
  //     paymentDescription = 'CONTANTI';
  //     indexCode = '0';
  // }

  return '''<?xml version="1.0" encoding="utf-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
  <soapenv:Body>
    <printerFiscalReceipt>
      <printRecMessage operator="1" message="$headerMessage" messageType="4" />
      
    </printerFiscalReceipt>
  </soapenv:Body>
</soapenv:Envelope>''';
}


}
