// xml_test.dart
import 'dart:io';
import 'customtest.dart';

void main() async {
  print('=' * 50);
  print('CUSTOM EDGE-N XML PROTOCOL TEST');
  print('=' * 50);
  
  // Enter your printer details
  stdout.write('Enter printer IP [192.168.16.77]: ');
  String ip = stdin.readLineSync() ?? '192.168.16.88';
  if (ip.isEmpty) ip = '192.168.16.88';
  
  stdout.write('Enter fiscal ID (matricola) [STMTE770228]: ');
  String fiscalId = stdin.readLineSync() ?? 'STMTE770228';
  if (fiscalId.isEmpty) fiscalId = 'STETE501318';
  
  final printer = XmlPrinterService(
    ipAddress: ip,
    fiscalId: fiscalId,
  );

  print('\n📋 Configuration:');
  print('   URL: ${printer.fetchUrl}');
  print('   Fiscal ID: $fiscalId');
  
  try {
    // First, test connection with getInfo
    print('\n🔍 Testing connection...');
    var info = await printer.getInfo();
    
    if (info['success']) {
      print('✅ Connected successfully!');
      if (info['data'].containsKey('serialNumber')) {
        print('   Matricola: ${info['data']['serialNumber']}');
      }
      if (info['data'].containsKey('fpuState')) {
        print('   State: ${info['data']['fpuState']}');
      }
    } else {
      print('❌ Connection failed with status: ${info['status']}');
    }
    
    // Menu
    while (true) {
      print('\n' + '-' * 40);
      print('COMMANDS:');
      print('  1 - Get Printer Status');
      print('  2 - Get Info (including Matricola)');
      print('  3 - Print Kitchen Note (Non-Fiscal)');
      print('  4 - Print Fiscal Receipt');
      print('  5 - Print Invoice');
      print('  6 - Open Cash Drawer');
      print('  7 - Print X Report');
      print('  8 - Print Z Report (Daily Close)');
      print('  9 - DirectIO Command (like example)');
      print('  10 - Reset Printer');
      print('  0 - Exit');
      print('-' * 40);
      
      stdout.write('Select: ');
      String? choice = stdin.readLineSync();
      if (choice == '0') break;
      
      try {
        Map<String, dynamic>? result;
        
        switch (choice) {
          case '1':
            result = await printer.getStatus();
            print('\n✅ Status retrieved');
            if (result['data'].containsKey('printerStatus')) {
              print('Cover Open: ${result['data']['coverOpen']}');
              print('Paper End: ${result['data']['paperEnd']}');
            }
            break;
            
          case '2':
            result = await printer.getInfo();
            if (result['success']) {
              print('\n✅ Printer Info:');
              result['data'].forEach((key, value) {
                print('   $key: $value');
              });
            }
            break;
            
          case '3':
            // Kitchen note example from page 114
            result = await printer.printKitchenNote(
              lines: [
                '🍕 PIZZA PAUL\'S',
                '------------------',
                'Table: 5',
                '2x Margherita Pizza',
                '1x Coca Cola',
                '1x Tiramisu',
                '------------------',
                '** NO ONIONS **',
                '17:30 12/03/2024',
              ],
            );
            print('\n✅ Kitchen note printed!');
            break;
            
          case '4':
            // Fiscal receipt example from page 113
            result = await printer.printFiscalReceipt(
              items: [
                {'description': 'PANINO', 'price': 350.00, 'quantity': 2000},
                {'description': 'PIZZA', 'price': 450.00, 'quantity': 1000},
              ],
              cashAmount: 11.50,
            );
            print('\n✅ Fiscal receipt printed!');
            break;
            
          case '5':
            // Invoice example from page 111
            result = await printer.printInvoice(
              invoiceNumber: '1',
              items: [
                {'description': 'PANINO', 'price': 350.00, 'quantity': 2},
                {'description': 'PANINO', 'price': 350.00, 'quantity': 2},
              ],
              total: 700.00,
              paymentType: '1',
              customerName: 'Mario Rossi',
              customerVAT: 'RSSMRA80A01H501X',
            );
            print('\n✅ Invoice printed!');
            break;
            
          case '6':
            result = await printer.openDrawer();
            print('\n✅ Cash drawer opened!');
            break;
            
          case '7':
            result = await printer.printXReport();
            print('\n✅ X Report printed!');
            break;
            
          case '8':
            result = await printer.printZReport('Daily Close');
            print('\n✅ Z Report printed!');
            break;
            
          case '9':
            // DirectIO example from your code
            print('\n📤 Sending DirectIO command 2202 with data="07"');
            result = await printer.directIO('2202', '07');
            print('\n✅ DirectIO command sent!');
            break;
            
          case '10':
            result = await printer.resetPrinter();
            print('\n✅ Printer reset!');
            break;
            
          default:
            print('Invalid choice');
        }
        
        if (result != null && !result['success']) {
          print('⚠️ Command failed with status: ${result['status']}');
          
          // Map status codes to error messages (from page 127-142)
          switch(result['status']) {
            case '3':
              print('   ERR03: Invalid value');
              break;
            case '16':
              print('   ERR16: Paper end');
              break;
            case '24':
              print('   ERR24: Error in command length');
              break;
            case '64':
              print('   ERR64: Cover open');
              break;
            case '98':
              print('   ERR98: Device busy');
              break;
          }
        }
        
      } catch (e) {
        print('\n❌ Error: $e');
      }
    }
    
  } catch (e) {
    print('\n❌ Connection failed: $e');
    print('\nTroubleshooting:');
    print('1. Check if printer is ON');
    print('2. Verify IP address: $ip');
    print('3. Verify fiscal ID: $fiscalId');
    print('4. Try: ${printer.fetchUrl} in browser');
  }
}