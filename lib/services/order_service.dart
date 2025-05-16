import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/order.dart';

class OrderService {
  final String baseUrl;

  OrderService({required this.baseUrl});

  Future<void> placeOrder(Order order) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customerName': order.customerName,
          'customerPhone': order.customerPhone,
          'customerAddress': order.customerAddress,
          'customerNotes': order.customerNotes,
          'items': order.items.map((item) => {
            'productId': item.product.id,
            'quantity': item.quantity,
            'unitPrice': item.product.currentPrice,
          }).toList(),
          'totalAmount': order.totalAmount,
          'paymentMethod': order.paymentMethod,
        }),
      );
      
      if (response.statusCode != 201) {
        throw Exception('Failed to place order');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
}