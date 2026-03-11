import 'package:flutter/foundation.dart';
import 'database_service.dart';

class CurrencyService extends ChangeNotifier {
  static final CurrencyService _instance = CurrencyService._internal();
  String _currency = '€';

  factory CurrencyService() {
    return _instance;
  }

  CurrencyService._internal();

  String get currency => _currency;

  Future<void> init() async {
    final savedCurrency = await DatabaseService().getSetting('currency');
    if (savedCurrency != null) {
      _currency = savedCurrency;
      notifyListeners();
    }
  }

  Future<void> setCurrency(String newCurrency) async {
    _currency = newCurrency;
    await DatabaseService().saveSetting('currency', newCurrency);
    notifyListeners();
  }
}
