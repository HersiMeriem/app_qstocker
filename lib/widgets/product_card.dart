import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../screens/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Carte du produit ${product.name}',
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(product: product),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                      child: Hero(
                        tag: 'product-image-${product.id}',
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.grey[300]!, width: 1),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                          ),
                          child: product.imageUrl != null
                              ? _buildImage(product.imageUrl!)
                              : Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.image,
                                        size: 50, color: Colors.grey),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.brand,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        _buildPriceSection(context),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            key: const Key('addToCartButton'),
                            onPressed: product.isAvailable
                                ? onAddToCart
                                : null,
                            icon: const Icon(Icons.add_shopping_cart,
                                size: 18),
                            label: const Text('Ajouter'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!product.isAvailable)
              const Positioned(
                top: 8,
                right: 8,
                child: _StockStatusBadge(
                  text: 'RUPTURE',
                  color: Colors.red,
                ),
              ),
            if (product.isOnPromotion)
              Positioned(
                top: 8,
                left: 8,
                child: _StockStatusBadge(
                  text:
                      '-${product.promotion!.discountPercentage}%',
                  color: Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.isOnPromotion)
          Text(
            '${product.sellingPrice.toStringAsFixed(3)} DT',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        Text(
          '${product.currentPrice.toStringAsFixed(3)} DT',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: product.isOnPromotion
                ? Colors.red
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('data:image/')) {
      try {
        final base64Data = imageUrl.split(',').last;
        return Image.memory(
          base64Decode(base64Data),
          fit: BoxFit.cover,
        );
      } catch (e) {
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.broken_image,
                size: 50, color: Colors.grey),
          ),
        );
      }
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.image, size: 50, color: Colors.grey),
          ),
        ),
      );
    }
  }
}

class _StockStatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StockStatusBadge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
