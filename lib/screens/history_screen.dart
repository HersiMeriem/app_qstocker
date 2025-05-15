import 'package:flutter/material.dart';
import 'custom_bottom_bar.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fcff),
      appBar: AppBar(
        title: const Text('Historique des scans'),
        backgroundColor: const Color(0xFFf8fcff),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF548CB8)),
      ),
      body: const Center(
        child: Text(
          'Historique des produits scannés',
          style: TextStyle(fontSize: 18, color: Color(0xFF1e4868)),
        ),
      ),
bottomNavigationBar: buildCustomBottomBar(context, 2),
    );
  }
}