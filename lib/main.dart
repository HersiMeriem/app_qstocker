import 'package:app_qstocker/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_wrapper.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'services/auth_service.dart';
import 'firebase_options.dart';
import 'services/product_service.dart';
import 'services/cart_service.dart';
import 'theme/theme.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialisation de Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialisation des formats de date pour le français
    Intl.defaultLocale = 'fr_FR';

    runApp(
      MultiProvider(
        providers: [
          Provider<AuthService>(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => CartService()),
          Provider(create: (_) => ProductService()), 
          Provider<OrderService>(
  create: (_) => OrderService(
    baseUrl: 'https://qstockerpfe-default-rtdb.firebaseio.com/',
  ),
),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    print('Erreur lors de l\'initialisation de l\'application: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QStocker',
      debugShowCheckedModeBanner: false,

      // Configuration de l'internationalisation
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'), // Français
      ],
      locale: const Locale('fr', 'FR'),

      // ✅ Nouvelle configuration avec le thème extrait
      theme: appTheme,

      // Gestion des routes
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthWrapper(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
      },

      // Personnalisation des transitions entre pages
      onGenerateRoute: (settings) {
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            switch (settings.name) {
              case '/':
                return const SplashScreen();
              case '/auth':
                return const AuthWrapper();
              case '/home':
                return const HomeScreen();
              case '/login':
                return const LoginScreen();
              case '/register':
                return const RegisterScreen();
              case '/forgot-password':
                return const ForgotPasswordScreen();
              default:
                return const Scaffold(
                  body: Center(child: Text('Page non trouvée')),
                );
            }
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
      },
    );
  }
}