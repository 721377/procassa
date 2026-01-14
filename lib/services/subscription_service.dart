import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:procassa/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:procassa/main.dart';
import 'package:intl/intl.dart';
import 'package:procassa/screens/expired_subscription_screen.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  Future<void> updateLastVerifiedDateFromFiscal(String? fiscalDateStr) async {
    if (fiscalDateStr == null || fiscalDateStr.isEmpty) return;

    try {
      // Input format is "13/1/2026"
      final DateFormat inputFormat = DateFormat('d/M/yyyy');
      final DateTime fiscalDate = inputFormat.parse(fiscalDateStr);

      final db = DatabaseService();
      final info = await db.getAgencyInfo();
      if (info != null) {
        final Map<String, dynamic> updatedInfo = Map.from(info);
        
        // Only update if the fiscal date is newer than the current last verified date
        final currentLastVerifiedStr = info['last_verified_date'];
        if (currentLastVerifiedStr != null) {
          final currentLastVerified = DateTime.parse(currentLastVerifiedStr);
          if (fiscalDate.isAfter(currentLastVerified)) {
            updatedInfo['last_verified_date'] = fiscalDate.toIso8601String();
            await db.saveAgencyInfo(updatedInfo);
          }
        } else {
          updatedInfo['last_verified_date'] = fiscalDate.toIso8601String();
          await db.saveAgencyInfo(updatedInfo);
        }
      }
    } catch (e) {
      print('Error updating last verified date from fiscal: $e');
    }
  }

  Future<DateTime?> getNetworkTime() async {
    // We are now using the fiscal date from the printer as our "trusted" time source
    // to prevent device date tampering.
    return null;
  }

  Future<int> isSubscriptionValid() async {
    final agencyInfo = await DatabaseService().getAgencyInfo();
    if (agencyInfo == null) return 0;

    final expiryDateStr = agencyInfo['subscription_end_date'];
    final lastVerifiedStr = agencyInfo['last_verified_date'];
    
    if (expiryDateStr == null) return 0;

    final expiryDate = DateTime.parse(expiryDateStr);
    final lastVerified = lastVerifiedStr != null ? DateTime.parse(lastVerifiedStr) : null;
    
    // We use device time but compare it against the last date confirmed by the fiscal printer
    final currentTime = DateTime.now();

    // 1. Check if user tampered with date (rolled back before the last fiscal print)
    if (lastVerified != null && currentTime.isBefore(lastVerified)) {
      return 2; // Tampered
    }

    // 2. Check if expired
    if (currentTime.isAfter(expiryDate)) {
      return 1; // Expired
    }

    // 3. Check if expiring soon (3 days or less)
    final difference = expiryDate.difference(currentTime).inDays;
    if (difference <= 3) {
      return 3; // Warning
    }

    return 0; // Valid
  }

  Future<void> checkSubscription(BuildContext context, {bool force = false}) async {
    final db = DatabaseService();
    final info = await db.getAgencyInfo();
    if (info == null) return;

    final lastCheckStr = info['last_check_date'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (!force && lastCheckStr != null) {
      final lastCheck = DateTime.parse(lastCheckStr);
      final lastCheckDay = DateTime(lastCheck.year, lastCheck.month, lastCheck.day);
      
      // If we already checked today, don't check again
      if (today.isAtSameMomentAs(lastCheckDay)) {
        return;
      }
    }

    final status = await isSubscriptionValid();
    
    // Update last check date only if not force or if it was force but now it's fine
    // Actually, always update it if we reached this point, but if it's tampered, 
    // we want to be able to re-check.
    
    final Map<String, dynamic> updatedInfo = Map.from(info);
    updatedInfo['last_check_date'] = now.toIso8601String();
    await db.saveAgencyInfo(updatedInfo);

    if (status == 1) {
      _showBlockedDialog();
    } else if (status == 2) {
      _showTamperDialog();
    } else if (status == 3) {
      _showWarningDialog();
    }
  }

  void _showWarningDialog() {
    final context = MyApp.navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abbonamento in Scadenza'),
        content: const Text('Il tuo abbonamento scadrà tra meno di 3 giorni. Per favore, provvedi al rinnovo per evitare interruzioni del servizio.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTamperDialog() {
    final context = MyApp.navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text('Errore Data Sistema'),
          content: const Text('Rilevata incongruenza nella data del dispositivo. Per favore, imposta la data corretta (uguale o successiva all\'ultima chiusura fiscale).'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                checkSubscription(context, force: true);
              },
              child: const Text('Riprova'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockedDialog() {
    final context = MyApp.navigatorKey.currentContext;
    if (context == null) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const ExpiredSubscriptionScreen()),
      (route) => false,
    );
  }
}
