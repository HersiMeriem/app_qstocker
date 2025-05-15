import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPass = TextEditingController();
  final _newPass = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Changer le mot de passe')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildPasswordField(_currentPass, 'Mot de passe actuel'),
              const SizedBox(height: 10),
              _buildPasswordField(_newPass, 'Nouveau mot de passe'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleChange,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Valider'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.length < 6) {
          return 'Entrez au moins 6 caractères';
        }
        return null;
      },
    );
  }

  Future<void> _handleChange() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthService>(context, listen: false).changePassword(
        currentPassword: _currentPass.text,
        newPassword: _newPass.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe mis à jour')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
