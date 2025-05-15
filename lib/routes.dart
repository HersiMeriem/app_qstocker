import 'package:app_qstocker/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/history_screen.dart';
import 'screens/products_screen.dart';

final Map<String, WidgetBuilder> routes = {
  '/home': (context) => const HomeScreen(),
  '/scan': (context) => const ScanScreen(),
  '/history': (context) => const HistoryScreen(),
  '/products': (context) => const ProductsScreen(),
  '/login':(context) => const LoginScreen()
};