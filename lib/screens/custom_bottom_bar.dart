import 'package:app_qstocker/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'scan_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'products_screen.dart';

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
                destination: HomeScreen(),
                currentIndex: currentIndex,
                targetIndex: 0,
              ),
             // Update the ProductsScreen navigation to include required parameter
_buildBottomNavItem(
  context: context,
  icon: Icons.inventory_2_rounded,
  label: 'Produits',
  isActive: currentIndex == 1,
  destination: ProductsScreen(productService: Provider.of<ProductService>(context, listen: false)),
  currentIndex: currentIndex,
  targetIndex: 1,
),
              const SizedBox(width: 64), // Espace pour le bouton Scan
              _buildBottomNavItem(
                context: context,
                icon: Icons.history_rounded,
                label: 'Historique',
                isActive: currentIndex == 2,
                destination: HistoryScreen(),
                currentIndex: currentIndex,
                targetIndex: 2,
              ),
              _buildBottomNavItem(
                context: context,
                icon: Icons.person_rounded,
                label: 'Profil',
                isActive: currentIndex == 3,
                destination: ProfileScreen(),
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
                    pageBuilder: (_, __, ___) => ScanScreen(),
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
        color: isActive ? const Color(0xFF548cb8).withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive
                ? const Color(0xFF1e4868)
                : const Color(0xFF548cb8).withOpacity(0.6),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: isActive
                  ? const Color(0xFF1e4868)
                  : const Color(0xFF548cb8).withOpacity(0.6),
            ),
          ),
        ],
      ),
    ),
  );
}
