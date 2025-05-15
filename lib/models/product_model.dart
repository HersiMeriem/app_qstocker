class Product {
  final String id;
  final String name;
  final String type;
  final String category;
  final String description;
  final String qrCode;
  final String? imageUrl;
  final String volume;
  final String status; // 'active' | 'inactive' | 'promotion'
  final bool? isAuthentic;
  final double? discount;
  final Promotion? promotion;

  Product({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.description,
    required this.qrCode,
    this.imageUrl,
    required this.volume,
    required this.status,
    this.isAuthentic,
    this.discount,
    this.promotion,
  });

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      qrCode: map['qrCode'] ?? '',
      imageUrl: map['imageUrl'],
      volume: map['volume'] ?? '',
      status: map['status'] ?? 'active',
      isAuthentic: map['isAuthentic'],
      discount: map['discount']?.toDouble(),
      promotion: map['promotion'] != null 
          ? Promotion.fromMap(map['promotion']) 
          : null,
    );
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

  factory Promotion.fromMap(Map<String, dynamic> map) {
    return Promotion(
      startDate: map['startDate'] ?? '',
      endDate: map['endDate'] ?? '',
      discountPercentage: map['discountPercentage']?.toDouble() ?? 0.0,
    );
  }
}