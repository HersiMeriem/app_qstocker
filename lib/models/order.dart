import 'package:app_qstocker/models/cart_item.dart';
import 'package:app_qstocker/models/product.dart';

class Order {
  final String id;
  final String customerName;
  final String customerPhone;
  final String? customerAddress;
  final String? customerNotes;
  final List<CartItem> items;
  final double totalAmount;
  final double shippingFee;
  final double grandTotal;
  final DateTime orderDate;
  String status;
  final String paymentMethod;
  final String userId;

  Order({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    this.customerAddress,
    this.customerNotes,
    required this.items,
    required this.totalAmount,
    required this.shippingFee,
    required this.grandTotal,
    required this.orderDate,
    this.status = 'pending',
    this.paymentMethod = 'on_delivery',
    required this.userId,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      customerAddress: json['customerAddress'],
      customerNotes: json['customerNotes'],
      items: (json['items'] as List<dynamic>?)?.map((item) {
        return CartItem(
          product: Product(
            id: item['productId'] ?? '',
            name: item['productName'] ?? '',
            imageUrl: item['productImage'],
            unitPrice: (item['unitPrice'] ?? 0).toDouble(),
            brand: item['brand'] ?? '',
            category: item['category'] ?? '',
            volume: item['volume'] ?? '',
            costPrice: (item['costPrice'] ?? 0).toDouble(),
            origin: item['origin'] ?? '',
            status: item['status'] ?? 'active',
            perfumeType: item['perfumeType'] ?? '',
            qrCode: item['qrCode'],
            description: item['description'],
            olfactiveFamily: item['olfactiveFamily'],
            promotion: item['promotion'] != null
                ? Promotion.fromJson(item['promotion'])
                : null,
            isAuthentic: item['isAuthentic'],
            createdAt: item['createdAt'] != null
                ? DateTime.parse(item['createdAt'])
                : null,
            updatedAt: item['updatedAt'] != null
                ? DateTime.parse(item['updatedAt'])
                : null,
            stock: item['stock'] ?? 0,
            sellingPrice: (item['sellingPrice'] ?? 0).toDouble(),
          ),
          quantity: item['quantity'] ?? 1,
        );
      }).toList() ?? [],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      shippingFee: (json['shippingFee'] ?? 0).toDouble(),
      grandTotal: (json['grandTotal'] ?? 0).toDouble(),
      orderDate: DateTime.parse(json['orderDate']),
      status: json['status'] ?? 'pending',
      paymentMethod: json['paymentMethod'] ?? 'on_delivery',
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'customerNotes': customerNotes,
      'items': items.map((item) => {
        'productId': item.product.id,
        'productName': item.product.name,
        'quantity': item.quantity,
        'unitPrice': item.product.currentPrice,
        'totalPrice': item.totalPrice,
        'productImage': item.product.imageUrl,
        'brand': item.product.brand,
        'category': item.product.category,
        'stock': item.product.stock,
        'sellingPrice': item.product.sellingPrice,
      }).toList(),
      'totalAmount': totalAmount,
      'shippingFee': shippingFee,
      'grandTotal': grandTotal,
      'orderDate': orderDate.toIso8601String(),
      'status': status,
      'paymentMethod': paymentMethod,
      'userId': userId,
    };
  }
}
