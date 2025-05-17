import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart';

class OrderService {
  final String baseUrl;

  OrderService({required this.baseUrl});

  Future<String> placeOrder(Order order) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non authentifié');

      final token = await user.getIdToken();
      final url = Uri.parse('$baseUrl/orders.json?auth=$token');

      print("📡 Envoi de la commande à Firebase...");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(order.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("✅ Commande enregistrée avec ID: ${responseData['name']}");
        return responseData['name'];
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Échec de la commande: ${e.toString()}");
      throw Exception('Échec de la commande: ${e.toString()}');
    }
  }

  Future<List<Order>> fetchUserOrders(String userId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non authentifié');

      final token = await user.getIdToken();
      final url = Uri.parse('$baseUrl/orders.json?orderBy="userId"&equalTo="$userId"&auth=$token');
      print("📡 Appel URL: $url");

      final response = await http.get(url);
      print("📥 Réponse Firebase: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic>? data = json.decode(response.body);
        if (data == null || data.isEmpty) {
          print("⚠️ Aucune commande trouvée pour cet utilisateur.");
          return [];
        }

        final orders = data.entries.map((entry) {
          return Order.fromJson({...entry.value, 'id': entry.key});
        }).toList()
          ..sort((a, b) => b.orderDate.compareTo(a.orderDate));

        print("✅ ${orders.length} commandes récupérées pour l'utilisateur $userId");
        return orders;
      } else {
        throw Exception('Erreur serveur: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("❌ Échec de récupération des commandes: ${e.toString()}");
      throw Exception('Échec de récupération des commandes: ${e.toString()}');
    }
  }
}
