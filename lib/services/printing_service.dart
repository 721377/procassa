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
import 'iva_handler.dart';

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

  // ============================================================================
  // BLUETOOTH PRINTER - ORDER PRINTING
  // ============================================================================

  Future<bool> printCommandViaBluetooth(
    String bluetoothAddress,
    List<Map<String, dynamic>> items,
    double subtotal,
    double taxPercentage, {
    String? businessName,
  }) async {
    try {
      final printContent = _buildPrintContent(
        items,
        subtotal,
        taxPercentage,
        businessName: businessName,
      );

      final Uint8List bytes = Uint8List.fromList(printContent.codeUnits);

      final success = await bt_printer.FlutterBluetoothPrinter.printBytes(
        address: bluetoothAddress,
        data: bytes,
        keepConnected: true,
        maxBufferSize: 512,
        delayTime: 120,
      );

      if (!success) return false;

      final Uint8List feed5 = Uint8List.fromList([0x1B, 0x69]);
      await bt_printer.FlutterBluetoothPrinter.printBytes(
        address: bluetoothAddress,
        data: feed5,
        keepConnected: false,
        maxBufferSize: 512,
        delayTime: 120,
      );

      return true;
    } catch (e) {
      log("Error printing via Bluetooth: $e");
      return false;
    }
  }

  // ============================================================================
  // BLUETOOTH PRINTER - HELPER METHODS
  // ============================================================================

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

    buffer.writeln('\x1B\x21\x13 TOTALE:                   \x80${subtotal.toStringAsFixed(2)} \x1B\x21\x00');

    buffer.writeln('-----------------------------------------------\n');

    final now = DateTime.now();
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
    buffer.writeln(dateFormatter.format(now));
    buffer.writeln('\n\n\n');

    return buffer.toString();
  }

  // ============================================================================
  // NETWORK/IP PRINTER - ORDER PRINTING
  // ============================================================================

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

  // ============================================================================
  // NETWORK/IP PRINTER - HELPER METHODS
  // ============================================================================

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

  // ============================================================================
  // SUNMI PRINTER - ORDER PRINTING
  // ============================================================================

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

  // ============================================================================
  // SUNMI PRINTER - TEST PRINT
  // ============================================================================

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

  // ============================================================================
  // SUNMI PRINTER - HELPER METHODS
  // ============================================================================

  Future<void> _printSunmiOrderContent(
    List<Map<String, dynamic>> items,
    double subtotal,
    double taxPercentage, {
    String? businessName,
    double doaFee = 0.0,
  }) async {
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

    for (final item in items) {
      final name = item['name'] as String? ?? 'Articolo';
      final quantity = item['quantity'] as int? ?? 1;
      final price = item['price'] as double? ?? 0.0;

      await SunmiPrinter.printText(
        '$quantity X${price.toStringAsFixed(2)}  $name',
        style: SunmiTextStyle(
          align: SunmiPrintAlign.LEFT,
          fontSize: 32,
          bold: true,
        ),
      );

      await SunmiPrinter.lineWrap(20);
    }

    await SunmiPrinter.lineWrap(10);

    await SunmiPrinter.printText(
      '--------------------------------',
      style: SunmiTextStyle(
        align: SunmiPrintAlign.CENTER,
        fontSize: 20,
      ),
    );

    await SunmiPrinter.lineWrap(6);

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

    await SunmiPrinter.printText(
      '--------------------------------',
      style: SunmiTextStyle(
        align: SunmiPrintAlign.CENTER,
        fontSize: 20,
      ),
    );

    await SunmiPrinter.lineWrap(6);

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

  // ============================================================================
  // Epson,RCH,Custom- - RECEIPT PRINTING
  // ============================================================================

  Future<String?> printReceiptHybrid(
    List<Map<String, dynamic>> items,
    double totalAmount,
    String paymentMethod, {
    String? tableInfo,
  }) async {
    try {
      print('Starting receipt printing...');

      final printer = await _getEpsonReceiptPrinter();
      print('Printer details: $printer');
      print('Printertyep ${printer?.receiptPrinterType}');
      if (printer == null) {
        log('Receipt printer not found in database');
        return null;
      }

      final receiptData = {
        'items': items,
        'total': totalAmount,
        'tableInfo': tableInfo,
        'date': DateTime.now().toIso8601String(),
        'paymentType': paymentMethod,
      };

      switch (printer.receiptPrinterType) {
        case 'Epson':
          final xmlData = _generateFiscalXml(receiptData);
          print('xml data: $xmlData');
          return await _sendXmlToEpsonPrinter(printer, xmlData);

        case 'RCH':
          final xmlData = _generateFiscalXmlRCH(receiptData);
          print('xml data: $xmlData');
          return await _sendXmlToRCHPrinter(printer, xmlData);

        default:
          log('Unsupported printer type: ${printer.printerType}');
          return null;
      }
    } catch (e, stackTrace) {
      log('Error printing receipt: $e');
      log(stackTrace.toString());
      return null;
    }
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

  // ============================================================================
  // FISCAL PRINTER - HELPER METHODS
  // ============================================================================

  String _generateFiscalXml(Map<String, dynamic> receiptData) {
    final items = receiptData['items'] as List<Map<String, dynamic>>;
    final total = receiptData['total'] as double;
    final date = receiptData['date'] as String?;
    final paymentType = receiptData['paymentType'] as String?;

    String itemsXml = '';
    for (final item in items) {
      final name = item['name'] as String? ?? 'Item';
      final price = item['price'] as double? ?? 0.0;
      final quantity = item['quantity'] as int? ?? 1;
      final ivaCode = item['ivaCode'] as String?;

      final formattedQty = quantity.toStringAsFixed(3).replaceAll('.', ',');
      final formattedPrice = price.toStringAsFixed(2).replaceAll('.', ',');

      int department = 1;
      if (ivaCode != null && SimpleIvaManager.isValid(ivaCode)) {
        department = SimpleIvaManager.getDepartment(ivaCode);
      }

      itemsXml += '''
        <printRecItem operator="1" description="$name" quantity="$formattedQty" unitPrice="$formattedPrice" department="$department" />
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

  String _generateRefundXml({
    required String zRepNumber,
    required String fiscalReceiptNumber,
    required String receiptISODateTime,
    required String serialNumber,
    required List<Map<String, dynamic>> refundItems,
    required String paymentMethod,
    required String justification,
  }) {
    final parsedDate = DateTime.parse(receiptISODateTime);
    final formattedDate =
        '${parsedDate.day.toString().padLeft(2, '0')}'
        '${parsedDate.month.toString().padLeft(2, '0')}'
        '${parsedDate.year}';

    final paddedZRepNumber = zRepNumber.padLeft(4, '0');
    final paddedFiscalReceiptNumber = fiscalReceiptNumber.padLeft(4, '0');

    final headerMessage = 'VOID $paddedZRepNumber $paddedFiscalReceiptNumber $formattedDate $serialNumber';

    return '''<?xml version="1.0" encoding="utf-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
  <soapenv:Body>
    <printerFiscalReceipt>
      <printRecMessage operator="1" message="$headerMessage" messageType="4" />
      
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

  // ============================================================================
  // RCH FISCAL PRINTER - RECEIPT PRINTING
  // ============================================================================

  Future<String?> _sendXmlToRCHPrinter(
      Stampante printer, String xmlData) async {
    try {
      final url = Uri.http(printer.indirizzoIp, '/service.cgi');

      print('ip adress : ${printer.indirizzoIp}');
      print('port : ${printer.porta}');
      log('Sending Epson XML to: $url');
      print('XML Data: $xmlData');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/xml'},
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

  // ============================================================================
  // RCH FISCAL PRINTER - HELPER METHODS
  // ============================================================================

  String _generateFiscalXmlRCH(Map<String, dynamic> receiptData) {
    final items = receiptData['items'] as List<Map<String, dynamic>>;
    final total = receiptData['total'] as double;
    final tableInfo = receiptData['tableInfo'] as String?;
    final date = receiptData['date'] as String?;
    final paymentType = receiptData['paymentType'] as String?;

    final ivaMapping = {
      '04': {'department': 3, 'rate': 4.0},
      '05': {'department': 4, 'rate': 5.0},
      '10': {'department': 2, 'rate': 10.0},
      '22': {'department': 1, 'rate': 22.0},
    };

    String itemsXml = '';

    for (final item in items) {
      final name = item['name'] as String? ?? 'Item';
      final price = item['price'] as double? ?? 0.0;
      final quantity = item['quantity'] as int? ?? 1;
      final ivaCode = item['ivaCode'] as String?;

      int department = 1;

      if (ivaCode != null && ivaMapping.containsKey(ivaCode)) {
        department = ivaMapping[ivaCode]!['department'] as int;
      }

      final priceInCents = (price * 100).toInt();

      final quantityParam = quantity > 1 ? '/*$quantity' : '';

      final escapedDesc = _escapeRCHDescription(name);

      itemsXml += '<cmd>=R$department/\$$priceInCents$quantityParam/($escapedDesc)</cmd>\n';
    }

    String subtotalXml = '<cmd>=S</cmd>\n';

    String paymentXml = '';

    if (paymentType != null) {
      switch (paymentType.toUpperCase()) {
        case 'CARTA':
        case 'SATISPAY':
        case 'POS':
          paymentXml = '<cmd>=T4</cmd>\n';
          break;
        case 'TICKET':
          paymentXml = '<cmd>=T5</cmd>\n';
          break;
        case 'ASSEGNI':
          paymentXml = '<cmd>=T3</cmd>\n';
          break;
        case 'CREDITO':
        case 'NON RISCOSSO':
          paymentXml = '<cmd>=T2</cmd>\n';
          break;
        default:
          paymentXml = '<cmd>=T1</cmd>\n';
      }
    } else {
      paymentXml = '<cmd>=T1</cmd>\n';
    }

    String additionalInfoXml = '';

    if (date != null && date.isNotEmpty) {
      final formattedDate = date.split('T').first;
      additionalInfoXml += '<cmd>="/?A/(Data: $formattedDate)</cmd>\n';
    }

    return '''<?xml version="1.0" encoding="UTF-8"?>
<Service>
$itemsXml
$subtotalXml
$paymentXml
</Service>''';
  }

  String _escapeRCHDescription(String description) {
    String escaped = description.replaceAll(')', '))');

    escaped = escaped.replaceAll('TOTALE', 'TOT.');

    escaped = escaped.replaceAll('/', ' ');

    if (escaped.length > 36) {
      escaped = escaped.substring(0, 36);
    }

    return escaped;
  }

  // ============================================================================
  // UTILITIES
  // ============================================================================

  Future<Stampante?> _getEpsonReceiptPrinter() async {
    try {
      return await DatabaseService().getEpsonReceiptPrinter();
    } catch (e) {
      log('Error getting Epson printer: $e');
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
}
