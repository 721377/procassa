import 'package:flutter/material.dart';
import '../models.dart';
import '../services/database_service.dart';
import '../services/iva_handler.dart';

class IVAScreen extends StatefulWidget {
  const IVAScreen({super.key});

  @override
  State<IVAScreen> createState() => _IVAScreenState();
}

class _IVAScreenState extends State<IVAScreen> {
  final DatabaseService _db = DatabaseService();
  late Future<List<IVA>> _ivas;
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _valoreController = TextEditingController();
  final TextEditingController _ivaCodeController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  IVA? _editingIVA;
  String? _selectedIvaCode;
  int? _selectedDepartment;
  bool _isCustomDepartment = false;

  @override
  void initState() {
    super.initState();
    _ivas = _db.getIVAs();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _valoreController.dispose();
    _ivaCodeController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nomeController.clear();
    _valoreController.clear();
    _ivaCodeController.clear();
    _departmentController.clear();
    _editingIVA = null;
    _selectedIvaCode = null;
    _selectedDepartment = null;
    _isCustomDepartment = false;
  }

  void _openBottomSheet({IVA? iva}) {
    if (iva != null) {
      _nomeController.text = iva.nome;
      _valoreController.text = iva.valore.toString();
      _ivaCodeController.text = iva.ivaCode ?? '';
      _selectedIvaCode = iva.ivaCode;
      _selectedDepartment = iva.department;
      if (iva.ivaCode != null && SimpleIvaManager.isValid(iva.ivaCode!)) {
        _isCustomDepartment = false;
        _departmentController.text = SimpleIvaManager.getDepartment(iva.ivaCode!).toString();
      } else if (iva.department != null) {
        _isCustomDepartment = true;
        _departmentController.text = iva.department.toString();
      }
      _editingIVA = iva;
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
        builder: (context, setDialogState) => Padding(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  iva != null ? 'Modifica IVA' : 'Nuova IVA',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'Nome',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nomeController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Inserisci nome IVA (es: Standard, Ridotta)',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Valore (%)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _valoreController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                setDialogState(() {
                  if (value.isNotEmpty) {
                    final parsedValue = double.tryParse(value);
                    if (parsedValue != null) {
                      final code = SimpleIvaManager.getCodeByRate(parsedValue);
                      if (code != null) {
                        _selectedIvaCode = code;
                        _isCustomDepartment = false;
                        _departmentController.text = SimpleIvaManager.getDepartment(code).toString();
                        _selectedDepartment = SimpleIvaManager.getDepartment(code);
                      }
                    }
                  }
                });
              },
              decoration: InputDecoration(
                hintText: 'Inserisci valore (es: 22, 10, 5)',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Codice IVA (Opzionale)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: _selectedIvaCode,
                  icon: const Icon(Icons.arrow_drop_down_rounded),
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  hint: const Text(
                    'Seleziona un codice IVA',
                    style: TextStyle(color: Colors.grey),
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedIvaCode = value;
                      if (value != null && SimpleIvaManager.isValid(value)) {
                        _isCustomDepartment = false;
                        _departmentController.text = SimpleIvaManager.getDepartment(value).toString();
                        _selectedDepartment = SimpleIvaManager.getDepartment(value);
                        _valoreController.text = SimpleIvaManager.getRate(value).toStringAsFixed(1);
                      }
                    });
                  },
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Nessuno'),
                    ),
                    ...SimpleIvaManager.getAllCodes().map((code) {
                      final description = SimpleIvaManager.getDescription(code);
                      return DropdownMenuItem<String?>(
                        value: code,
                        child: Text('$code - $description'),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Dipartimento',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _departmentController,
                    keyboardType: TextInputType.number,
                    readOnly: !_isCustomDepartment && _selectedIvaCode != null,
                    decoration: InputDecoration(
                      hintText: 'Inserisci numero dipartimento',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_selectedIvaCode != null)
                  ElevatedButton(
                    onPressed: () {
                      setDialogState(() {
                        _isCustomDepartment = !_isCustomDepartment;
                        if (!_isCustomDepartment && SimpleIvaManager.isValid(_selectedIvaCode!)) {
                          _departmentController.text = SimpleIvaManager.getDepartment(_selectedIvaCode!).toString();
                        } else {
                          _departmentController.clear();
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCustomDepartment ? Colors.orange : Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _isCustomDepartment ? 'Custom' : 'Auto',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      'Annulla',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveIVA,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6FF1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Salva',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _saveIVA() async {
    if (_nomeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Inserisci un nome'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    if (_valoreController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Inserisci un valore'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    final valore = double.tryParse(_valoreController.text);
    if (valore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Il valore deve essere un numero'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    int? department;
    if (_departmentController.text.isNotEmpty) {
      department = int.tryParse(_departmentController.text);
      if (department == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Il dipartimento deve essere un numero'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }
    }

    if (_editingIVA != null) {
      final updated = IVA(
        id: _editingIVA!.id,
        nome: _nomeController.text,
        valore: valore,
        ivaCode: _selectedIvaCode,
        department: department,
      );
      await _db.updateIVA(updated);
    } else {
      final newIVA = IVA(
        nome: _nomeController.text,
        valore: valore,
        ivaCode: _selectedIvaCode,
        department: department,
      );
      await _db.insertIVA(newIVA);
    }

    _resetForm();
    setState(() {
      _ivas = _db.getIVAs();
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _editingIVA != null ? 'IVA modificata' : 'IVA aggiunta',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _deleteIVA(IVA iva) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Elimina IVA',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Sei sicuro di voler eliminare "${iva.nome}" (${iva.valore}%)?',
          style: TextStyle(color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _db.deleteIVA(iva.id!);
              setState(() {
                _ivas = _db.getIVAs();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('IVA eliminata'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red[100]!),
              ),
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openBottomSheet(),
        backgroundColor: const Color(0xFF2D6FF1),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        child: const Icon(Icons.add_rounded, size: 24),
      ),
      body: FutureBuilder<List<IVA>>(
        future: _ivas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2D6FF1),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Errore nel caricamento',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final ivas = snapshot.data ?? [];

          if (ivas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.percent_outlined,
                    size: 72,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nessuna IVA',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aggiungi la tua prima IVA',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: ivas.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final iva = ivas[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  title: Text(
                    iva.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '${iva.valore}%',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _openBottomSheet(iva: iva),
                        icon: Icon(
                          Icons.edit_outlined,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _deleteIVA(iva),
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red[400],
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

}
