import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/auth_service.dart';
import 'custom_bottom_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _birthDateController;
  String? _selectedGender;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'Français';
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _birthDateController = TextEditingController();
    _loadUserData();
  }

  String _getInitial(String? displayName, String? email) {
    if (displayName != null && displayName.isNotEmpty) {
      return displayName.substring(0, 1).toUpperCase();
    }
    if (email != null && email.isNotEmpty) {
      return email.substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final userData = await authService.getUserData();
      setState(() {
        _nameController.text = userData['fullName'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _birthDateController.text = userData['birthDate'] ?? '';
        _selectedGender = userData['gender'];
        _notificationsEnabled = userData['notificationsEnabled'] ?? true;
        _selectedLanguage = userData['language'] ?? 'Français';
      });
    } catch (e) {
      debugPrint('Erreur chargement données: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final downloadUrl = await authService.uploadProfileImage(
          File(pickedFile.path),
        );
        await authService.updateProfilePhoto(downloadUrl);

        setState(() {
          _profileImage = File(pickedFile.path);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo de profil mise à jour')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFf8fcff),
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: const Color(0xFFf8fcff),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF548CB8)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF548CB8)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => SettingsScreen(
                        language: _selectedLanguage,
                        notificationsEnabled: _notificationsEnabled,
                        onSettingsChanged: (language, notifications) {
                          setState(() {
                            _selectedLanguage = language;
                            _notificationsEnabled = notifications;
                          });
                        },
                      ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProfileHeader(user),
            const SizedBox(height: 30),
            _buildPersonalInfoSection(authService),
            const SizedBox(height: 20),
            _buildSecuritySection(context, authService),
          ],
        ),
      ),
      bottomNavigationBar: buildCustomBottomBar(context, 3),
    );
  }

  Widget _buildProfileHeader(User? user) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
          CircleAvatar(
  radius: 50,
  backgroundColor: const Color(0xFF548CB8),
  backgroundImage: _profileImage != null
      ? FileImage(_profileImage!)
      : user?.photoURL != null
          ? NetworkImage(user!.photoURL!)
          : null,
  child: _profileImage == null && user?.photoURL == null
      ? Text(
          _getInitial(user?.displayName, user?.email),
          style: const TextStyle(
            fontSize: 40,
            color: Colors.white,
          ),
        )
      : null,
),

              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF548CB8), width: 2),
                ),
                child: const Icon(
                  Icons.edit,
                  size: 18,
                  color: Color(0xFF548CB8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user?.displayName ?? user?.email?.split('@')[0] ?? 'Profil',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1e4868),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user?.email ?? '',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection(AuthService authService) {
    final user = authService.currentUser;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations personnelles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1e4868),
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoTile(
              icon: Icons.person,
              title: 'Nom complet',
              value: user?.displayName ?? 'Ajouter un nom',
              onTap:
                  () => _showEditDialog(
                    context,
                    'Nom complet',
                    _nameController,
                    (value) async {
                      await authService.updateDisplayName(value);
                      setState(() {});
                    },
                  ),
            ),
            const Divider(),
            _buildInfoTile(
              icon: Icons.email,
              title: 'Email',
              value: user?.email ?? '',
              onTap:
                  () => _showEditDialog(context, 'Email', _emailController, (
                    value,
                  ) async {
                    await authService.updateEmail(value);
                    setState(() {});
                  }),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cake, color: Color(0xFF548CB8)),
              title: const Text(
                'Date de naissance',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _birthDateController.text.isEmpty
                    ? 'Non définie'
                    : _birthDateController.text,
              ),
              trailing: const Icon(Icons.edit, size: 20),
              onTap: () => _selectBirthDate(context),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.person_outline,
                color: Color(0xFF548CB8),
              ),
              title: const Text(
                'Sexe',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(_selectedGender ?? 'Non défini'),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () => _showGenderPicker(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection(BuildContext context, AuthService authService) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock, color: Color(0xFF548CB8)),
            title: const Text('Changer le mot de passe'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPasswordChangeDialog(context, authService),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              'Supprimer le compte',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _showDeleteAccountDialog(context, authService),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _showLogoutConfirmation(context, authService),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF548CB8)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value),
      trailing: const Icon(Icons.edit, size: 20),
      onTap: onTap,
    );
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      final formattedDate = DateFormat('dd/MM/yyyy').format(picked);
      setState(() {
        _birthDateController.text = formattedDate;
      });
      await Provider.of<AuthService>(
        context,
        listen: false,
      ).updateUserData({'birthDate': formattedDate});
    }
  }

  Future<void> _showGenderPicker(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Sélectionnez votre sexe'),
          children: [
            RadioListTile<String>(
              title: const Text('Masculin'),
              value: 'Masculin',
              groupValue: _selectedGender,
              onChanged: (value) async {
                setState(() {
                  _selectedGender = value;
                });
                await authService.updateUserData({'gender': value});
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Féminin'),
              value: 'Féminin',
              groupValue: _selectedGender,
              onChanged: (value) async {
                setState(() {
                  _selectedGender = value;
                });
                await authService.updateUserData({'gender': value});
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Autre'),
              value: 'Autre',
              groupValue: _selectedGender,
              onChanged: (value) async {
                setState(() {
                  _selectedGender = value;
                });
                await authService.updateUserData({'gender': value});
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    String fieldName,
    TextEditingController controller,
    Future<void> Function(String) onSave,
  ) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modifier $fieldName'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Entrez votre $fieldName'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Le champ $fieldName ne peut pas être vide',
                      ),
                    ),
                  );
                  return;
                }
                try {
                  await onSave(controller.text.trim());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$fieldName mis à jour avec succès'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: ${e.toString()}')),
                  );
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

Future<void> _showPasswordChangeDialog(
  BuildContext context,
  AuthService authService,
) async {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Ancien mot de passe',
                  hintText: 'Entrez votre mot de passe actuel',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  hintText: 'Entrez votre nouveau mot de passe',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le nouveau mot de passe',
                  hintText: 'Confirmez votre nouveau mot de passe',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Les mots de passe ne correspondent pas'),
                  ),
                );
                return;
              }

              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Le mot de passe doit contenir au moins 6 caractères',
                    ),
                  ),
                );
                return;
              }

              try {
                await authService.changePassword(
                  currentPassword: oldPasswordController.text,
                  newPassword: newPasswordController.text,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mot de passe changé avec succès'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      e.toString().contains('wrong-password')
                          ? 'Mot de passe actuel incorrect'
                          : 'Erreur: ${e.toString()}',
                    ),
                  ),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      );
    },
  );
}

  Future<void> _showLogoutConfirmation(
    BuildContext context,
    AuthService authService,
  ) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await authService.signOut();
                Navigator.pushReplacementNamed(context, '/auth');
              },
              child: const Text(
                'Déconnexion',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteAccountDialog(
    BuildContext context,
    AuthService authService,
  ) async {
    final passwordController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le compte'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cette action est irréversible. Toutes vos données seront perdues.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  hintText: 'Entrez votre mot de passe pour confirmer',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final user = authService.currentUser;
                  if (user != null && user.email != null) {
                    final credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: passwordController.text,
                    );
                    await user.reauthenticateWithCredential(credential);
                    await authService.deleteAccount();
                    Navigator.pushReplacementNamed(context, '/auth');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: ${e.toString()}')),
                  );
                }
              },
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final String language;
  final bool notificationsEnabled;
  final Function(String, bool) onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.language,
    required this.notificationsEnabled,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _selectedLanguage;
  late bool _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.language;
    _notificationsEnabled = widget.notificationsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: const Color(0xFFf8fcff),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF548CB8)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Activer les notifications'),
                    value: _notificationsEnabled,
                    onChanged: (value) async {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      await authService.updateUserData({
                        'notificationsEnabled': value,
                      });
                      widget.onSettingsChanged(_selectedLanguage, value);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Langue'),
                    trailing: DropdownButton<String>(
                      value: _selectedLanguage,
                      items: const [
                        DropdownMenuItem(
                          value: 'Français',
                          child: Text('Français'),
                        ),
                        DropdownMenuItem(
                          value: 'English',
                          child: Text('English'),
                        ),
                      ],
                      onChanged: (value) async {
                        if (value != null) {
                          setState(() {
                            _selectedLanguage = value;
                          });
                          await authService.updateUserData({'language': value});
                          widget.onSettingsChanged(
                            value,
                            _notificationsEnabled,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
