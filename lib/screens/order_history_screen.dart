import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart';
import '../services/order_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<List<Order>> _ordersFuture;
  final OrderService _orderService = OrderService(
    baseUrl: 'https://qstocker-9b450-default-rtdb.firebaseio.com',
  );
  late StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    _ordersFuture = Future.value([]); // Initialize with an empty list
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        print("✅ Utilisateur connecté: ${user.uid}");
        setState(() {
          _ordersFuture = _loadOrders(user.uid);
        });
      } else {
        print("⚠️ Aucun utilisateur connecté");
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<List<Order>> _loadOrders(String userId) async {
    try {
      print("✅ Chargement des commandes pour userId: $userId");
      final orders = await _orderService.fetchUserOrders(userId);

      if (orders.isEmpty) {
        print("ℹ️ Aucune commande trouvée pour cet utilisateur");
      } else {
        print("✅ ${orders.length} commandes chargées avec succès");
      }

      return orders;
    } catch (e) {
      print("❌ Erreur critique lors du chargement des commandes: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de chargement des commandes: ${e.toString()}")),
      );
      return [];
    }
  }

  Future<void> _refreshOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _ordersFuture = _loadOrders(user.uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des commandes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrders,
          ),
        ],
      ),
      body: _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 50, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Vous devez être connecté pour voir vos commandes'),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<Order>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 50, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Impossible de charger les commandes',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshOrders,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, size: 50, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Aucune commande trouvée'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _refreshOrders,
                  child: const Text('Actualiser'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshOrders,
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: orders.length,
            itemBuilder: (context, index) => _buildOrderCard(context, orders[index]),
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Icon(
          _getStatusIcon(order.status),
          color: _getStatusColor(order.status),
        ),
        title: Text(
          'Commande #${order.id.substring(0, 8)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatDate(order.orderDate)} - ${order.totalAmount.toStringAsFixed(3)} DT',
            ),
            const SizedBox(height: 4),
            Text(
              '${order.items.length} article(s)',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Statut', _getStatusText(order.status)),
                _buildInfoRow('Date', _formatDateTime(order.orderDate)),
                _buildInfoRow('Méthode de paiement', _getPaymentMethodText(order.paymentMethod)),
                _buildInfoRow('Client', order.customerName),
                _buildInfoRow('Téléphone', order.customerPhone),
                if (order.customerAddress?.isNotEmpty ?? false)
                  _buildInfoRow('Adresse', order.customerAddress!),
                if (order.customerNotes?.isNotEmpty ?? false)
                  _buildInfoRow('Notes', order.customerNotes!),

                const SizedBox(height: 16),
                const Text(
                  'Articles commandés:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Divider(),
                ...order.items.map((item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: item.product.imageUrl != null
                      ? Image.network(
                          item.product.imageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image, size: 50),
                        )
                      : const Icon(Icons.image, size: 50),
                  title: Text(item.product.name),
                  subtitle: Text('${item.quantity} x ${item.product.currentPrice.toStringAsFixed(3)} DT'),
                  trailing: Text(
                    '${item.totalPrice.toStringAsFixed(3)} DT',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                )),

                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${order.totalAmount.toStringAsFixed(3)} DT',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'processing':
        return 'En cours de traitement';
      case 'shipped':
        return 'Expédiée';
      case 'delivered':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'processing':
        return Icons.sync;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }

  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'on_delivery':
        return 'Paiement à la livraison';
      case 'credit_card':
        return 'Carte bancaire';
      case 'mobile_money':
        return 'Mobile Money';
      default:
        return method;
    }
  }
}
