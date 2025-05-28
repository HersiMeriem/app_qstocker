import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'product_detail_screen.dart';
import 'custom_bottom_bar.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  static const Color backgroundColor = Colors.black87;

  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
    formats: [
      BarcodeFormat.qrCode,
      BarcodeFormat.dataMatrix,
      BarcodeFormat.ean13,
      BarcodeFormat.code128,
    ],
    returnImage: false,
    detectionTimeoutMs: 250,
  );

  bool _isProcessing = false;
  bool _isFlashOn = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture barcodeCapture) async {
    if (_isProcessing || barcodeCapture.barcodes.isEmpty) return;

    final rawCode = barcodeCapture.barcodes.first.rawValue;
    final qrCode = rawCode?.replaceAll('\n', '').trim();

    if (qrCode == null || qrCode.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final productService = Provider.of<ProductService>(context, listen: false);
      final product = await productService.fetchProductByQrCode(qrCode);

      if (!mounted) return;

      if (product != null) {
        // Produit authentique
        productService.addToHistory(product.copyWith(isAuthentic: true));
        await _showProductDialog(product);
      } else {
        // Produit suspect - créer un produit temporaire
        final suspectProduct = Product(
          id: qrCode,
          name: 'Produit inconnu',
          brand: 'Marque inconnue',
          qrCode: qrCode,
          category: 'Inconnu',
          volume: 'N/A',
          costPrice: 0,
          origin: 'Inconnue',
          status: 'suspect',
          unitPrice: 0,
          perfumeType: 'Inconnu',
          stock: 0,
          sellingPrice: 0,
          isAuthentic: false, // Marqué comme suspect
        );

        productService.addToHistory(suspectProduct);
        await _showAlert(
          icon: Icons.warning_amber_rounded,
          color: Colors.orange,
          title: "Produit Suspect",
          message: "Ce produit ($qrCode) n'est pas reconnu et peut être une contrefaçon.",
        );
      }
    } catch (e) {
      await _showAlert(
        icon: Icons.error_outline,
        color: Colors.redAccent,
        title: "Erreur",
        message: "Une erreur est survenue : ${e.toString()}",
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showProductDialog(Product product) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, color: Colors.green, size: 60),
                  const SizedBox(height: 10),
                  const Text("Produit Authentifié",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildProductImage(product),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(product.name,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                  Text(product.brand,
                      style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[800],
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        icon: const Icon(Icons.close, size: 20),
                        label: const Text("Fermer"),
                      ),
                  ElevatedButton.icon(
  onPressed: () {
    Navigator.of(ctx).pop();
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ProductDetailScreen(product: product),
  ),
);

  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.symmetric(
        horizontal: 20, vertical: 12),
  ),
  icon: const Icon(Icons.arrow_forward_ios, size: 18),
  label: const Text("Détails"),
),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductImage(Product product) {
    final imageData = product.imageUrl;

    if (imageData != null && imageData.startsWith('data:image/')) {
      try {
        final base64Data = imageData.split(',').last;
        return Image.memory(
          base64Decode(base64Data),
          fit: BoxFit.contain,
          errorBuilder: (ctx, err, stack) => _buildPlaceholder(),
        );
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
        return _buildPlaceholder();
      }
    }

    if (imageData != null && (imageData.startsWith('http://') || imageData.startsWith('https://'))) {
      return Image.network(
        imageData,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported,
                 size: 50,
                 color: Colors.grey[400]),
            const SizedBox(height: 8),
            const Text('Image non disponible',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Future<void> _showAlert({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(icon, color: color, size: 52),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Scanner un produit"),
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              setState(() => _isFlashOn = !_isFlashOn);
              _controller.toggleTorch();
            },
            color: _isFlashOn ? Colors.yellow : Colors.white,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            fit: BoxFit.cover,
          ),
          _buildOverlayUI(),
        ],
      ),
      bottomNavigationBar: buildCustomBottomBar(context, 2),
    );
  }

  Widget _buildOverlayUI() {
    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white54, width: 1.5),
                ),
                child: CustomPaint(painter: _ScannerCornersPainter()),
              ),
              AnimatedBuilder(
                animation: _animationController,
                builder: (_, __) {
                  final value = _animationController.value;
                  return Positioned(
                    top: 260 * value,
                    child: Container(
                      width: 260,
                      height: 2,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.greenAccent, Colors.transparent],
                          stops: [0.1, 0.5, 0.9],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Text(
            "Alignez le QR code dans le cadre pour scanner",
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ScannerCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    const length = 35.0;

    canvas.drawLine(Offset(0, 0), Offset(length, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(0, length), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - length, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, length), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - length, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - length), paint);
    canvas.drawLine(Offset(0, size.height), Offset(length, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - length), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
