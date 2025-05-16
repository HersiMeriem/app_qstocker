import 'package:firebase_database/firebase_database.dart';
import '../models/product.dart';

class ProductService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref().child('products');

  Future<List<Product>> fetchProducts() async {
    try {
      DatabaseEvent event = await _database.once();
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
        return values.values.map((value) => Product.fromJson(value)).toList();
      } else {
        return [];
      }
    } catch (e) {
      throw Exception('Erreur de connexion: ${e.toString()}');
    }
  }

  Future<Product> fetchProductById(String id) async {
    try {
      DatabaseEvent event = await _database.child(id).once();
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        return Product.fromJson(snapshot.value as Map<dynamic, dynamic>);
      } else {
        throw Exception('Produit non trouvé');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: ${e.toString()}');
    }
  }
}
