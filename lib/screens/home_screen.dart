import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:app_qstocker/screens/history_screen.dart';
import 'package:app_qstocker/services/product_service.dart';
import 'package:app_qstocker/services/auth_service.dart';
import 'package:app_qstocker/screens/scan_screen.dart';
import 'package:app_qstocker/screens/products_screen.dart';
import 'package:app_qstocker/screens/order_history_screen.dart';
import 'package:app_qstocker/screens/product_detail_screen.dart';
import 'package:app_qstocker/screens/profile_screen.dart';
import '../models/product.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Product>> _promoProductsFuture;
  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    _promoProductsFuture = _loadPromoProducts();
  }

  Future<List<Product>> _loadPromoProducts() async {
    try {
      final allProducts = await _productService.fetchProducts();
      return allProducts.where((product) => product.isOnPromotion).toList();
    } catch (e) {
      print('Error loading promo products: $e');
      return [];
    }
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
          appBar: _buildAppBar(context),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeHeader(user),
                  _buildWelcomeBanner(),
                  _buildFeaturesGrid(context, _productService),
                  _buildPromotionsSection(context),
                  _buildCommitmentsSection(),
                  _buildAboutUsSection(),
                  _buildSocialMediaSection(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          bottomNavigationBar: buildCustomBottomBar(context, 0),
        );
      },
    );
  }

 Widget _buildPromotionsSection(BuildContext context) {
  return FutureBuilder<List<Product>>(
    future: _promoProductsFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
        return _buildDefaultPromoSection();
      }

      final promoProducts = snapshot.data!;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Promotions en cours',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1e4868),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductsScreen(
                        productService: _productService,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Voir plus',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF548CB8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: promoProducts.length,
              itemBuilder: (context, index) {
                final product = promoProducts[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: product),
                      ),
                    );
                  },
                  child: Container(
                    width: 300,
                    margin: const EdgeInsets.only(right: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFC1A36D), width: 1),
                    ),
                    child: Stack(
                      children: [
                        product.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: product.imageUrl!.startsWith('data:image/')
                                    ? Image.memory(
                                        decodeBase64Image(product.imageUrl!),
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.image),
                                        ),
                                      )
                                    : Image.network(
                                        product.imageUrl!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.image),
                                        ),
                                      ),
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.image, size: 50),
                                ),
                              ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.brand,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    '${product.currentPrice.toStringAsFixed(3)} DT',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${product.sellingPrice.toStringAsFixed(3)} DT',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFFC1A36D), Color(0xFF548CB8)],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '-${product.promotion!.discountPercentage}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}

  Widget _buildDefaultPromoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        const Text(
          'Découvrez nos promotions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1e4868),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 300,
                margin: const EdgeInsets.only(right: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: AssetImage('images/promo_${index + 1}.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    [
                      '-30% sur Dior',
                      'Nouveautés exclusives',
                      'Sélection de prestige',
                    ][index],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
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
                  text: 'Parfy',
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
    );
  }

  Widget _buildWelcomeHeader(User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bonjour, ${user?.email?.split('@')[0] ?? 'Cher Client'}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1e4868),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Explorez l\'essence du luxe avec nos créations parfumées.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20, bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC1A36D), Color(0xFFE6C391)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: const [
          Icon(FontAwesomeIcons.sprayCanSparkles, color: Colors.white, size: 30),
          SizedBox(height: 8),
          Text(
            'ÉLÉGANCE • LUXE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Bienvenue chez QParfy',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Laissez votre parfum parler pour vous. Élégance, caractère et séduction en une seule signature.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid(
    BuildContext context,
    ProductService productService,
  ) {
    return GridView.count(
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
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScanScreen()),
          ),
        ),
        _buildFeatureButton(
          context,
          Icons.history,
          'Historique',
          const Color(0xFF1e4868).withOpacity(0.1),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          ),
        ),
        _buildFeatureButton(
          context,
          Icons.store,
          'Boutique',
          const Color(0xFFC1A36D).withOpacity(0.1),
          () {
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
          Icons.receipt_long,
          'Commandes',
          const Color(0xFF6A994E).withOpacity(0.1),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildCommitmentsSection() {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Text(
          'Nos Engagements',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1e4868),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCommitmentItem(Icons.verified, 'Parfums certifiés'),
            _buildCommitmentItem(Icons.local_shipping, 'Expédition en 24h'),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCommitmentItem(Icons.handshake, 'Paiement à la livraison'),
            _buildCommitmentItem(Icons.recycling, 'Packaging responsable'),
          ],
        ),
      ],
    );
  }

  Widget _buildCommitmentItem(IconData icon, String text) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF548CB8).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 30, color: const Color(0xFF1e4868)),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildAboutUsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFf0f7ff),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: Color(0xFFC1A36D), width: 3),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'À Propos de QParfy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1e4868),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'QParfy est une maison spécialisée dans la vente de parfums de grandes marques, 100% originaux. '
            'Notre engagement est d’offrir à chaque client une expérience olfactive authentique, en toute confiance, '
            'grâce à une sélection rigoureuse de fragrances prestigieuses.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSocialMediaSection() {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Text(
          'Suivez-nous',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1e4868),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialIcon(FontAwesomeIcons.facebook, 'https://facebook.com'),
            const SizedBox(width: 20),
            _buildSocialIcon(
              FontAwesomeIcons.instagram,
              'https://instagram.com',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, String url) {
    return InkWell(
      onTap: () => _launchSocialMedia(url),
      child: AnimatedScale(
        scale: 1.1,
        duration: Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF548CB8).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: const Color(0xFF1e4868)),
        ),
      ),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1e4868),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
              const Text('Pour toute assistance, contactez-nous :'),
              const SizedBox(height: 16),
              _buildContactOption(Icons.email, 'contact@qparfy.com', context),
              const SizedBox(height: 8),
              _buildContactOption(Icons.phone, '+216 95 345 678', context),
              const SizedBox(height: 16),
              const Text('Disponible 7j/7 de 8h à 20h'),
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
          onTap: () => _launchContact(text),
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

  void _launchContact(String contact) {
    // Implémentez la logique pour lancer un email/appel
  }

  void _launchSocialMedia(String url) {
    // Implémentez la logique pour ouvrir les réseaux sociaux
  }

  Uint8List decodeBase64Image(String base64String) {
    try {
      // Extraire la partie base64 de la chaîne
      final base64Data = base64String.split(',').last;
      return base64.decode(base64Data);
    } catch (e) {
      // En cas d'erreur, retourner une image vide ou une image par défaut
      // Ici, on retourne une image vide de 1x1 pixel
      return Uint8List.fromList([0x00]); // Retourne une image vide
    }
  }

  Widget buildCustomBottomBar(BuildContext context, int currentIndex) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBottomNavItem(
                  context: context,
                  icon: Icons.home_rounded,
                  label: 'Accueil',
                  isActive: currentIndex == 0,
                  destination: const HomeScreen(),
                  currentIndex: currentIndex,
                  targetIndex: 0,
                ),
                _buildBottomNavItem(
                  context: context,
                  icon: Icons.inventory_2_rounded,
                  label: 'Produits',
                  isActive: currentIndex == 1,
                  destination: ProductsScreen(
                    productService: Provider.of<ProductService>(
                      context,
                      listen: false,
                    ),
                  ),
                  currentIndex: currentIndex,
                  targetIndex: 1,
                ),
                const SizedBox(width: 64), // Espace pour le bouton Scan
                _buildBottomNavItem(
                  context: context,
                  icon: Icons.history_rounded,
                  label: 'Historique',
                  isActive: currentIndex == 2,
                  destination: const HistoryScreen(),
                  currentIndex: currentIndex,
                  targetIndex: 2,
                ),
                _buildBottomNavItem(
                  context: context,
                  icon: Icons.person_rounded,
                  label: 'Profil',
                  isActive: currentIndex == 3,
                  destination: const ProfileScreen(),
                  currentIndex: currentIndex,
                  targetIndex: 3,
                ),
              ],
            ),
          ),
          Positioned(
            top: -10, // abaissé légèrement
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const ScanScreen(),
                      transitionDuration: Duration.zero,
                    ),
                  );
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1e4868), Color(0xFF548cb8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 34,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required Widget destination,
    required int currentIndex,
    required int targetIndex,
  }) {
    return InkWell(
      onTap: () {
        if (currentIndex != targetIndex) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) => destination,
              transitionDuration: Duration.zero,
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      splashColor: const Color(0xFF548cb8).withOpacity(0.1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:
              isActive
                  ? const Color(0xFF548cb8).withOpacity(0.12)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color:
                  isActive
                      ? const Color(0xFF1e4868)
                      : const Color(0xFF548CB8).withOpacity(0.6),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color:
                    isActive
                        ? const Color(0xFF1e4868)
                        : const Color(0xFF548CB8).withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
