import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/order.dart';

class OrderService {
  final DatabaseReference _ordersRef;

  OrderService({required String baseUrl})
      : _ordersRef = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: baseUrl).ref('orders');

  Stream<List<Order>> getOrdersStream(String userId) {
    return _ordersRef
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      return data.entries.map((entry) {
        return Order.fromJson({
          'id': entry.key,
          ...Map<String, dynamic>.from(entry.value),
        });
      }).toList()
        ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
    });
  }

  Future<void> placeOrder(Order order) async {
    try {
      await _ordersRef.push().set(order.toJson());
    } catch (e) {
      if (kDebugMode) {
        print('Error placing order: $e');
      }
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _ordersRef.child(orderId).update({
        'status': newStatus,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating order status: $e');
      }
      rethrow;
    }
  }

  Future<List<Order>> fetchUserOrders(String userId) async {
    try {
      final snapshot = await _ordersRef.orderByChild('userId').equalTo(userId).once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) return [];

      return data.entries.map((entry) {
        return Order.fromJson({
          'id': entry.key,
          ...Map<String, dynamic>.from(entry.value),
        });
      }).toList()
        ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user orders: $e');
      }
      rethrow;
    }
  }
}
