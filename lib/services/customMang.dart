import 'dart:io';
import 'dart:typed_data';

class CustomProtocolPrinter {
  final String ipAddress;
  final int port;
  int frameCounter = 0;
  
  CustomProtocolPrinter({required this.ipAddress, this.port = 9100});
  
  List<int> _buildCommand(String header, String data) {
    var command = <int>[];
    
    // STX
    command.add(0x02);
    
    // CNT (2 bytes, 00-99, increment for each command)
    var cntStr = frameCounter.toString().padLeft(2, '0');
    command.addAll(cntStr.codeUnits);
    
    // IDENT (fixed to '0')
    command.add(0x30);
    
    // HEADER (4 bytes: 1 + 3 digits)
    command.addAll(header.codeUnits);
    
    // DATA
    command.addAll(data.codeUnits);
    
    // Calculate checksum (CNT + IDENT + HEADER + DATA) mod 100
    var sum = 0;
    for (var i = 1; i < command.length; i++) { // Skip STX
      sum += command[i];
    }
    var checksum = sum % 100;
    command.addAll(checksum.toString().padLeft(2, '0').codeUnits);
    
    // ETX
    command.add(0x03);
    
    frameCounter = (frameCounter + 1) % 100;
    
    return command;
  }
  
  Future<void> printFiscalReceipt() async {
    var socket = await Socket.connect(ipAddress, port);
    
    try {
      // Example: Open fiscal receipt (auto-opens on first sale)
      // Command 3301: Sale operation
      var saleCmd = _buildCommand('3301', '1 000000000 001 09 Product1 000010000 00');
      socket.add(saleCmd);
      await socket.flush();
      
      // Add discount (Command 3301 type 3)
      var discountCmd = _buildCommand('3301', '3 000000000 001 06 Discount 000001000 00');
      socket.add(discountCmd);
      await socket.flush();
      
      // Payment (Command 3007)
      var paymentCmd = _buildCommand('3007', '01 00 08 CASH 000009000');
      socket.add(paymentCmd);
      await socket.flush();
      
      // Close receipt (Command 3011)
      var closeCmd = _buildCommand('3011', '');
      socket.add(closeCmd);
      await socket.flush();
      
      // Cut paper (Command 3013)
      var cutCmd = _buildCommand('3013', '');
      socket.add(cutCmd);
      await socket.flush();
      
      print('Fiscal receipt printed');
      
    } catch (e) {
      print('Error: $e');
    } finally {
      socket.close();
    }
  }
}