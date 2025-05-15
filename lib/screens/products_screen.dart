import 'package:flutter/material.dart';
import 'dart:convert'; // For base64 decoding
import 'dart:typed_data'; // For Uint8List
import '../models/product_model.dart';
import '../services/product_service.dart';
import 'product_detail_screen.dart';
import 'custom_bottom_bar.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _productService = ProductService();
  late Future<List<Product>> _productsFuture;
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _productsFuture = _productService.getAllProducts();
    _productsFuture.then((products) {
      setState(() {
        _filteredProducts = products;
      });
    });
  }

  void _refreshProducts() {
    setState(() {
      _productsFuture = _productService.getAllProducts();
      _productsFuture.then((products) {
        setState(() {
          _filteredProducts = products;
        });
      });
    });
  }

  void _filterProducts(String query) {
    _productsFuture.then((products) {
      setState(() {
        _filteredProducts = products.where((product) {
          final nameLower = product.name.toLowerCase();
          final typeLower = product.type.toLowerCase();
          final searchLower = query.toLowerCase();
          return nameLower.contains(searchLower) ||
                 typeLower.contains(searchLower);
        }).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nos Produits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Rechercher',
                hintText: 'Rechercher par nom ou type',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: _filterProducts,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Aucun produit disponible'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return _buildProductCard(product, context);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: buildCustomBottomBar(context, 1),
    );
  }

  Widget _buildProductCard(Product product, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: product.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Image du produit
              if (product.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImageFromBase64(product.imageUrl!),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image),
                ),

              const SizedBox(width: 16),

              // Détails du produit
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    if (product.status == 'promotion' && product.promotion != null)
                      Text(
                        'Promotion: -${product.promotion!.discountPercentage}%',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageFromBase64(String base64String) {
    // Remove the data URI prefix if present
    final base64Data = base64String.split(',').last;
    final bytes = base64.decode(base64Data);
    return Image.memory(
      Uint8List.fromList(bytes),
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.error);
      },
    );
  }
}
