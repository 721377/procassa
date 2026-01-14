import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:procassa/APIs.dart';
import 'package:procassa/services/database_service.dart';
import 'dart:convert';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  // Color Palette (matching login_screen.dart)
  static const Color primaryColor = Color(0xFF4361EE);
  static const Color successColor = Color(0xFF06D6A0);
  static const Color dangerColor = Color(0xFFEF476F);
  static const Color backgroundColor = Color(0xFFFAFBFC);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color borderColor = Color(0xFFEEEEEE);

  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _companyNameController = TextEditingController();
  final _pivaController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _companyNameController.dispose();
    _pivaController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _contactPersonController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegistration() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Le password non coincidono'),
            backgroundColor: dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);
      
      try {
        final response = await APIs.registerClient(
          companyName: _companyNameController.text,
          nome: _contactPersonController.text,
          email: _emailController.text,
          password: _passwordController.text,
          piva: _pivaController.text,
          phone: _phoneController.text,
          contactPerson: _contactPersonController.text,
          address: _addressController.text,
          city: _cityController.text,
          state: _stateController.text,
          postalCode: _postalCodeController.text,
        );

        setState(() => _isLoading = false);

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          if (result['success'] == true) {
            // Save Agency Info locally
            final now = DateTime.now();
            final expiryDate = now.add(const Duration(days: 31));
            
            final db = DatabaseService();
            await db.saveAgencyInfo({
              'company_name': _companyNameController.text,
              'email': _emailController.text,
              'piva': _pivaController.text,
              'phone': _phoneController.text,
              'address': _addressController.text,
              'city': _cityController.text,
              'state': _stateController.text,
              'postal_code': _postalCodeController.text,
              'contact_person': _contactPersonController.text,
              'subscription_end_date': expiryDate.toIso8601String(),
              'status': 'active'
            });

            // Save User locally for offline login (unhashed as requested)
            await db.saveLocalUser({
              'username': _contactPersonController.text,
              'password': _passwordController.text,
              'email': _emailController.text,
              'agency_id': result['id'],
              'role': 2,
            });

            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: successColor, size: 28),
                      const SizedBox(width: 10),
                      const Text('Registrazione Completata'),
                    ],
                  ),
                  content: const Text(
                    'Il tuo account è stato creato con successo!\n\nSei ora in modalità DEMO gratuita per la durata di 31 giorni.',
                    style: TextStyle(fontSize: 16),
                  ),
                  actions: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Back to login
                        },
                        child: const Text('Inizia Ora', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              );
            }
          } else {
            if (mounted) {
              if (result['message'] == 'Client already exists') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Utente già registrato'),
                    content: const Text('Il cliente con questi dati risulta già presente nel sistema.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Chiudi'),
                      ),
                    ],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Errore durante la registrazione'),
                    backgroundColor: dangerColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Errore del server: ${response.statusCode}'),
                backgroundColor: dangerColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore di connessione: $e'),
              backgroundColor: dangerColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background Image and Gradient (matching login_screen.dart)
          Positioned.fill(
            child: Image.asset(
              'images/loginscreen.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: primaryColor.withOpacity(0.1),
                );
              },
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  children: [
                    // Header
                    Column(
                      children: [
                        Text(
                          'ProCassa',
                          style: GoogleFonts.poppins(
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea il tuo account aziendale',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Registration Form Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: _buildRegistrationForm(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Back to Login
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Hai già un account? Accedi',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Dati Aziendali'),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _companyNameController,
                  label: 'Ragione Sociale',
                  hint: 'es. Tech Solutions S.R.L.',
                  icon: Icons.business_rounded,
                  required: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _pivaController,
                  label: 'Partita IVA / CF',
                  hint: '11 cifre',
                  icon: Icons.badge_outlined,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _emailController,
                  label: 'Email Professionale',
                  hint: 'email@esempio.it',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  required: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _phoneController,
                  label: 'Telefono',
                  hint: '+39 02 ...',
                  icon: Icons.phone_outlined,
                ),
              ),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: borderColor),
          ),
          
          _buildSectionTitle('Sede Legale'),
          _buildTextField(
            controller: _addressController,
            label: 'Indirizzo Sede Legale',
            hint: 'Via/Corso, Numero',
            icon: Icons.location_on_outlined,
          ),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: _cityController,
                  label: 'Città',
                  hint: 'es. Milano',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildTextField(
                  controller: _stateController,
                  label: 'Provincia',
                  hint: 'es. MI',
                  maxLength: 2,
                ),
              ),
            ],
          ),
          _buildTextField(
            controller: _postalCodeController,
            label: 'CAP',
            hint: '5 cifre',
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: borderColor),
          ),
          
          _buildSectionTitle('Sicurezza'),
          _buildTextField(
            controller: _contactPersonController,
            label: 'Username',
            hint: 'Scegli un username',
            icon: Icons.person_outline_rounded,
            required: true,
          ),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  required: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: textTertiary,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Conferma Password',
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscureConfirmPassword,
                  required: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: textTertiary,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Registra account',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textSecondary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    bool obscureText = false,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLength: maxLength,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: textPrimary,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            hintStyle: GoogleFonts.inter(
              color: textTertiary,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: icon != null ? Icon(icon, color: textTertiary, size: 20) : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) {
            if (required && (value == null || value.isEmpty)) {
              return 'Campo obbligatorio';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
