import 'package:firebase_database/firebase_database.dart';
import '../models/product_model.dart';
class ProductService {
  final DatabaseReference _productsRef = 
      FirebaseDatabase.instance.ref().child('products');

  // Récupérer tous les produits
  Future<List<Product>> getAllProducts() async {
    try {
      DatabaseEvent event = await _productsRef.once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value == null) return [];

      Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
      List<Product> products = [];

      values.forEach((key, value) {
        products.add(Product.fromMap(Map<String, dynamic>.from(value), key));
      });

      return products;
    } catch (e) {
      print('Erreur lors de la récupération des produits: $e');
      return [];
    }
  }

  // Récupérer un produit par ID
  Future<Product?> getProductById(String id) async {
    try {
      DatabaseEvent event = await _productsRef.child(id).once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value == null) return null;

      return Product.fromMap(
        Map<String, dynamic>.from(snapshot.value as Map),
        id,
      );
    } catch (e) {
      print('Erreur lors de la récupération du produit: $e');
      return null;
    }
  }
}