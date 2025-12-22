import 'package:flutter/material.dart';

class ImpostazioniScreen extends StatefulWidget {
  const ImpostazioniScreen({super.key});

  @override
  State<ImpostazioniScreen> createState() => _ImpostazioniScreenState();
}

class _ImpostazioniScreenState extends State<ImpostazioniScreen> {
  bool _notifiche = true;
  bool _suoniApp = true;
  bool _vibrazioni = true;
  bool _salvataggioAutomatico = true;
  String _tema = 'chiaro';
  String _lingua = 'italiano';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        backgroundColor: const Color(0xFF2D6FF1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Notifiche'),
            _buildSwitchTile(
              title: 'Notifiche',
              subtitle: 'Ricevi notifiche per nuovi ordini',
              value: _notifiche,
              onChanged: (value) {
                setState(() {
                  _notifiche = value;
                });
              },
            ),
            _buildSwitchTile(
              title: 'Suoni',
              subtitle: 'Abilita suoni dell\'app',
              value: _suoniApp,
              onChanged: (value) {
                setState(() {
                  _suoniApp = value;
                });
              },
            ),
            _buildSwitchTile(
              title: 'Vibrazioni',
              subtitle: 'Abilita vibrazioni',
              value: _vibrazioni,
              onChanged: (value) {
                setState(() {
                  _vibrazioni = value;
                });
              },
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Dati'),
            _buildSwitchTile(
              title: 'Salvataggio Automatico',
              subtitle: 'Salva automaticamente i dati',
              value: _salvataggioAutomatico,
              onChanged: (value) {
                setState(() {
                  _salvataggioAutomatico = value;
                });
              },
            ),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: ListTile(
                title: const Text('Esporta Dati'),
                subtitle: const Text('Scarica backup dei dati'),
                trailing: const Icon(Icons.download),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Esportazione in corso...'),
                    ),
                  );
                },
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: ListTile(
                title: const Text('Importa Dati'),
                subtitle: const Text('Ripristina dati da backup'),
                trailing: const Icon(Icons.upload),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Importazione in corso...'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Personalizzazione'),
            _buildDropdownTile(
              title: 'Tema',
              value: _tema,
              items: const ['chiaro', 'scuro', 'automatico'],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _tema = value;
                  });
                }
              },
            ),
            _buildDropdownTile(
              title: 'Lingua',
              value: _lingua,
              items: const ['italiano', 'inglese', 'francese'],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _lingua = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Informazioni'),
            const Card(
              child: ListTile(
                title: Text('Versione'),
                subtitle: Text('1.0.0'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Info Sviluppatore'),
                trailing: const Icon(Icons.info),
                onTap: () {
                  _showAboutDialog();
                },
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  _showResetDialog();
                },
                child: const Text(
                  'Ripristina Predefiniti',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D6FF1),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF2D6FF1),
        ),
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            DropdownButton<String>(
              value: value,
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
              underline: const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Procassa POS'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versione: 1.0.0'),
            SizedBox(height: 12),
            Text(
              'Un\'applicazione POS moderna e intuitiva per la gestione del punto vendita.',
            ),
            SizedBox(height: 12),
            Text(
              'Sviluppato con Flutter',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ripristina Predefiniti'),
        content: const Text(
          'Sei sicuro di voler ripristinare le impostazioni predefinite?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _notifiche = true;
                _suoniApp = true;
                _vibrazioni = true;
                _salvataggioAutomatico = true;
                _tema = 'chiaro';
                _lingua = 'italiano';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Impostazioni ripristinate'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Ripristina', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
