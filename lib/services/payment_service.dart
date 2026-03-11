import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import '../models.dart';
import '../util/printer_status_decoder.dart' as decoder;
import 'printing_service.dart';
import 'database_service.dart';

class PaymentService {
  final PrintingService _printingService = PrintingService();
  final DatabaseService _databaseService = DatabaseService();

  void validatePrinterStatus(
      Map<String, String> statusSegments, List<String> errors) {
    if (statusSegments['printer'] != 'OK') {
      final printerStatus =
          statusSegments['printer'] ?? 'Errore stampante sconosciuto';
      if (printerStatus != 'Carta in esaurimento') {
        errors.add(printerStatus);
      }
    }
    if (statusSegments['ej'] != 'Giornale elettronico OK') {
      errors.add(statusSegments['ej'] ?? 'Errore giornale elettronico');
    }
    if (statusSegments['cashDrawer'] != 'Cassetto chiuso') {
      errors.add(statusSegments['cashDrawer'] ?? 'Errore cassetto');
    }
    if (statusSegments['receipt'] != 'Scontrino chiuso') {
      errors.add(statusSegments['receipt'] ?? 'Errore scontrino');
    }
    if (statusSegments['mode'] != 'Stato: Registrazione') {
      errors.add(statusSegments['mode'] ?? 'Errore modalità');
    }
  }

  bool checkPaperWarning(Map<String, String> statusSegments) {
    final printerStatus = statusSegments['printer'] ?? '';
    return printerStatus == 'Carta in esaurimento';
  }

  Map<String, dynamic> parsePrinterResponse(String responseBody) {
    final result = <String, dynamic>{
      'fiscalReceiptNumber': null,
      'receiptISODateTime': null,
      'zRepNumber': null,
      'serialNumber': null,
      'statusSegments': <String, String>{},
      'printerStatus': null,
      'fiscalReceiptDate': null,
    };

    try {
      final document = XmlDocument.parse(responseBody);

      // Check for Custom response format
      final customResponse = document.findElements('response').firstOrNull;
      if (customResponse != null) {
        final successAttr = customResponse.getAttribute('success');
        if (successAttr == 'true') {
          final addInfo = customResponse.findElements('addInfo').firstOrNull;
          if (addInfo != null) {
            // Extract custom printer fields from addInfo
            final printerStatus = addInfo.findElements('printerStatus').firstOrNull?.innerText.trim();
            if (printerStatus != null && printerStatus.isNotEmpty) {
              result['printerStatus'] = printerStatus;
            }

            // fiscalDoc is the custom printer's equivalent of fiscalReceiptNumber
            final fiscalDoc = addInfo.findElements('fiscalDoc').firstOrNull?.innerText.trim();
            if (fiscalDoc != null && fiscalDoc.isNotEmpty) {
              result['fiscalReceiptNumber'] = fiscalDoc;
            }

            // dateTime is the custom printer's equivalent of receiptISODateTime
            final dateTime = addInfo.findElements('dateTime').firstOrNull?.innerText.trim();
            if (dateTime != null && dateTime.isNotEmpty) {
              result['receiptISODateTime'] = dateTime;
            }

            // nClose is the custom printer's equivalent of zRepNumber (Z report number)
            final nClose = addInfo.findElements('nClose').firstOrNull?.innerText.trim();
            if (nClose != null && nClose.isNotEmpty) {
              result['zRepNumber'] = nClose;
            }
          }
          
          // Also check for standard Epson-style fields in case custom printer returns them
          final fiscalReceiptNumber = customResponse.findElements('fiscalReceiptNumber').firstOrNull?.innerText.trim();
          if (fiscalReceiptNumber != null && fiscalReceiptNumber.isNotEmpty && result['fiscalReceiptNumber'] == null) {
            result['fiscalReceiptNumber'] = fiscalReceiptNumber;
          }
          
          final receiptISODateTime = customResponse.findElements('receiptISODateTime').firstOrNull?.innerText.trim();
          if (receiptISODateTime != null && receiptISODateTime.isNotEmpty && result['receiptISODateTime'] == null) {
            result['receiptISODateTime'] = receiptISODateTime;
          }
          
          final zRepNumber = customResponse.findElements('zRepNumber').firstOrNull?.innerText.trim();
          if (zRepNumber != null && zRepNumber.isNotEmpty && result['zRepNumber'] == null) {
            result['zRepNumber'] = zRepNumber;
          }
          
          final serialNumber = customResponse.findElements('serialNumber').firstOrNull?.innerText.trim();
          if (serialNumber != null && serialNumber.isNotEmpty) {
            result['serialNumber'] = serialNumber;
          }
          
          return result;
        }
      }

      final fiscalReceiptNumberElement =
          document.findAllElements('fiscalReceiptNumber').firstOrNull;
      if (fiscalReceiptNumberElement != null) {
        result['fiscalReceiptNumber'] =
            fiscalReceiptNumberElement.innerText.trim();
      }

      final fiscalReceiptDateElement =
          document.findAllElements('fiscalReceiptDate').firstOrNull;
      if (fiscalReceiptDateElement != null) {
        result['fiscalReceiptDate'] = fiscalReceiptDateElement.innerText.trim();
        print('Fiscal Receipt Date: ${result['fiscalReceiptDate']}');
      }

      final receiptISODateTimeElement =
          document.findAllElements('receiptISODateTime').firstOrNull;
      if (receiptISODateTimeElement != null) {
        result['receiptISODateTime'] =
            receiptISODateTimeElement.innerText.trim();
      }

      final zRepNumberElement =
          document.findAllElements('zRepNumber').firstOrNull;
      if (zRepNumberElement != null) {
        result['zRepNumber'] = zRepNumberElement.innerText.trim();
      }

      final serialNumberElement =
          document.findAllElements('serialNumber').firstOrNull;
      if (serialNumberElement != null) {
        result['serialNumber'] = serialNumberElement.innerText.trim();
      }

      final printerStatusElement =
          document.findAllElements('printerStatus').firstOrNull;
      if (printerStatusElement != null) {
        final printerStatus = printerStatusElement.innerText.trim();
        if (printerStatus.isNotEmpty && printerStatus.length >= 5) {
          result['printerStatus'] = printerStatus;
          result['statusSegments'] =
              decoder.FpStatusDecoder.decodeFpStatusSegments(printerStatus);
          debugPrint('Decoded printer status: ${result["statusSegments"]}');
        } else if (printerStatus.isNotEmpty) {
          debugPrint(
              'Printer status too short: "$printerStatus" (expected at least 5 characters)');
        }
      }
    } catch (e) {
      debugPrint('Error parsing printer response: $e');
    }

    return result;
  }

  Future<String?> printReceiptAndGetResponse(
      List<Map<String, dynamic>> items,
      double total,
      String paymentMethod, {
      double totalDiscount = 0,
    }) async {
    return await _printingService.printReceiptHybrid(
      items,
      total,
      paymentMethod,
      totalDiscount: totalDiscount,
    );
  }

  Future<int> saveTransaction(
      double total,
      String paymentMethod,
      List<CartItem> cartItems,
      {double discount = 0}) async {
    try {
      final transaction = Transaction(
        date: DateTime.now(),
        total: total,
        discount: discount,
        paymentMethod: paymentMethod,
        isReturn: false,
        items: cartItems.map((cartItem) {
          return TransactionItem(
            transactionId: 0,
            productName: cartItem.product.name,
            price: cartItem.product.price,
            quantity: cartItem.quantity,
            total: cartItem.total,
            discount: cartItem.discount,
          );
        }).toList(),
      );

      final transactionId = await _databaseService.insertTransaction(transaction);

      for (final item in transaction.items) {
        await _databaseService.insertTransactionItem(
          TransactionItem(
            transactionId: transactionId,
            productName: item.productName,
            price: item.price,
            quantity: item.quantity,
            total: item.total,
            discount: item.discount,
          ),
        );
      }

      return transactionId;
    } catch (e) {
      debugPrint('Error saving transaction: $e');
      return 0;
    }
  }

  Future<void> updateTransactionWithFiscalData(
      int transactionId,
      Map<String, dynamic> fiscalData) async {
    if (fiscalData.isEmpty || transactionId == 0) return;

    try {
      await _databaseService.updateTransactionWithFiscalData(
        transactionId,
        fiscalData['fiscalReceiptNumber']?.toString(),
        fiscalData['receiptISODateTime']?.toString(),
        fiscalData['zRepNumber']?.toString(),
        fiscalData['serialNumber']?.toString(),
      );
    } catch (e) {
      debugPrint('Error updating transaction with fiscal data: $e');
    }
  }

  String getPaymentMethodLabel(String method) {
    switch (method) {
      case 'CARTA':
        return 'Carta di Credito';
      case 'CONTANTE':
        return 'Contanti';
      case 'TICKET':
        return 'Buono';
      case 'SATISPAY':
        return 'Satispay';
      case 'TRANSFER':
        return 'Bonifico';
      case 'MOBILE':
        return 'Pagamento Mobile';
      default:
        return method;
    }
  }

  Future<Stampante?> getReceiptPrinter() async {
    return await _databaseService.getEpsonReceiptPrinter();
  }
}
