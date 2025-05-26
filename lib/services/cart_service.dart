import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartService with ChangeNotifier {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  List<CartItem> _items = [];
  String? _userId;

  List<CartItem> get items => _items;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get shippingFee => totalAmount > 500 ? 0 : 8;

  double get grandTotal => totalAmount + shippingFee;

  // Initialiser avec l'ID utilisateur
  void init(String userId) {
    _userId = userId;
    _loadCart();
  }

  Future<void> _loadCart() async {
    if (_userId == null) return;

    try {
      final snapshot = await _dbRef.child('userCarts/$_userId').once();
      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        _items = data.entries.map((entry) {
          return CartItem(
            product: Product.fromJson(Map<String, dynamic>.from(entry.value['product'])),
            quantity: entry.value['quantity'],
          );
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cart: $e');
    }
  }

  Future<void> _saveCart() async {
    if (_userId == null) return;

    try {
      final cartData = _items.asMap().map((index, item) {
        return MapEntry(
          item.product.id,
          {
            'product': item.product.toJson(),
            'quantity': item.quantity,
          },
        );
      });

      await _dbRef.child('userCarts/$_userId').set(cartData);
    } catch (e) {
      debugPrint('Error saving cart: $e');
    }
  }

  void addToCart(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }

    _saveCart();
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(String productId, int newQuantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);

    if (index >= 0) {
      if (newQuantity > 0) {
        _items[index].quantity = newQuantity;
      } else {
        _items.removeAt(index);
      }

      _saveCart();
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    if (_userId != null) {
      _dbRef.child('userCarts/$_userId').remove();
    }
    notifyListeners();
  }
}
