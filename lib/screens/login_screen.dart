import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:procassa/screens/pos_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Color Palette
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
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedStore;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _stores = [
    'Milano Centro',
    'Roma Termini',
    'Firenze Duomo',
    'Napoli Piazza',
    'Torino Centro',
    'Venezia San Marco',
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate() && _selectedStore != null) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Accesso effettuato con successo!'),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PosScreen()),
      );
    } else if (_selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Seleziona un punto vendita'),
          backgroundColor: dangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          
          // Extra small screens (phones in portrait)
          if (screenWidth < 375) {
            return _buildExtraSmallLayout();
          }
          // Small screens (phones)
          else if (screenWidth < 600) {
            return _buildMobileLayout();
          }
          // Medium screens (tablets in portrait)
          else if (screenWidth < 900) {
            return _buildTabletLayout();
          }
          // Large screens (tablets in landscape, small desktops)
          else if (screenWidth < 1200) {
            return _buildLargeLayout();
          }
          // Extra large screens (desktops)
          else {
            return _buildDesktopLayout();
          }
        },
      ),
    );
  }

  // Extra Small Layout (iPhone SE, small phones)
  Widget _buildExtraSmallLayout() {
    return Stack(
      children: [
        // Background Image
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
        
        // Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.85),
                  Colors.black.withOpacity(0.65),
                  Colors.black.withOpacity(0.45),
                ],
              ),
            ),
          ),
        ),
        
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ProCassa',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sistema POS',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Login Form Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _buildLoginForm(isExtraSmall: true),
                ),
                
                const SizedBox(height: 30),
                
                // Feature Highlights
                Column(
                  children: [
                    Text(
                      'Caratteristiche:',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildExtraSmallFeatureBadge(
                          icon: Icons.bolt_rounded,
                          title: 'Velocità',
                        ),
                        _buildExtraSmallFeatureBadge(
                          icon: Icons.security_rounded,
                          title: 'Sicurezza',
                        ),
                        _buildExtraSmallFeatureBadge(
                          icon: Icons.analytics_rounded,
                          title: 'Report',
                        ),
                        _buildExtraSmallFeatureBadge(
                          icon: Icons.support_agent_rounded,
                          title: 'Supporto',
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Footer
                _buildExtraSmallFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Mobile Layout (375px - 599px)
  Widget _buildMobileLayout() {
    return Stack(
      children: [
        // Background Image
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
        
        // Gradient Overlay
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
        
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                // Header
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      'Sistema POS Avanzato',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 60),
                
                // Login Form Card
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
                  child: _buildLoginForm(),
                ),
                
                const SizedBox(height: 32),
                
                // Mobile Feature Highlights
                Column(
                  children: [
                    Text(
                      'Caratteristiche principali:',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMobileFeatureBadge(
                          icon: Icons.bolt_rounded,
                          title: 'Velocità',
                          iconColor: const Color(0xFF06D6A0),
                        ),
                        _buildMobileFeatureBadge(
                          icon: Icons.security_rounded,
                          title: 'Sicurezza',
                          iconColor: const Color(0xFF4361EE),
                        ),
                        _buildMobileFeatureBadge(
                          icon: Icons.analytics_rounded,
                          title: 'Report',
                          iconColor: const Color(0xFFEF476F),
                        ),
                        _buildMobileFeatureBadge(
                          icon: Icons.support_agent_rounded,
                          title: 'Supporto',
                          iconColor: const Color(0xFFFFD166),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Footer
                _buildMobileFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Tablet Layout (600px - 899px)
  Widget _buildTabletLayout() {
    return Stack(
      children: [
        // Background Image
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
        
        // Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.75),
                  Colors.black.withOpacity(0.55),
                  Colors.black.withOpacity(0.35),
                ],
              ),
            ),
          ),
        ),
        
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'ProCassa',
                          style: GoogleFonts.poppins(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Sistema POS Avanzato',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Login Form Card
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: _buildLoginForm(),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Tablet Feature Cards
                    Column(
                      children: [
                        Text(
                          'Perché scegliere ProCassa:',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 1.5,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            _buildTabletFeatureCard(
                              icon: Icons.bolt_rounded,
                              title: 'Performance',
                              description: 'Velocità ottimizzata',
                              iconColor: const Color(0xFF06D6A0),
                            ),
                            _buildTabletFeatureCard(
                              icon: Icons.security_rounded,
                              title: 'Sicurezza',
                              description: 'Dati protetti',
                              iconColor: const Color(0xFF4361EE),
                            ),
                            _buildTabletFeatureCard(
                              icon: Icons.analytics_rounded,
                              title: 'Analisi',
                              description: 'Report dettagliati',
                              iconColor: const Color(0xFFEF476F),
                            ),
                            _buildTabletFeatureCard(
                              icon: Icons.support_agent_rounded,
                              title: 'Supporto',
                              description: '24/7 assistenza',
                              iconColor: const Color(0xFFFFD166),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Footer
                    _buildTabletFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Large Layout (900px - 1199px) - Tablet Landscape / Small Desktop
  Widget _buildLargeLayout() {
    return Container(
      color: backgroundColor,
      child: Row(
        children: [
          // Left Panel - Image (40% width)
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                // Background Image
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
                
                // Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.65),
                          Colors.black.withOpacity(0.45),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Content
                Container(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Brand
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ProCassa',
                            style: GoogleFonts.poppins(
                              fontSize: 44,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sistema POS Avanzato',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Feature Highlights
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vantaggi:',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildLargeFeatureBadge(
                                icon: Icons.bolt_rounded,
                                title: 'Performance',
                              ),
                              _buildLargeFeatureBadge(
                                icon: Icons.security_rounded,
                                title: 'Sicurezza',
                              ),
                              _buildLargeFeatureBadge(
                                icon: Icons.analytics_rounded,
                                title: 'Analisi',
                              ),
                              _buildLargeFeatureBadge(
                                icon: Icons.support_agent_rounded,
                                title: 'Supporto',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Right Panel - Form (60% width)
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                constraints: const BoxConstraints(minHeight: 700),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Back
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bentornato',
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Accedi per gestire il tuo punto vendita',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Login Form
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 450),
                      child: _buildLoginForm(),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Footer
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Desktop Layout (1200px and above)
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Panel - Image Section
        Expanded(
          child: Stack(
            children: [
              // Background Image
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
              
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              // Content Overlay
              Positioned.fill(
                child: Container(
                  padding: const EdgeInsets.all(60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ProCassa',
                            style: GoogleFonts.poppins(
                              fontSize: 52,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sistema POS Avanzato',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      // Feature Highlights
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Perché scegliere ProCassa:',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 30),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _buildDesktopFeatureCard(
                                  icon: Icons.bolt_rounded,
                                  title: 'Performance',
                                  description: 'Velocità e affidabilità garantite',
                                  iconColor: const Color(0xFF06D6A0),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildDesktopFeatureCard(
                                  icon: Icons.security_rounded,
                                  title: 'Sicurezza',
                                  description: 'Dati protetti e crittografati',
                                  iconColor: const Color(0xFF4361EE),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildDesktopFeatureCard(
                                  icon: Icons.analytics_rounded,
                                  title: 'Analisi',
                                  description: 'Report dettagliati in tempo reale',
                                  iconColor: const Color(0xFFEF476F),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Right Panel - Login Form
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              constraints: const BoxConstraints(minHeight: 800),
              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Back Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bentornato',
                        style: GoogleFonts.poppins(
                          fontSize: 40,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Accedi per gestire il tuo punto vendita',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          color: textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // Login Form
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: _buildLoginForm(),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Footer
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Shared Login Form
  Widget _buildLoginForm({bool isExtraSmall = false}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form Title
          Text(
            'Accedi',
            style: GoogleFonts.poppins(
              fontSize: isExtraSmall ? 22 : 24,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Inserisci le tue credenziali per continuare',
            style: GoogleFonts.inter(
              fontSize: isExtraSmall ? 13 : 14,
              color: textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          
          SizedBox(height: isExtraSmall ? 20 : 28),
          
          // Username Field
          TextFormField(
            controller: _usernameController,
            style: GoogleFonts.inter(
              fontSize: isExtraSmall ? 15 : 16,
              color: textPrimary,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              hintText: 'Nome utente',
              hintStyle: GoogleFonts.inter(
                color: textTertiary,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(Icons.person_outline_rounded, 
                color: textTertiary, size: isExtraSmall ? 18 : 20),
              filled: true,
              fillColor: surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isExtraSmall ? 8 : 10),
                borderSide: const BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isExtraSmall ? 8 : 10),
                borderSide: const BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isExtraSmall ? 8 : 10),
                borderSide: BorderSide(color: primaryColor, width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isExtraSmall ? 12 : 14,
              ),
            ),
            validator: (value) =>
                value!.isEmpty ? 'Inserisci nome utente' : null,
          ),
          
          SizedBox(height: isExtraSmall ? 12 : 16),
          
          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: GoogleFonts.inter(
              fontSize: isExtraSmall ? 15 : 16,
              color: textPrimary,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              hintText: 'Password',
              hintStyle: GoogleFonts.inter(
                color: textTertiary,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(Icons.lock_outline_rounded, 
                color: textTertiary, size: isExtraSmall ? 18 : 20),
              filled: true,
              fillColor: surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isExtraSmall ? 8 : 10),
                borderSide: const BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isExtraSmall ? 8 : 10),
                borderSide: const BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isExtraSmall ? 8 : 10),
                borderSide: BorderSide(color: primaryColor, width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isExtraSmall ? 12 : 14,
              ),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: textTertiary,
                  size: isExtraSmall ? 18 : 20,
                ),
              ),
            ),
            validator: (value) =>
                value!.isEmpty ? 'Inserisci password' : null,
          ),
          
          SizedBox(height: isExtraSmall ? 12 : 16),
          
          // Store Dropdown
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(isExtraSmall ? 8 : 10),
              border: Border.all(color: borderColor),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedStore,
              style: GoogleFonts.inter(
                fontSize: isExtraSmall ? 15 : 16,
                color: textPrimary,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isExtraSmall ? 12 : 14,
                ),
                hintText: 'Punto vendita',
                hintStyle: GoogleFonts.inter(
                  color: textTertiary,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(Icons.store_mall_directory_outlined, 
                  color: textTertiary, size: isExtraSmall ? 18 : 20),
              ),
              items: _stores
                  .map((store) => DropdownMenuItem(
                        value: store,
                        child: Text(
                          store,
                          style: GoogleFonts.inter(fontSize: isExtraSmall ? 15 : 16),
                        ),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedStore = value),
              validator: (value) =>
                  value == null ? 'Seleziona un punto vendita' : null,
              dropdownColor: surfaceColor,
              borderRadius: BorderRadius.circular(isExtraSmall ? 8 : 10),
              icon: Icon(Icons.arrow_drop_down, color: textTertiary),
            ),
          ),
          
          SizedBox(height: isExtraSmall ? 20 : 24),
          
          // Login Button
          SizedBox(
            width: double.infinity,
            height: isExtraSmall ? 44 : 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isExtraSmall ? 8 : 10),
                ),
                elevation: 0,
                shadowColor: primaryColor.withOpacity(0.3),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: isExtraSmall ? 18 : 20,
                      height: isExtraSmall ? 18 : 20,
                      child: const CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Accedi al sistema',
                      style: GoogleFonts.inter(
                        fontSize: isExtraSmall ? 15 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          
          SizedBox(height: isExtraSmall ? 12 : 16),
          
          // Forgot Password
          Center(
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: textSecondary,
              ),
              child: Text(
                'Password dimenticata?',
                style: GoogleFonts.inter(
                  fontSize: isExtraSmall ? 13 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Feature Components for Different Screen Sizes
  Widget _buildExtraSmallFeatureBadge({
    required IconData icon,
    required String title,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFeatureBadge({
    required IconData icon,
    required String title,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 26,
          ),
        ),
        
        const SizedBox(height: 10),
        
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLargeFeatureBadge({
    required IconData icon,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 6),
          
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Footer Components for Different Screen Sizes
  Widget _buildExtraSmallFooter() {
    return Column(
      children: [
        Text(
          'v2.5.1 • Dicotec',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '© ${DateTime.now().year} ProCassa',
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.white.withOpacity(0.6),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFooter() {
    return Column(
      children: [
        Text(
          'v2.5.1 • Powered by Dicotec',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '© ${DateTime.now().year} ProCassa POS System',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white.withOpacity(0.6),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildTabletFooter() {
    return Column(
      children: [
        Text(
          'v2.5.1 • Powered by Dicotec • ${DateTime.now().year}',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '© ${DateTime.now().year} ProCassa POS System',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withOpacity(0.6),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Divider(color: borderColor),
        const SizedBox(height: 16),
        Text(
          'v2.5.1 • Powered by Dicotec',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: textTertiary,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '© ${DateTime.now().year} ProCassa POS System',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: textTertiary.withOpacity(0.7),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}