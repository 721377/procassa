import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:procassa/l10n/app_localizations.dart';
import 'package:procassa/services/currency_service.dart';
import '../models.dart';
import '../services/database_service.dart';

// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/timezone.dart' as tz;
import '../main.dart';

class DebitScreen extends StatefulWidget {
  const DebitScreen({super.key});

  @override
  State<DebitScreen> createState() => _DebitScreenState();
}

class _DebitScreenState extends State<DebitScreen> {
  final DatabaseService _db = DatabaseService();
  late Future<List<Debit>> _debits;

  final TextEditingController _personController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  DateTime _returnDate = DateTime.now().add(const Duration(days: 7));
  bool _isFromMe = false;
  bool _hasAlarm = false;

  @override
  void initState() {
    super.initState();
    _refreshDebits();
  }

  void _refreshDebits() {
    setState(() {
      _debits = _db.getDebits();
    });
  }

  void _resetForm() {
    _personController.clear();
    _amountController.clear();
    _selectedDate = DateTime.now();
    _returnDate = DateTime.now().add(const Duration(days: 7));
    _isFromMe = false;
    _hasAlarm = false;
  }

  Future<void> _selectDate(BuildContext context, bool isReturnDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isReturnDate ? _returnDate : _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isReturnDate) {
          _returnDate = picked;
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  /*
  Future<void> _scheduleNotification(Debit debit) async {
    final scheduledDate = tz.TZDateTime.from(debit.returnDate, tz.local);
    
    await flutterLocalNotificationsPlugin.zonedSchedule(
      debit.id ?? 0,
      'Debit Return Reminder',
      'Reminder to return ${CurrencyService().currency}${debit.amount.toStringAsFixed(2)} to ${debit.personName}',
      scheduledDate.subtract(const Duration(hours: 1)), // Notify 1 hour before
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'debit_reminders',
          'Debit Reminders',
          channelDescription: 'Notifications for debit return dates',
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
  */

  void _openAddDebitSheet({Debit? debit}) {
    if (debit != null) {
      _personController.text = debit.personName;
      _amountController.text = debit.amount.toString();
      _selectedDate = debit.date;
      _returnDate = debit.returnDate;
      _isFromMe = debit.isFromMe;
      _hasAlarm = debit.hasAlarm;
    } else {
      _resetForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debit != null ? AppLocalizations.of(context)!.editArticle : AppLocalizations.of(context)!.newDebit,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _personController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.person,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.amount,
                    prefixText: '${CurrencyService().currency} ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: Text(AppLocalizations.of(context)!.date),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                        onTap: () async {
                          await _selectDate(context, false);
                          setSheetState(() {});
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: Text(AppLocalizations.of(context)!.returnDate),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(_returnDate)),
                        onTap: () async {
                          await _selectDate(context, true);
                          setSheetState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.debitFrom),
                  subtitle: Text(_isFromMe ? 'I owe them' : 'They owe me'),
                  value: _isFromMe,
                  onChanged: (val) {
                    setSheetState(() => _isFromMe = val);
                  },
                ),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.setAlarm),
                  value: _hasAlarm,
                  onChanged: (val) {
                    setSheetState(() => _hasAlarm = val);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final newDebit = Debit(
                        id: debit?.id,
                        personName: _personController.text,
                        amount: double.tryParse(_amountController.text) ?? 0.0,
                        date: _selectedDate,
                        returnDate: _returnDate,
                        isFromMe: _isFromMe,
                        hasAlarm: _hasAlarm,
                      );

                      if (debit != null) {
                        await _db.updateDebit(newDebit);
                      } else {
                        final id = await _db.insertDebit(newDebit);
                        /*
                        if (_hasAlarm) {
                           _scheduleNotification(Debit(
                             id: id,
                             personName: newDebit.personName,
                             amount: newDebit.amount,
                             date: newDebit.date,
                             returnDate: newDebit.returnDate,
                             isFromMe: newDebit.isFromMe,
                             hasAlarm: true
                           ));
                        }
                        */
                      }

                      Navigator.pop(context);
                      _refreshDebits();
                    },
                    child: Text(AppLocalizations.of(context)!.save),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CurrencyService(),
      builder: (context, child) {
        final symbol = CurrencyService().currency;
        final l10n = AppLocalizations.of(context)!;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.debits),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _openAddDebitSheet(),
              ),
            ],
          ),
          body: FutureBuilder<List<Debit>>(
            future: _debits,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final debits = snapshot.data ?? [];
              if (debits.isEmpty) {
                return const Center(child: Text('No debits found'));
              }
              return ListView.builder(
                itemCount: debits.length,
                itemBuilder: (context, index) {
                  final debit = debits[index];
                  return ListTile(
                    title: Text(debit.personName),
                    subtitle: Text(
                        '${DateFormat('dd/MM/yyyy').format(debit.date)} - Return: ${DateFormat('dd/MM/yyyy').format(debit.returnDate)}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$symbol${debit.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: debit.isFromMe ? Colors.red : Colors.green,
                            fontSize: 16,
                          ),
                        ),
                        if (debit.hasAlarm)
                          const Icon(Icons.alarm, size: 16, color: Colors.blue),
                      ],
                    ),
                    onTap: () => _openAddDebitSheet(debit: debit),
                    onLongPress: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Debit?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _db.deleteDebit(debit.id!);
                        _refreshDebits();
                      }
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
