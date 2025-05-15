import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import 'dart:convert'; // For base64 decoding
import 'dart:typed_data'; // For Uint8List

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<Product?> _productFuture;
  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    _productFuture = _productService.getProductById(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du produit'),
      ),
      body: FutureBuilder<Product?>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Produit non trouvé'));
          }

          final product = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image du produit
                if (product.imageUrl != null)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildImageFromBase64(product.imageUrl!),
                    ),
                  )
                else
                  Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.image, size: 50),
                  ),

                const SizedBox(height: 24),

                // Nom et catégorie
                Center(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    product.category,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Authenticité
                if (product.isAuthentic != null)
                  ListTile(
                    leading: Icon(
                      product.isAuthentic! ? Icons.verified : Icons.warning,
                      color: product.isAuthentic! ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      product.isAuthentic! ? 'Produit authentique' : 'Produit contrefait',
                      style: TextStyle(
                        color: product.isAuthentic! ? Colors.green : Colors.red,
                      ),
                    ),
                  ),

                // Description
                const SizedBox(height: 16),
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(product.description),

                // Promotion
                if (product.status == 'promotion' && product.promotion != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Promotion:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('-${product.promotion!.discountPercentage}% de réduction'),
                      Text('Du ${_formatDate(product.promotion!.startDate)} au ${_formatDate(product.promotion!.endDate)}'),
                    ],
                  ),

                // QR Code
                const SizedBox(height: 16),
                const Text(
                  'QR Code:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Center(
                  child: _buildQrCodeImage(product.qrCode),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageFromBase64(String base64String) {
    // Remove the data URI prefix if present
    final base64Data = base64String.split(',').last;
    final bytes = base64.decode(base64Data);
    return Image.memory(
      Uint8List.fromList(bytes),
      height: 200,
      width: 200,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.error);
      },
    );
  }

  Widget _buildQrCodeImage(String qrCodeData) {
    try {
      // Remove the data URI prefix if present
      final base64Data = qrCodeData.split(',').last;
      final bytes = base64.decode(base64Data);
      return Image.memory(
        Uint8List.fromList(bytes),
        height: 200,
        width: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Text('Invalid QR Code Data');
        },
      );
    } catch (e) {
      return const Text('Invalid QR Code Data');
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}
