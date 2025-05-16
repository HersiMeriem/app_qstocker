class Product {
  final String id;
  final String name;
  final String? qrCode;
  final String? description;
  final String? olfactiveFamily;
  final String brand;
  final String category;
  final String? imageUrl;
  final String volume;
  final double costPrice;
  final String origin;
  final String status;
  final double unitPrice;
  final String perfumeType;
  final Promotion? promotion;
  final bool? isAuthentic;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    this.qrCode,
    this.description,
    this.olfactiveFamily,
    required this.brand,
    required this.category,
    this.imageUrl,
    required this.volume,
    required this.costPrice,
    required this.origin,
    required this.status,
    required this.unitPrice, 
    required this.perfumeType,
    this.promotion,
    this.isAuthentic,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<dynamic, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      qrCode: json['qrCode'],
      description: json['description'],
      olfactiveFamily: json['olfactiveFamily'],
      brand: json['brand'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['imageUrl'],
      volume: json['volume'] ?? '',
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      origin: json['origin'] ?? '',
      status: json['status'] ?? 'active',
      unitPrice: (json['unitPrice'] ?? 0).toDouble(), // Remplacement de prixDeVente par unitPrice
      perfumeType: json['perfumeType'] ?? '',
      promotion: json['promotion'] != null
          ? Promotion.fromJson(json['promotion'])
          : null,
      isAuthentic: json['isAuthentic'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  double get currentPrice {
    if (status == 'promotion' && promotion != null && _isPromotionActive()) {
      return unitPrice * (1 - (promotion!.discountPercentage / 100)); // Remplacement de prixDeVente par unitPrice
    }
    return unitPrice; 
  }

  bool _isPromotionActive() {
    if (promotion == null) return false;
    final now = DateTime.now();
    final start = DateTime.parse(promotion!.startDate);
    final end = DateTime.parse(promotion!.endDate);
    return now.isAfter(start) && now.isBefore(end);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'qrCode': qrCode,
      'description': description,
      'olfactiveFamily': olfactiveFamily,
      'brand': brand,
      'category': category,
      'imageUrl': imageUrl,
      'volume': volume,
      'costPrice': costPrice,
      'origin': origin,
      'status': status,
      'unitPrice': unitPrice,
      'perfumeType': perfumeType,
      'promotion': promotion?.toJson(),
      'isAuthentic': isAuthentic,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class Promotion {
  final String startDate;
  final String endDate;
  final double discountPercentage;

  Promotion({
    required this.startDate,
    required this.endDate,
    required this.discountPercentage,
  });

  factory Promotion.fromJson(Map<dynamic, dynamic> json) {
    return Promotion(
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      discountPercentage: (json['discountPercentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate,
      'endDate': endDate,
      'discountPercentage': discountPercentage,
    };
  }
}
