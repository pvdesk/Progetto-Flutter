import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyCodeController = TextEditingController();
  final _nomeController = TextEditingController();
  final _cognomeController = TextEditingController();
  final _codiceFiscaleController = TextEditingController();
  final _dataNascitaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCompanyCode();
  }

  Future<void> _loadSavedCompanyCode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('saved_company_code');
    if (savedCode != null && mounted) {
      _companyCodeController.text = savedCode;
    }
  }

  @override
  void dispose() {
    _companyCodeController.dispose();
    _nomeController.dispose();
    _cognomeController.dispose();
    _codiceFiscaleController.dispose();
    _dataNascitaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    final companyCode = _companyCodeController.text.trim();
    if (companyCode.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_company_code', companyCode);
    }

    final success = await authProvider.register(
      companyCode,
      _nomeController.text.trim(),
      _cognomeController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      _codiceFiscaleController.text.trim(),
      _dataNascitaController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrazione completata con successo! Ora puoi accedere.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Torna alla schermata di login
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Errore durante la registrazione'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrazione'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF020617)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(28.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Crea un nuovo account',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // Codice Azienda
                      TextFormField(
                        controller: _companyCodeController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Codice Azienda', Icons.business_center_outlined),
                        validator: (val) => (val == null || val.isEmpty) ? 'Inserisci il Codice Azienda' : null,
                      ),
                      const SizedBox(height: 16),

                      // Nome
                      TextFormField(
                        controller: _nomeController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Nome', Icons.person_outline),
                        validator: (val) => (val == null || val.isEmpty) ? 'Inserisci il nome' : null,
                      ),
                      const SizedBox(height: 16),

                      // Cognome
                      TextFormField(
                        controller: _cognomeController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Cognome', Icons.person_outline),
                        validator: (val) => (val == null || val.isEmpty) ? 'Inserisci il cognome' : null,
                      ),
                      const SizedBox(height: 16),

                      // Codice Fiscale
                      TextFormField(
                        controller: _codiceFiscaleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Codice Fiscale', Icons.badge_outlined),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Inserisci il Codice Fiscale';
                          if (val.length != 16) return 'Il Codice Fiscale deve essere di 16 caratteri';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Data di Nascita
                      TextFormField(
                        controller: _dataNascitaController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Data di Nascita (YYYY-MM-DD) opzionale', Icons.calendar_today_outlined),
                        validator: (val) {
                          if (val != null && val.isNotEmpty) {
                            if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(val)) {
                              return 'Formato non valido, usa YYYY-MM-DD';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Email', Icons.email_outlined),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Inserisci l\'email';
                          if (!val.contains('@')) return 'Inserisci un\'email valida';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                          prefixIcon: Icon(Icons.lock_outline_rounded, color: Theme.of(context).primaryColor),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white.withOpacity(0.6),
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.04),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.redAccent),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Inserisci la password';
                          if (val.length < 6) return 'Minimo 6 caratteri';
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Pulsante Registrati
                      ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'REGISTRATI',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
      prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
