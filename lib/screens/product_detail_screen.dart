import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/cart_service.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product image with hero animation
            Hero(
              tag: 'product-image-${product.id}',
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: product.imageUrl != null
                    ? _buildImage(product.imageUrl!)
                    : Container(
                        height: 300,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 100, color: Colors.grey),
                      ),
              ),
            ),

            // Product details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and add to cart button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (product.isAvailable)
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.primaryColor,
                            ),
                            child: const Icon(Icons.add_shopping_cart, color: Colors.white),
                          ),
                          onPressed: () {
                            cartService.addToCart(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} ajouté au panier'),
                                action: SnackBarAction(
                                  label: 'Voir',
                                  onPressed: () => Navigator.pushNamed(context, '/cart'),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Brand and price
                  if (product.brand.isNotEmpty)
                    Text(
                      product.brand,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: 16),

                  _buildPriceSection(context),
                  const SizedBox(height: 16),

                  // Product tags/chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (product.category.isNotEmpty)
                        Chip(
                          label: Text(product.category),
                          backgroundColor: theme.primaryColor.withOpacity(0.1),
                        ),
                      if (product.olfactiveFamily?.isNotEmpty ?? false)
                        Chip(
                          label: Text(product.olfactiveFamily!),
                          backgroundColor: Colors.green[50],
                        ),
                      if (product.perfumeType.isNotEmpty)
                        Chip(
                          label: Text(product.perfumeType),
                          backgroundColor: Colors.purple[50],
                        ),
                      if (!product.isAvailable)
                        Chip(
                          label: const Text('Rupture'),
                          backgroundColor: Colors.red[50],
                          labelStyle: const TextStyle(color: Colors.red),
                        ),
                      if (product.isAuthentic != null)
                        Chip(
                          label: Text(product.isAuthentic! ? 'Authentique' : 'Contrefaçon'),
                          backgroundColor: product.isAuthentic!
                              ? Colors.green[50]
                              : Colors.red[50],
                          labelStyle: TextStyle(
                            color: product.isAuthentic!
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Product details
                  _buildInfoRow(Icons.category, 'Catégorie', product.category),
                  if (product.olfactiveFamily?.isNotEmpty ?? false)
                    _buildInfoRow(Icons.local_florist, 'Famille olfactive', product.olfactiveFamily!),
                  _buildInfoRow(Icons.style, 'Type de parfum', product.perfumeType),
                  _buildInfoRow(Icons.public, 'Origine', product.origin),
                  _buildInfoRow(Icons.straighten, 'Volume', product.volume),
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description ?? 'Aucune description disponible',
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),

                  // Promotion details if applicable
                  if (product.isOnPromotion)
                    _buildPromotionSection(context),
                ],
              ),
            ),
          ],
        ),
      ),

      // Fixed add to cart button at bottom
      bottomNavigationBar: product.isAvailable
          ? Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () {
                  cartService.addToCart(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} ajouté au panier'),
                      action: SnackBarAction(
                        label: 'Voir',
                        onPressed: () => Navigator.pushNamed(context, '/cart'),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Ajouter au panier'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('data:image/')) {
      try {
        final base64Data = imageUrl.split(',').last;
        return Image.memory(
          base64Decode(base64Data),
          height: 300,
          fit: BoxFit.cover,
        );
      } catch (e) {
        return Container(
          height: 300,
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
          ),
        );
      }
    } else {
      return Image.network(
        imageUrl,
        height: 300,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 300,
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.error, size: 50, color: Colors.grey),
            ),
          );
        },
      );
    }
  }

  Widget _buildPriceSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (product.isOnPromotion)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
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
            const SizedBox(width: 12),
            Text(
              '${product.currentPrice.toStringAsFixed(3)} DT',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: product.isOnPromotion
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        if (product.isOnPromotion)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Au lieu de ${product.sellingPrice.toStringAsFixed(3)} DT',
              style: TextStyle(
                color: Colors.grey,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionSection(BuildContext context) {
    final promotion = product.promotion!;
    final isActive = product.isOnPromotion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Détails de la promotion',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              _buildPromotionDetailRow('Remise', '${promotion.discountPercentage}%'),
              _buildPromotionDetailRow('Prix original', '${product.sellingPrice.toStringAsFixed(3)} DT'),
              _buildPromotionDetailRow('Prix promotionnel', '${product.currentPrice.toStringAsFixed(3)} DT'),
              _buildPromotionDetailRow('Début', _formatDate(DateTime.parse(promotion.startDate))),
              _buildPromotionDetailRow('Fin', _formatDate(DateTime.parse(promotion.endDate))),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isActive ? Icons.timer : Icons.timer_off,
                      color: isActive ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isActive ? 'Promotion active' : 'Promotion expirée',
                      style: TextStyle(
                        color: isActive ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
