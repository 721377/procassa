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
        title: const Text(
          'Impostazioni',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _buildSectionHeader(
            icon: Icons.notifications_outlined,
            title: 'Notifiche',
          ),
          _buildSettingItem(
            title: 'Notifiche push',
            subtitle: 'Ricevi notifiche per nuovi ordini',
            trailing: Switch(
              value: _notifiche,
              onChanged: (value) => setState(() => _notifiche = value),
              activeColor: const Color(0xFF2D6FF1),
            ),
          ),
          _buildSettingItem(
            title: 'Suoni',
            subtitle: 'Attiva suoni dell\'app',
            trailing: Switch(
              value: _suoniApp,
              onChanged: (value) => setState(() => _suoniApp = value),
              activeColor: const Color(0xFF2D6FF1),
            ),
          ),
          _buildSettingItem(
            title: 'Vibrazioni',
            subtitle: 'Attiva feedback tattile',
            trailing: Switch(
              value: _vibrazioni,
              onChanged: (value) => setState(() => _vibrazioni = value),
              activeColor: const Color(0xFF2D6FF1),
            ),
          ),
          const SizedBox(height: 8),
          
          _buildSectionHeader(
            icon: Icons.data_usage_outlined,
            title: 'Dati e Backup',
          ),
          _buildSettingItem(
            title: 'Salvataggio automatico',
            subtitle: 'Salva automaticamente i dati',
            trailing: Switch(
              value: _salvataggioAutomatico,
              onChanged: (value) => setState(() => _salvataggioAutomatico = value),
              activeColor: const Color(0xFF2D6FF1),
            ),
          ),
          _buildSettingItem(
            title: 'Esporta dati',
            subtitle: 'Scarica backup dei dati',
            trailing: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2D6FF1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.download_outlined,
                size: 20,
                color: Color(0xFF2D6FF1),
              ),
            ),
            onTap: () => _showSnackbar('Esportazione in corso...'),
          ),
          _buildSettingItem(
            title: 'Importa dati',
            subtitle: 'Ripristina da backup',
            trailing: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2D6FF1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.upload_outlined,
                size: 20,
                color: Color(0xFF2D6FF1),
              ),
            ),
            onTap: () => _showSnackbar('Importazione in corso...'),
          ),
          const SizedBox(height: 8),
          
          _buildSectionHeader(
            icon: Icons.palette_outlined,
            title: 'Personalizzazione',
          ),
          _buildSettingItem(
            title: 'Tema app',
            subtitle: _tema.capitalize(),
            trailing: SizedBox(
              width: 130,
              child: DropdownButton<String>(
                value: _tema,
                isExpanded: true,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: 'chiaro',
                    child: Text('Chiaro'),
                  ),
                  DropdownMenuItem(
                    value: 'scuro',
                    child: Text('Scuro'),
                  ),
                  DropdownMenuItem(
                    value: 'automatico',
                    child: Text('Automatico'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _tema = value);
                  }
                },
              ),
            ),
          ),
          _buildSettingItem(
            title: 'Lingua',
            subtitle: _lingua.capitalize(),
            trailing: SizedBox(
              width: 130,
              child: DropdownButton<String>(
                value: _lingua,
                isExpanded: true,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: 'italiano',
                    child: Text('Italiano'),
                  ),
                  DropdownMenuItem(
                    value: 'inglese',
                    child: Text('Inglese'),
                  ),
                  DropdownMenuItem(
                    value: 'francese',
                    child: Text('Francese'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _lingua = value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          _buildSectionHeader(
            icon: Icons.info_outline,
            title: 'Informazioni',
          ),
          _buildSettingItem(
            title: 'Versione',
            subtitle: '1.0.0',
            trailing: null,
          ),
          _buildSettingItem(
            title: 'Informazioni app',
            subtitle: 'Note sulla versione e sviluppatore',
            trailing: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.grey,
              ),
            ),
            onTap: _showAboutDialog,
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Divider(
                  color: Colors.grey.withOpacity(0.2),
                  height: 40,
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: Colors.red.withOpacity(0.3),
                      ),
                    ),
                    onPressed: _showResetDialog,
                    child: const Text(
                      'Ripristina impostazioni',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Questa azione reimposterà tutte le preferenze',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF2D6FF1),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D6FF1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.point_of_sale_outlined,
                      size: 32,
                      color: Color(0xFF2D6FF1),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Procassa POS',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Versione 1.0.0',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Un\'applicazione POS moderna e intuitiva per la gestione del punto vendita.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sviluppato con Flutter',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D6FF1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Chiudi',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restore_outlined,
                  size: 32,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ripristina impostazioni',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tutte le impostazioni torneranno ai valori predefiniti.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Annulla',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
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
                        _showSnackbar('Impostazioni ripristinate');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Ripristina',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}