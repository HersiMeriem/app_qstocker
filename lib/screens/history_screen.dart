import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'custom_bottom_bar.dart';
import 'product_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  SortOption _sortOption = SortOption.newestFirst;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final productService = Provider.of<ProductService>(context, listen: false);
    await productService.ensureHistoryLoaded();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductService>(context);
    final history = productService.scanHistory;

    final filteredHistory = history.where((product) {
      final query = _searchQuery.toLowerCase();
      return product.name.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query) ||
          (product.qrCode?.toLowerCase().contains(query) ?? false);
    }).toList();

    filteredHistory.sort((a, b) {
      final aDate = productService.getScanDate(a);
      final bDate = productService.getScanDate(b);

      switch (_sortOption) {
        case SortOption.newestFirst:
          return bDate.compareTo(aDate);
        case SortOption.oldestFirst:
          return aDate.compareTo(bDate);
        case SortOption.nameAsc:
          return a.name.compareTo(b.name);
        case SortOption.nameDesc:
          return b.name.compareTo(a.name);
      }
    });

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFf8fcff),
      appBar: AppBar(
        title: const Text('Historique des scans'),
        backgroundColor: const Color(0xFFf8fcff),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF548CB8)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showClearHistoryDialog(context, productService),
            tooltip: 'Effacer l\'historique',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher dans l\'historique...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Trier par: '),
                    const SizedBox(width: 8),
                    DropdownButton<SortOption>(
                      value: _sortOption,
                      items: SortOption.values.map((option) {
                        return DropdownMenuItem<SortOption>(
                          value: option,
                          child: Text(option.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _sortOption = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredHistory.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun scan dans l\'historique',
                      style: TextStyle(fontSize: 18, color: Color(0xFF1e4868)),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      final product = filteredHistory[index];
                      return _buildHistoryItem(context, product, productService);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: buildCustomBottomBar(context, 2),
    );
  }

  Widget _buildHistoryItem(BuildContext context, Product product, ProductService productService) {
    IconData statusIcon;
    Color statusColor;
    String statusText;

    if (product.qrCode == null || product.qrCode!.isEmpty) {
      statusIcon = Icons.qr_code_scanner;
      statusColor = Colors.grey;
      statusText = "QR Code non détecté";
    } else if (product.isAuthentic ?? false) {
      statusIcon = Icons.verified;
      statusColor = Colors.green;
      statusText = "Authentique";
    } else {
      statusIcon = Icons.warning;
      statusColor = Colors.orange;
      statusText = "Suspect - Possible contrefaçon";
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildProductImage(product.imageUrl!),
                      )
                    : const Icon(Icons.image_not_supported),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      product.brand,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scanné le ${DateFormat('dd/MM/yyyy à HH:mm').format(productService.getScanDate(product))}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.startsWith('data:image/')) {
      final base64Data = imageUrl.split(',').last;
      return Image.memory(
        base64Decode(base64Data),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
      );
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
      );
    }
  }

  Future<void> _showClearHistoryDialog(
      BuildContext context, ProductService productService) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Effacer l\'historique'),
          content: const Text(
              'Voulez-vous vraiment effacer tout l\'historique des scans ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Effacer', style: TextStyle(color: Colors.red)),
              onPressed: () {
                productService.clearHistory();
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }
}

enum SortOption {
  newestFirst,
  oldestFirst,
  nameAsc,
  nameDesc,
}

extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.newestFirst:
        return 'Plus récent';
      case SortOption.oldestFirst:
        return 'Plus ancien';
      case SortOption.nameAsc:
        return 'Nom (A-Z)';
      case SortOption.nameDesc:
        return 'Nom (Z-A)';
    }
  }
}
