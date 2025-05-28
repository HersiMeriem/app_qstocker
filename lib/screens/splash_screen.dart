import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/auth');
    });

    return Scaffold(
      backgroundColor: const Color(0xFFf8fcff),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('images/logoQS.png', height: 120),
            const SizedBox(height: 30),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Q',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e4868),
                    ),
                  ),
                  TextSpan(
                    text: 'trace',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF548CB8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Vérifiez, Soyez Sûr,',
              style: TextStyle(fontSize: 16, color: Color(0xFF93bede)),
            ),
            const Text(
              'Achetez en confiance',
              style: TextStyle(fontSize: 16, color: Color(0xFF93bede)),
            ),
          ],
        ),
      ),
    );
  }
}