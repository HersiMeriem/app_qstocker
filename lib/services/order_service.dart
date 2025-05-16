import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart';
import '../models/cart_item.dart';

class OrderService {
  static const String _basePath = 'orders.json';
  final String baseUrl;

  OrderService({required this.baseUrl});

  Future<String> placeOrder(Order order) async {
    try {
      // Vérification de l'authentification
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non authentifié');
      }

      // Récupération du token d'authentification
      final token = await user.getIdToken();

      // Construction de l'URL avec authentification
      final url = Uri.parse('$baseUrl/$_basePath?auth=$token');

      // Préparation des données de la commande
      final orderData = _prepareOrderData(order, user.uid);

      // Envoi de la requête
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderData),
      );

      // Gestion de la réponse
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Échec de la commande: ${e.toString()}');
    }
  }

  Map<String, dynamic> _prepareOrderData(Order order, String userId) {
    return {
      'id': order.id,
      'customerName': order.customerName,
      'customerPhone': order.customerPhone,
      'customerAddress': order.customerAddress ?? '',
      'customerNotes': order.customerNotes ?? '',
      'userId': userId,
      'items': _prepareOrderItems(order.items),
      'totalAmount': order.totalAmount,
      'orderDate': DateTime.now().toIso8601String(),
      'status': 'pending',
      'paymentMethod': order.paymentMethod,
    };
  }

  List<Map<String, dynamic>> _prepareOrderItems(List<CartItem> items) {
    return items
        .map(
          (item) => {
            'productId': item.product.id,
            'productName': item.product.name,
            'quantity': item.quantity,
            'unitPrice': item.product.currentPrice,
            'totalPrice': item.totalPrice,
            'productImage': item.product.imageUrl ?? '',
          },
        )
        .toList();
  }

  String _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(response.body);
      return responseData['name']; // Retourne l'ID généré par Firebase
    } else {
      throw Exception(
        'Erreur serveur (${response.statusCode}): ${response.reasonPhrase}',
      );
    }
  }

  // Méthode optionnelle pour valider les données avant envoi
  static void validateOrder(Order order) {
    if (order.customerName.isEmpty) {
      throw Exception('Le nom du client est requis');
    }
    if (order.customerPhone.isEmpty) {
      throw Exception('Le téléphone du client est requis');
    }
    if (order.items.isEmpty) {
      throw Exception('Le panier est vide');
    }
    if (order.totalAmount <= 0) {
      throw Exception('Montant total invalide');
    }
  }
}
