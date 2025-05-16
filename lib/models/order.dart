import 'package:app_qstocker/models/cart_item.dart';

class Order {
  final String id;
  final String customerName;
  final String customerPhone;
  final String? customerAddress;
  final String? customerNotes;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime orderDate;
  final String status;
  final String paymentMethod;
  final String userId; // Ajouté

  Order({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    this.customerAddress,
    this.customerNotes,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    this.status = 'pending',
    this.paymentMethod = 'on_delivery',
    required this.userId, // Ajouté
  });
}