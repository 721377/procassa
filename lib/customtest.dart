import 'package:flutter/material.dart';
import 'services/customMang.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Printer App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SimplePrinterScreen(),
    );
  }
}

class SimplePrinterScreen extends StatefulWidget {
  @override
  _SimplePrinterScreenState createState() => _SimplePrinterScreenState();
}

class _SimplePrinterScreenState extends State<SimplePrinterScreen> {
  final CustomProtocolPrinter printer = CustomProtocolPrinter(
    ipAddress: '192.168.16.26',
  );
  
  bool _isPrinting = false;
  String _message = 'Ready to print';

  Future<void> _printSimpleReceipt() async {
    setState(() {
      _isPrinting = true;
      _message = 'Printing...';
    });

    try {
      await printer.printFiscalReceipt();
      
      setState(() {
        _message = 'Receipt printed successfully!';
      });
      
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
      });
      print('Print error: $e');
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simple Printer'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.print,
              size: 80,
              color: _isPrinting ? Colors.blue : Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              _message,
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            if (_isPrinting)
              CircularProgressIndicator(),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isPrinting ? null : _printSimpleReceipt,
              icon: Icon(Icons.print),
              label: Text('Print Receipt'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Printer IP: 192.168.16.26',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}