import 'package:app_qstocker/screens/history_screen.dart';
import 'package:app_qstocker/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'scan_screen.dart';
import 'products_screen.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Aide & Support',
            style: TextStyle(color: Color(0xFF1e4868)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pour toute assistance, veuillez contacter notre équipe :'),
              const SizedBox(height: 16),
              _buildContactOption(Icons.email, 'contact.qstocker@.com', context),
              const SizedBox(height: 8),
              _buildContactOption(Icons.phone, '+216 123 654 987', context),
              const SizedBox(height: 16),
              const Text('Lundi - Vendredi : 9h - 18h'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Fermer',
                style: TextStyle(color: Color(0xFF548CB8)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContactOption(IconData icon, String text, BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF548CB8)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            // Action pour copier le texte ou ouvrir l'application correspondante
          },
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF1e4868),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Scaffold(
          backgroundColor: const Color(0xFFf8fcff),
          appBar: AppBar(
            title: Row(
              children: [
                Image.asset('images/qstocker.png', height: 30),
                const SizedBox(width: 8),
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Q',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1e4868),
                        ),
                      ),
                      TextSpan(
                        text: 'trace',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF548cb8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFf8fcff),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.help_outline,
                  size: 28,
                  color: Color(0xFF548CB8),
                ),
                onPressed: () => _showHelpDialog(context),
              ),
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  size: 28,
                  color: Color(0xFF548CB8),
                ),
                onPressed: () {},
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Bonjour, ${user?.email?.split('@')[0] ?? 'Utilisateur'}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1e4868),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Message de bienvenue élégant
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10, bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFC1A36D),
                          Color(0xFFE8D9B5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Bienvenue sur Qtrace ! Plongez dans l\'univers des parfums authentiques et raffinés.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1e4868),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Grid de fonctionnalités
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 1.1,
                    children: [
                      _buildFeatureButton(
                        context,
                        Icons.qr_code_scanner,
                        'Scanner un produit',
                        const Color(0xFF548CB8).withOpacity(0.1),
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen())),
                      ),
                      _buildFeatureButton(
                        context,
                        Icons.history,
                        'Historique des produits',
                        const Color(0xFF1e4868).withOpacity(0.1),
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                      ),
                     _buildFeatureButton(
  context,
  Icons.visibility,
  'Visualiser les produits',
  const Color(0xFF548CB8).withOpacity(0.1),
  () {
    final productService = Provider.of<ProductService>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductsScreen(productService: productService),
      ),
    );
  },
),
                      _buildFeatureButton(
                        context,
                        Icons.verified_user,
                        'Authentification',
                        const Color(0xFF1e4868).withOpacity(0.1),
                        () {}, // TODO: Naviguer vers l'authentification
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Section Promotions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Promotions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1e4868)),
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                        ),
                        child: const Text(
                          'Voir tout',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF548CB8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: AssetImage('images/promotions_banner.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Espace supplémentaire en bas
                ],
              ),
            ),
          ),
          bottomNavigationBar: buildCustomBottomBar(context, 0),
        );
      },
    );
  }

  Widget _buildFeatureButton(
    BuildContext context,
    IconData icon,
    String text,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: const Color(0xFF1e4868)),
              const SizedBox(height: 10),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1e4868).withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
