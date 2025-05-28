import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final items = cartService.items;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('🛒 Votre Panier', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: items.isEmpty
          ? const Center(child: Text('Votre panier est vide'))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Dismissible(
                        key: Key(item.product.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => cartService.removeFromCart(item.product.id),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: item.product.imageUrl != null
                                      ? _buildImage(item.product.imageUrl!, 60, 60)
                                      : const Icon(Icons.image, size: 60, color: Colors.grey),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text('${item.product.currentPrice.toStringAsFixed(3)} DT x ${item.quantity}'),
                                      Text(
                                        'Total: ${item.totalPrice.toStringAsFixed(3)} DT',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () {
                                        cartService.updateQuantity(item.product.id, item.quantity - 1);
                                      },
                                    ),
                                    Text(item.quantity.toString()),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () {
                                        cartService.updateQuantity(item.product.id, item.quantity + 1);
                                      },
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('${cartService.totalAmount.toStringAsFixed(3)} DT',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CheckoutScreen()),
                            );
                          },
                          icon: const Icon(Icons.payment),
                          label: const Text('Passer la commande'),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }

  Widget _buildImage(String imageUrl, double width, double height) {
    if (imageUrl.startsWith('data:image/')) {
      try {
        final base64Data = imageUrl.split(',').last;
        return Image.memory(
          base64Decode(base64Data),
          width: width,
          height: height,
          fit: BoxFit.cover,
        );
      } catch (e) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.broken_image, size: 30, color: Colors.grey),
          ),
        );
      }
    } else {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.error, size: 30, color: Colors.grey),
            ),
          );
        },
      );
    }
  }
}
