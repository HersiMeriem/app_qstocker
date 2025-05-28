import 'package:firebase_database/firebase_database.dart';
import '../models/product.dart';

class ProductService {
  final DatabaseReference _productsRef = FirebaseDatabase.instance.ref().child('products');
  final DatabaseReference _stockRef = FirebaseDatabase.instance.ref().child('stock');
  final DatabaseReference _scanHistoryRef = FirebaseDatabase.instance.ref().child('scanHistory');
  List<Product> _scanHistory = [];
  final Map<String, DateTime> _scanDates = {};
  bool _isHistoryLoaded = false;

  List<Product> get scanHistory {
    if (!_isHistoryLoaded) {
      _loadScanHistory();
      return [];
    }
    return _scanHistory;
  }

  Future<void> ensureHistoryLoaded() async {
    if (!_isHistoryLoaded) {
      await _loadScanHistory();
    }
  }

  Future<void> _loadScanHistory() async {
    try {
      final snapshot = await _scanHistoryRef.orderByChild('scanDate').once();
      _scanHistory = [];
      _scanDates.clear();

      if (snapshot.snapshot.value != null) {
        final historyData = snapshot.snapshot.value as Map<dynamic, dynamic>;

        final tempList = <Product>[];
        final tempDates = <String, DateTime>{};

        historyData.forEach((key, value) {
          try {
            final productData = Map<String, dynamic>.from(value);
            final product = Product.fromJson(productData);
            tempList.add(product);

            final scanDateStr = productData['scanDate'] as String?;
            tempDates[product.id] = scanDateStr != null
                ? DateTime.parse(scanDateStr)
                : DateTime.now();
          } catch (e) {
            print('Error parsing scan history item $key: $e');
          }
        });

        tempList.sort((a, b) {
          final aDate = tempDates[a.id] ?? DateTime.now();
          final bDate = tempDates[b.id] ?? DateTime.now();
          return bDate.compareTo(aDate);
        });

        _scanHistory = tempList;
        _scanDates.addAll(tempDates);
      }
      _isHistoryLoaded = true;
    } catch (e) {
      print('Error loading scan history: $e');
      _isHistoryLoaded = true;
    }
  }

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

          final stockQuantity = (stockData['quantite'] ?? stockData['quantity'] ?? 0) as int;
          final status = stockQuantity <= 0 ? 'out-of-stock' : (productData['status'] ?? 'active');

          return Product.fromJson({
            ...productData,
            'stock': stockQuantity,
            'sellingPrice': (stockData['prixDeVente'] ?? stockData['sellingPrice'] ?? productData['unitPrice'] ?? 0).toDouble(),
            'status': status,
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

Future<Product?> fetchProductByQrCode(String qrCode) async {
  try {
    final cleanedQrCode = qrCode.trim();

    final qrSnapshot = await _productsRef
        .orderByChild('qrCode')
        .equalTo(cleanedQrCode)
        .once();

    if (qrSnapshot.snapshot.value != null) {
      final data = qrSnapshot.snapshot.value as Map<dynamic, dynamic>;
      final productEntry = data.entries.first;
      return await _createProductFromEntry(productEntry);
    }

    final productSnapshot = await _productsRef.child(cleanedQrCode).once();
    if (productSnapshot.snapshot.value != null) {
      return await _createProductFromEntry(
        MapEntry(cleanedQrCode, productSnapshot.snapshot.value),
      );
    }

    return null;
  } catch (e) {
    print('Error fetching product by QR code: $e');
    throw Exception('Erreur de chargement du produit par QR code');
  }
}

Future<Product> _createProductFromEntry(MapEntry<dynamic, dynamic> entry) async {
  final productId = entry.key as String;
  final productData = {...entry.value as Map};

  final stockSnapshot = await _stockRef.child(productId).once();
  final stockData = stockSnapshot.snapshot.value as Map? ?? {};

  final sellingPrice = (stockData['sellingPrice'] ??
                        stockData['prixDeVente'] ??
                        productData['sellingPrice'] ??
                        productData['unitPrice'] ??
                        0).toDouble();

  final stockQuantity = (stockData['quantity'] ?? stockData['quantite'] ?? 0) as int;

  return Product.fromJson({
    ...productData,
    'id': productId,
    'stock': stockQuantity,
    'sellingPrice': sellingPrice,
  });
}

  Future<void> addToHistory(Product product) async {
    if (!_isHistoryLoaded) await _loadScanHistory();

    _scanHistory.removeWhere((p) => p.id == product.id);

    _scanHistory.insert(0, product);
    _scanDates[product.id] = DateTime.now();

    await _scanHistoryRef.child(product.id).set({
      ...product.toJson(),
      'scanDate': DateTime.now().toIso8601String(),
      'isAuthentic': product.isAuthentic ?? false, // Sauvegarder explicitement le statut
    });
  }

  void clearHistory() {
    _scanHistory.clear();
    _scanDates.clear();
    _scanHistoryRef.remove();
  }

  DateTime getScanDate(Product product) {
    return _scanDates[product.id] ?? DateTime.now();
  }
}
