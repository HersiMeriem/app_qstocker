import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import 'order_confirmation_screen.dart';
import '../models/cart_item.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _orderError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _orderError = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Vous devez être connecté pour passer une commande');
      }

      final cartService = Provider.of<CartService>(context, listen: false);
      final orderService = OrderService(
        baseUrl: 'https://qstocker-9b450-default-rtdb.firebaseio.com',
      );

      final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
      
      final order = Order(
        id: orderId,
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        customerAddress: _addressController.text.trim(),
        customerNotes: _notesController.text.trim(),
        items: List<CartItem>.from(cartService.items), // Copie de la liste
        totalAmount: cartService.totalAmount,
        orderDate: DateTime.now(),
        paymentMethod: 'on_delivery',
        userId: user.uid,
      );

      final confirmedOrder = await showDialog<Order>(
        context: context,
        builder: (context) => _buildOrderConfirmationDialog(context, order),
      );

      if (confirmedOrder != null) {
        await orderService.placeOrder(confirmedOrder);
        
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(orderId: orderId),
          ),
        );
        
        cartService.clearCart();
      }
    } catch (e) {
      setState(() {
        _orderError = 'Erreur lors de la commande: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_orderError!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildOrderConfirmationDialog(BuildContext context, Order order) {
    return AlertDialog(
      title: const Text('Confirmer la commande'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Voulez-vous finaliser cette commande ?'),
            const SizedBox(height: 16),
            Text('Nom: ${order.customerName}'),
            Text('Téléphone: ${order.customerPhone}'),
            if (order.customerAddress?.isNotEmpty ?? false)
              Text('Adresse: ${order.customerAddress}'),
            const SizedBox(height: 16),
            const Text('Articles:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...order.items.map((item) => 
              Text('- ${item.product.name} (x${item.quantity})')
            ),
            const SizedBox(height: 16),
            Text(
              'Total: ${order.totalAmount.toStringAsFixed(3)} DT',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, order),
          child: const Text('Confirmer'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finaliser la commande'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Informations client
              _buildSectionTitle('Informations client'),
              _buildTextFormField(
                controller: _nameController,
                label: 'Nom complet',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre nom';
                  }
                  return null;
                },
              ),
              _buildTextFormField(
                controller: _phoneController,
                label: 'Numéro de téléphone',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un numéro';
                  }
                  if (!RegExp(r'^[0-9]{8,15}$').hasMatch(value)) {
                    return 'Numéro invalide';
                  }
                  return null;
                },
              ),
              _buildTextFormField(
                controller: _addressController,
                label: 'Adresse de livraison (optionnel)',
                icon: Icons.location_on,
              ),
              _buildTextFormField(
                controller: _notesController,
                label: 'Notes supplémentaires (optionnel)',
                icon: Icons.note,
                maxLines: 3,
              ),

              // Section Récapitulatif
              _buildSectionTitle('Récapitulatif de la commande'),
              _buildOrderItemsList(cartService),

              // Section Total
              _buildTotalCard(cartService.totalAmount),

              // Section Paiement
              _buildSectionTitle('Méthode de paiement'),
              _buildPaymentMethodCard(),

              // Bouton de confirmation
              const SizedBox(height: 32),
              _buildSubmitButton(),

              // Affichage des erreurs
              if (_orderError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _orderError!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

Widget _buildTextFormField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType? keyboardType,
  String? Function(String?)? validator,
  int maxLines = 1,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ), 
      ), 
    ), 
  ); 
}

  Widget _buildOrderItemsList(CartService cartService) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cartService.items.length,
      itemBuilder: (context, index) {
        final item = cartService.items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: _buildProductImage(item.product.imageUrl),
            title: Text(item.product.name),
            subtitle: Text('${item.quantity} x ${item.product.currentPrice.toStringAsFixed(3)} DT'),
            trailing: Text('${item.totalPrice.toStringAsFixed(3)} DT'),
          ),
        );
      },
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    if (imageUrl == null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }

    if (imageUrl.startsWith('data:image/')) {
      try {
        final base64Data = imageUrl.split(',').last;
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            base64Decode(base64Data),
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        );
      } catch (e) {
        return _buildErrorImage();
      }
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 40,
              height: 40,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildErrorImage() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  Widget _buildTotalCard(double totalAmount) {
    return Column(
      children: [
        const Divider(),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${totalAmount.toStringAsFixed(3)} DT',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: const ListTile(
        leading: Icon(Icons.money),
        title: Text('Paiement à la livraison'),
        subtitle: Text('Vous payez lorsque vous recevez la commande'),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isSubmitting ? null : () => _submitOrder(context),
        child: _isSubmitting
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.white),
              )
            : const Text('Confirmer la commande'),
      ),
    );
  }
}