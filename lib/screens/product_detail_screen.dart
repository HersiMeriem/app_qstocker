import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../screens/cart_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: 'product-image-${product.id}',
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      height: 300,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 300,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 300,
                        color: Colors.grey[200],
                        child: const Icon(Icons.error),
                      ),
                    )
                  : Container(
                      height: 300,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 100, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                      if (product.status == 'out-of-stock')
                        Chip(
                          label: const Text('Rupture de stock'),
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
                  _buildInfoRow(Icons.category, 'Catégorie', product.category),
                  if (product.olfactiveFamily?.isNotEmpty ?? false)
                    _buildInfoRow(Icons.local_florist, 'Famille olfactive', product.olfactiveFamily!),
                  _buildInfoRow(Icons.style, 'Type de parfum', product.perfumeType),
                  _buildInfoRow(Icons.public, 'Origine', product.origin),
                  _buildInfoRow(Icons.straighten, 'Volume', product.volume),
                  const SizedBox(height: 24),
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description ?? 'Aucune description disponible',
                    style: const TextStyle(fontSize: 15),
                  ),
                  if (product.promotion != null && product.status == 'promotion')
                    _buildPromotionSection(context),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: product.status != 'out-of-stock'
                ? () {
                    cartService.addToCart(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} ajouté au panier'),
                        action: SnackBarAction(
                          label: 'Voir',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CartScreen()),
                            );
                          },
                        ),
                      ),
                    );
                  }
                : null,
            child: const Text('Ajouter au panier'),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceSection(BuildContext context) {
    return Row(
      children: [
        if (product.status == 'promotion' && product.promotion != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '-${product.promotion!.discountPercentage}%',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        const SizedBox(width: 12),
        Text(
          '${product.currentPrice.toStringAsFixed(3)} DT',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
            decoration: product.status == 'promotion'
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        if (product.status == 'promotion')
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              '${product.unitPrice.toStringAsFixed(3)} DT',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildPromotionSection(BuildContext context) {
    final promotion = product.promotion!;
    final now = DateTime.now();
    final startDate = DateTime.parse(promotion.startDate);
    final endDate = DateTime.parse(promotion.endDate);
    final isActive = now.isAfter(startDate) && now.isBefore(endDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Détails de la promotion:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        _buildPromotionDetailRow('Remise', '${promotion.discountPercentage}%'),
        _buildPromotionDetailRow('Prix original', '${product.unitPrice.toStringAsFixed(3)} DT'),
        _buildPromotionDetailRow('Prix promotionnel', '${product.currentPrice.toStringAsFixed(3)} DT'),
        _buildPromotionDetailRow('Début', _formatDate(startDate)),
        _buildPromotionDetailRow('Fin', _formatDate(endDate)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
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
              const SizedBox(width: 8),
              Text(
                isActive
                    ? 'Promotion active'
                    : 'Promotion expirée',
                style: TextStyle(
                  color: isActive ? Colors.green : Colors.orange,
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
