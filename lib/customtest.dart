// xml_printer_service.dart
import 'dart:io';
import 'dart:convert';

class XmlPrinterService {
  final String ipAddress;
  final String fiscalId; // Matricola fiscale for authentication
  final bool useHttps;
  
  XmlPrinterService({
    required this.ipAddress,
    required this.fiscalId,
    this.useHttps = false,
  });

  // Build the complete URL as shown on page 13
  String get fetchUrl {
    String protocol = useHttps ? 'https' : 'http';
    return '$protocol://$ipAddress/xml/printer.htm';
  }

  // Create Basic Auth header (username and password are both fiscalId)
  String get basicAuthHeader {
    String credentials = '$fiscalId:$fiscalId';
    String encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $encoded';
  }

  // Send XML via HTTP POST
  Future<Map<String, dynamic>> sendXml(String xml) async {
    final url = fetchUrl;
    
    print('\n📤 SENDING TO: $url');
    print('📤 XML:');
    print('-' * 40);
    print(xml);
    print('-' * 40);
    
    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse(url));
      
      // Set headers as required
      request.headers.set('Content-Type', 'text/plain');
      request.headers.set('authorization', basicAuthHeader);
      request.headers.set('Content-Length', xml.length.toString());
      
      // Send XML
      request.write(xml);
      
      // Get response
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      client.close();
      
      print('\n📥 RESPONSE:');
      print('-' * 40);
      print(responseBody);
      print('-' * 40);
      
      return _parseResponse(responseBody);
      
    } catch (e) {
      throw Exception('HTTP request failed: $e');
    }
  }

  // Parse XML response (based on page 25-27)
  Map<String, dynamic> _parseResponse(String response) {
    Map<String, dynamic> result = {
      'success': false,
      'status': 'ERROR',
      'data': {},
      'raw': response,
    };
    
    try {
      // Check success attribute
      if (response.contains('success="true"')) {
        result['success'] = true;
      } else if (response.contains('success="false"')) {
        result['success'] = false;
      }
      
      // Extract status code
      RegExp statusReg = RegExp(r'status="(\d+)"');
      var match = statusReg.firstMatch(response);
      if (match != null) {
        result['status'] = match.group(1);
      }
      
      // Extract printer status (S1S2S3S4S5 format from page 25)
      RegExp printerReg = RegExp(r'<printerStatus>(\d+)</printerStatus>');
      match = printerReg.firstMatch(response);
      if (match != null) {
        String ps = match.group(1)!;
        result['data']['printerStatus'] = ps;
        
        // Parse status bits (page 25)
        result['data']['coverOpen'] = ps.length > 0 ? ps[0] == '1' : false;
        result['data']['paperEnd'] = ps.length > 1 ? ps[1] == '1' : false;
        result['data']['nearEnd'] = ps.length > 2 ? ps[2] == '1' : false;
        result['data']['ejFull'] = ps.length > 3 ? ps[3] == '1' : false;
        result['data']['ejNearFull'] = ps.length > 4 ? ps[4] == '1' : false;
      }
      
      // Extract last command
      RegExp lastCmdReg = RegExp(r'<lastCommand>(.+?)</lastCommand>');
      match = lastCmdReg.firstMatch(response);
      if (match != null) {
        result['data']['lastCommand'] = match.group(1);
      }
      
      // Extract date/time
      RegExp dtReg = RegExp(r'<dateTime>(.+?)</dateTime>');
      match = dtReg.firstMatch(response);
      if (match != null) {
        result['data']['dateTime'] = match.group(1);
      }
      
      // Extract responseBuf (for commands that return data)
      RegExp bufReg = RegExp(r'<responseBuf>(.+?)</responseBuf>');
      match = bufReg.firstMatch(response);
      if (match != null) {
        result['data']['responseBuf'] = match.group(1);
      }
      
    } catch (e) {
      print('Parse error: $e');
    }
    
    return result;
  }

  // ============= COMMANDS (page 19) =============

  // Get printer info including MATRICOLA (page 66)
  Future<Map<String, dynamic>> getInfo() async {
    String xml = '''<?xml version="1.0" encoding="utf-8"?>
<printerCommand>
  <getInfo></getInfo>
</printerCommand>''';
    
    var result = await sendXml(xml);
    
    // Parse the info response which contains serialNumber
    if (result['success']) {
      RegExp snReg = RegExp(r'<serialNumber>(.+?)</serialNumber>');
      var match = snReg.firstMatch(result['raw']);
      if (match != null) {
        result['data']['serialNumber'] = match.group(1); // This is the MATRICOLA!
      }
      
      // Parse other useful info
      RegExp fpuStateReg = RegExp(r'<fpuState>(.+?)</fpuState>');
      match = fpuStateReg.firstMatch(result['raw']);
      if (match != null) {
        result['data']['fpuState'] = match.group(1);
      }
      
      RegExp zSetReg = RegExp(r'<zSetNumber>(\d+)</zSetNumber>');
      match = zSetReg.firstMatch(result['raw']);
      if (match != null) {
        result['data']['zSetNumber'] = match.group(1);
      }
    }
    
    return result;
  }

  // Get printer status (page 101)
  Future<Map<String, dynamic>> getStatus() async {
    String xml = '''<?xml version="1.0" encoding="utf-8"?>
<printerCommand>
  <queryPrinterStatus></queryPrinterStatus>
</printerCommand>''';
    return await sendXml(xml);
  }

  // Get date/time (page 61)
  Future<Map<String, dynamic>> getDateTime() async {
    String xml = '''<?xml version="1.0" encoding="utf-8"?>
<printerCommand>
  <getDateTime></getDateTime>
</printerCommand>''';
    return await sendXml(xml);
  }

  // Set date/time (page 107)
  Future<Map<String, dynamic>> setDateTime(DateTime dt) async {
    String dateStr = "${dt.day.toString().padLeft(2,'0')}${dt.month.toString().padLeft(2,'0')}${(dt.year % 100).toString().padLeft(2,'0')}${dt.hour.toString().padLeft(2,'0')}${dt.minute.toString().padLeft(2,'0')}";
    
    String xml = '''<?xml version="1.0" encoding="utf-8"?>
<printerCommand>
  <setDateTime date="$dateStr"></setDateTime>
</printerCommand>''';
    return await sendXml(xml);
  }

  // Open cash drawer (page 72)
  Future<Map<String, dynamic>> openDrawer([int drawer = 1]) async {
    String xml = '''<?xml version="1.0" encoding="utf-8"?>
<printerCommand>
  <openDrawer num="$drawer"></openDrawer>
</printerCommand>''';
    return await sendXml(xml);
  }

  // Paper feed (page 54)
  Future<Map<String, dynamic>> feedPaper(int lines) async {
    String xml = '''<?xml version="1.0" encoding="utf-8"?>
<printerCommand>
  <feed rows="$lines"></feed>
</printerCommand>''';
    return await sendXml(xml);
  }

  // Reset printer (cancel any open document) (page 105)
  Future<Map<String, dynamic>> resetPrinter() async {
    String xml = '''<?xml version="1.0" encoding="utf-8"?>
<printerCommand>
  <resetPrinter></resetPrinter>
</printerCommand>''';
    return await sendXml(xml);
  }

  // Get daily totals (page 59)
  Future<Map<String, dynamic>> getDailyTotals() async {
    String xml = '''<?xml version="1.0" encoding="utf-8"?>
<printerCommand>
  <getDailyTotals></getDailyTotals>
</printerCommand>''';
    return await sendXml(xml);
  }

  // ============= NON-FISCAL RECEIPTS (page 17) =============

  // Print kitchen note / non-fiscal receipt (page 114 example)
  Future<Map<String, dynamic>> printKitchenNote({
    required List<String> lines,
  }) async {
    StringBuffer xml = StringBuffer();
    xml.writeln('<?xml version="1.0" encoding="utf-8"?>');
    xml.writeln('<printerNotFiscal>');
    
    // Open non-fiscal receipt
    xml.writeln('  <beginNotFiscal></beginNotFiscal>');
    
    // Print each line using printNormal
    for (var line in lines) {
      // Escape quotes in line
      String safeLine = line.replaceAll('"', '\\"');
      // font="1" for normal, font="2" for bold
      String font = line.startsWith('**') ? '2' : '1';
      xml.writeln('  <printNormal font="$font" data="$safeLine"></printNormal>');
    }
    
    // Close receipt (auto-cuts)
    xml.writeln('  <endNotFiscal></endNotFiscal>');
    xml.writeln('</printerNotFiscal>');
    
    return await sendXml(xml.toString());
  }

  // ============= FISCAL RECEIPTS (page 15) =============

  // Print fiscal receipt (page 113 example)
  Future<Map<String, dynamic>> printFiscalReceipt({
    required List<Map<String, dynamic>> items,
    required double cashAmount,
    String? customerInfo,
  }) async {
    StringBuffer xml = StringBuffer();
    xml.writeln('<?xml version="1.0" encoding="utf-8"?>');
    xml.writeln('<printerFiscalReceipt>');
    
    // Open fiscal receipt
    xml.writeln('  <beginFiscalReceipt></beginFiscalReceipt>');
    
    // Add customer info if provided (using printRecMessage with font="C" as in page 111 example)
    if (customerInfo != null) {
      xml.writeln('  <printRecMessage messageType="3" font="C" message="$customerInfo"></printRecMessage>');
    }
    
    // Print items using printRecItem (page 83)
    for (var item in items) {
      String desc = item['description'].replaceAll('"', '\\"');
      double price = item['price'];
      int qty = item['quantity'] ?? 1;
      int dept = item['department'] ?? 1;
      
      xml.writeln('  <printRecItem description="$desc" unitPrice="$price" department=2 quantity="$qty"></printRecItem>');
    }
    
    // Subtotal (page 90)
    xml.writeln('  <printRecSubtotal></printRecSubtotal>');
    
    // Payment (cash = paymentType="1" as in page 93)
    xml.writeln('  <printRecTotal description="CONTANTI" payment="$cashAmount" paymentType="1"></printRecTotal>');
    
    // Close with cut (page 50)
    xml.writeln('  <endFiscalReceiptCut></endFiscalReceiptCut>');
    xml.writeln('</printerFiscalReceipt>');
    
    return await sendXml(xml.toString());
  }

  // ============= FISCAL DOCUMENTS (INVOICE) (page 21) =============

  // Print invoice (page 111 example)
  Future<Map<String, dynamic>> printInvoice({
    required String invoiceNumber,
    required List<Map<String, dynamic>> items,
    required double total,
    required String paymentType, // "1"=cash, "2"=check, "3"=credit card
    String? customerName,
    String? customerVAT,
  }) async {
    StringBuffer xml = StringBuffer();
    xml.writeln('<?xml version="1.0" encoding="utf-8"?>');
    xml.writeln('<printerFiscalDocument>');
    
    // Open invoice (page 33)
    xml.writeln('  <beginFiscalDocument documentType="directInvoice" documentNumber="$invoiceNumber"></beginFiscalDocument>');
    
    // Add customer if provided (using printRecMessage with font="C" as in page 111)
    if (customerName != null) {
      xml.writeln('  <printRecMessage messageType="3" font="C" message="$customerName"></printRecMessage>');
    }
    if (customerVAT != null) {
      xml.writeln('  <printRecMessage messageType="3" font="C" message="$customerVAT"></printRecMessage>');
    }
    
    // Print items
    for (var item in items) {
      String desc = item['description'].replaceAll('"', '\\"');
      double price = item['price'];
      int qty = item['quantity'] ?? 1;
      int dept = item['department'] ?? 1;
      
      xml.writeln('  <printRecItem description="$desc" unitPrice="$price" department="$dept" quantity="$qty"></printRecItem>');
    }
    
    // Payment
    xml.writeln('  <printRecTotal description="Pagamento" payment="$total" paymentType="$paymentType"></printRecTotal>');
    
    // Close with cut
    xml.writeln('  <endFiscalReceiptCut></endFiscalReceiptCut>');
    xml.writeln('</printerFiscalDocument>');
    
    return await sendXml(xml.toString());
  }

  // ============= REPORTS (page 18) =============

  // Print X report (daily report) (page 97)
  Future<Map<String, dynamic>> printXReport() async {
    String xml = '''<?xml version="1.0" encoding="utf-8"?>
<printerFiscalReport>
  <printXReport></printXReport>
</printerFiscalReport>''';
    return await sendXml(xml);
  }

  // Print Z report (daily closing) (page 99)
  Future<Map<String, dynamic>> printZReport([String description = ""]) async {
    String xml = '''<?xml version="1.0" encoding="utf-8"?>
<printerFiscalReport>
  <printZReport description="$description"></printZReport>
</printerFiscalReport>''';
    return await sendXml(xml);
  }

  // ============= BARCODE (page 74) =============

  // Print barcode
  Future<Map<String, dynamic>> printBarcode({
    required String code,
    required int codeType, // 1=EAN13, 2=EAN8, 3=CODE39, 4=CODE128, 6=QRCODE
    int hriPosition = 2, // 0=none, 2=below
    int height = 6,
  }) async {
    String xml = '''<?xml version="1.0" encoding="utf-8"?>
<printerNotFiscal>
  <beginNotFiscal></beginNotFiscal>
  <printBarCode hRIPosition="$hriPosition" codeType="$codeType" code="$code" barCodeHeight="$height"></printBarCode>
  <endNotFiscal></endNotFiscal>
</printerNotFiscal>''';
    return await sendXml(xml);
  }

  // ============= DISPLAY CONTROL (page 48) =============

  // Write to display
  Future<Map<String, dynamic>> displayText(String text) async {
    // Truncate to 40 chars (20 per line as per page 48)
    if (text.length > 40) text = text.substring(0, 40);
    
    String xml = '''<?xml version="1.0" encoding="utf-8"?>
<printerCommand>
  <displayText data="$text"></displayText>
</printerCommand>''';
    return await sendXml(xml);
  }

  // Clear display (page 41)
  Future<Map<String, dynamic>> clearDisplay() async {
    String xml = '''<?xml version="1.0" encoding="utf-8"?>
<printerCommand>
  <clearText></clearText>
</printerCommand>''';
    return await sendXml(xml);
  }

  // ============= DIRECT IO (page 47) =============

  // Send directIO command (as in your example)
  Future<Map<String, dynamic>> directIO(String command, String data) async {
    String xml = '''<?xml version="1.0" encoding="utf-8"?>
<printerCommand>
  <directIO command="$command" data="$data"></directIO>
</printerCommand>''';
    return await sendXml(xml);
  }
}