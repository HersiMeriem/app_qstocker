import 'package:firebase_database/firebase_database.dart';
import '../models/product.dart';

class ProductService {
  final DatabaseReference _productsRef = FirebaseDatabase.instance.ref().child('products');
  final DatabaseReference _stockRef = FirebaseDatabase.instance.ref().child('stock');

Future<List<Product>> fetchProducts() async {
  try {
    final results = await Future.wait([
      _productsRef.once(),
      _stockRef.once(),
    ]);

    final productsSnapshot = results[0];
    final stockSnapshot = results[1];

    if (productsSnapshot.snapshot.value == null) return [];

    final productsMap = productsSnapshot.snapshot.value as Map;
    final stockMap = stockSnapshot.snapshot.value as Map? ?? {};

    final products = productsMap.entries.map((entry) {
      try {
        final productData = {...entry.value as Map};
        final stockData = stockMap[entry.key] as Map? ?? {};

        // Vérifier si le produit est en stock
        final stockQuantity = (stockData['quantite'] ?? stockData['quantity'] ?? 0) as int;
        final status = stockQuantity <= 0 ? 'out-of-stock' : 
                      (productData['status'] ?? 'active');

        return Product.fromJson({
          ...productData,
          'stock': stockQuantity,
          'sellingPrice': (stockData['prixDeVente'] ?? stockData['sellingPrice'] ?? productData['unitPrice'] ?? 0).toDouble(),
          'status': status, // Mettre à jour le statut en fonction du stock
        });
      } catch (e) {
        print('Error parsing product ${entry.key}: $e');
        return null;
      }
    }).whereType<Product>().toList();

    _logProductsDetails(products);
    return products;
  } catch (e) {
    print('Error fetching products: $e');
    throw Exception('Erreur de chargement des produits: ${e.toString()}');
  }
}



  Future<Product> fetchProductById(String id) async {
    try {
      final results = await Future.wait([
        _productsRef.child(id).once(),
        _stockRef.child(id).once(),
      ]);

      final productSnapshot = results[0];
      final stockSnapshot = results[1];

      if (productSnapshot.snapshot.value == null) {
        throw Exception('Produit non trouvé');
      }

      final productData = {...productSnapshot.snapshot.value as Map};
      final stockData = stockSnapshot.snapshot.value as Map? ?? {};

      final product = Product.fromJson({
        ...productData,
        'stock': stockData['quantity'] ?? 0,
        'sellingPrice': stockData['sellingPrice'] ?? productData['unitPrice'] ?? 0,
      });

      print('Fetched product by ID: ${product.id}');
      print('Current price: ${product.currentPrice}');
      print('Stock: ${product.stock}');
      
      return product;
    } catch (e) {
      print('Error fetching product $id: $e');
      throw Exception('Erreur de chargement du produit: ${e.toString()}');
    }
  }

  Future<void> updateProductStock(String productId, int newStock) async {
    try {
      await _stockRef.child(productId).update({
        'quantity': newStock,
        'lastUpdated': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error updating stock for $productId: $e');
      throw Exception('Erreur de mise à jour du stock');
    }
  }

  void _logProductsDetails(List<Product> products) {
    print('=== Produits chargés (${products.length}) ===');
    for (var product in products) {
      print('ID: ${product.id}');
      print('Nom: ${product.name}');
      print('Prix: ${product.sellingPrice} DT');
      print('Stock: ${product.stock}');
      print('Statut: ${product.status}');
      
      if (product.isOnPromotion) {
        print('PROMO: -${product.promotion!.discountPercentage}%');
        print('Prix promo: ${product.currentPrice} DT');
        print('Valide jusqu\'au: ${product.promotion!.endDate}');
      }
      
      print('-------------------');
    }
  }

  //qrcode
 Future<Product?> fetchProductByQrCode(String qrCode) async {
  try {
    final snapshot = await _productsRef
        .orderByChild('qrCode')
        .equalTo(qrCode)
        .once();

    if (snapshot.snapshot.value == null) return null;

    final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
    final productEntry = data.entries.first;
    final productId = productEntry.key as String;
    final productData = {...productEntry.value as Map};
    
    // Récupérer aussi les données de stock
    final stockSnapshot = await _stockRef.child(productId).once();
    final stockData = stockSnapshot.snapshot.value as Map? ?? {};

    return Product.fromJson({
      ...productData,
      'id': productId,
      'stock': stockData['quantity'] ?? 0,
      'sellingPrice': stockData['sellingPrice'] ?? productData['unitPrice'] ?? 0,
    });
  } catch (e) {
    print('Error fetching product by QR code: $e');
    throw Exception('Erreur de chargement du produit par QR code');
  }
}


}