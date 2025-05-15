import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDate;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF548CB8)),
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithGoogle();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      await auth.registerWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _nameController.text,
        gender: _selectedGender ?? 'Non spécifié',
        birthDate: _selectedDate?.toIso8601String() ?? '',
      );

      // Succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Inscription réussie! Un email de confirmation a été envoyé.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pushReplacementNamed(context, '/login');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e.code)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé. Veuillez vous connecter.';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 6 caractères.';
      case 'invalid-email':
        return 'Adresse email invalide. Veuillez entrer une adresse valide.';
      case 'required-fields':
        return 'Veuillez remplir tous les champs obligatoires.';
      case 'user-creation-failed':
        return 'Échec de la création du compte. Veuillez réessayer.';
      default:
        return 'Une erreur est survenue. Veuillez réessayer.';
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF4B5D67), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF4B5D67)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF548CB8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1e4868), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String validatorMsg,
    bool isEmail = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label, icon),
      validator: (value) {
        if (value == null || value.isEmpty) return validatorMsg;
        if (isEmail) {
          if (!value.contains('@') || !value.contains('.')) {
            return 'Email invalide';
          }
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: _inputDecoration(label, Icons.lock).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xFF4B5D67),
          ),
          onPressed: onToggle,
        ),
      ),
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer un mot de passe';
            }
            if (value.length < 6) {
              return 'Le mot de passe doit contenir au moins 6 caractères';
            }
            return null;
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fcff),
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('images/qstocker.png', height: 24),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Q',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e4868),
                    ),
                  ),
                  TextSpan(
                    text: 'Stocker',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF548CB8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1e4868),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Text(
                  'Créer un compte',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF548CB8),
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _nameController,
                  label: 'Nom complet',
                  icon: Icons.person,
                  validatorMsg: 'Veuillez entrer votre nom',
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  validatorMsg: 'Veuillez entrer votre email',
                  isEmail: true,
                ),
                const SizedBox(height: 15),
                _buildPasswordField(
                  controller: _passwordController,
                  label: 'Mot de passe',
                  obscure: _obscurePassword,
                  onToggle:
                      () => setState(() {
                        _obscurePassword = !_obscurePassword;
                      }),
                ),
                const SizedBox(height: 15),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirmer le mot de passe',
                  obscure: _obscureConfirmPassword,
                  onToggle:
                      () => setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      }),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  decoration: _inputDecoration('Sexe', Icons.wc),
                  items:
                      ['Homme', 'Femme', 'Autre']
                          .map(
                            (gender) => DropdownMenuItem(
                              value: gender,
                              child: Text(gender),
                            ),
                          )
                          .toList(),
                  validator:
                      (value) =>
                          value == null ? 'Veuillez choisir votre sexe' : null,
                ),
                const SizedBox(height: 15),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: _inputDecoration(
                      'Date de naissance',
                      Icons.cake,
                    ),
                    child: Text(
                      _selectedDate == null
                          ? 'Sélectionner votre date de naissance'
                          : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            _selectedDate == null
                                ? Colors.grey
                                : Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF548CB8),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const FittedBox(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                              : const FittedBox(
                                child: Text(
                                  'Créer un compte',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'OU',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: Image.asset('images/google.png', height: 20),
                      label: const FittedBox(
                        child: Text(
                          'S\'inscrire avec Google',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Vous avez déjà un compte ? Se connecter',
                    style: TextStyle(
                      color: Color(0xFF548CB8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
