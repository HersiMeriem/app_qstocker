import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/cart_service.dart';
import '../widgets/product_card.dart';
import '../widgets/category_filter.dart';
import 'cart_screen.dart';
import '../widgets/search_app_bar.dart';
import 'order_history_screen.dart';
import 'home_screen.dart';
import 'scan_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class ProductsScreen extends StatefulWidget {
  final ProductService productService;

  const ProductsScreen({super.key, required this.productService});

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late Future<List<Product>> _productsFuture;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _selectedCategory = 'Tous';
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      _productsFuture = widget.productService.fetchProducts();
      final products = await _productsFuture;
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesCategory = _selectedCategory == 'Tous' ||
            product.category == _selectedCategory;
        final matchesSearch = _searchQuery.isEmpty ||
            product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (product.olfactiveFamily?.toLowerCase() ?? '').contains(_searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _filterProducts();
    });
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _filterProducts();
    });
  }

  Future<void> _refreshProducts() async {
    await _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final categories = ['Tous', ..._products.map((p) => p.category).toSet()];

    return Scaffold(
      appBar: SearchAppBar(
        title: 'Nos Produits',
        onSearch: _onSearch,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
              );
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              ),
              if (cartService.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.red,
                    child: Text(
                      cartService.itemCount.toString(),
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: Column(
          children: [
            if (categories.length > 1)
              CategoryFilter(
                categories: categories,
                selectedCategory: _selectedCategory,
                onCategorySelected: _onCategorySelected,
              ),
            Expanded(
              child: _isLoading
                  ? _buildShimmerLoader()
                  : _filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off, size: 50, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Aucun produit disponible'
                                    : 'Aucun résultat pour "$_searchQuery"',
                                style: const TextStyle(fontSize: 16),
                              ),
                              if (_searchQuery.isNotEmpty)
                                TextButton(
                                  onPressed: () => _onSearch(''),
                                  child: const Text('Réinitialiser la recherche'),
                                ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(8.0),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return ProductCard(
                              product: product,
                              onAddToCart: () {
                                cartService.addToCart(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product.name} ajouté au panier'),
                                    action: SnackBarAction(
                                      label: 'Voir',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const CartScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: buildCustomBottomBar(context, 1), // Ajoutez la barre de navigation ici
    );
  }

  Widget _buildShimmerLoader() {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 12,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 80,
                      height: 14,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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
                destination: HomeScreen(),
                currentIndex: currentIndex,
                targetIndex: 0,
              ),
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
