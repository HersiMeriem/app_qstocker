import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_qstocker/services/product_service.dart';
import 'package:app_qstocker/screens/login_screen.dart';
import 'package:app_qstocker/screens/home_screen.dart';
import 'package:app_qstocker/screens/scan_screen.dart';
import 'package:app_qstocker/screens/history_screen.dart';
import 'package:app_qstocker/screens/products_screen.dart';

final Map<String, WidgetBuilder> routes = {
  '/home': (context) => const HomeScreen(),
  '/scan': (context) => const ScanScreen(),
  '/history': (context) => const HistoryScreen(),
  '/products': (context) => ProductsScreen(
        productService: Provider.of<ProductService>(context, listen: false),
      ),
  '/login': (context) => const LoginScreen(),
};