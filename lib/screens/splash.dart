import 'package:flutter/material.dart';
import 'package:aplikasi_sibisa/screens/home.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    // Navigasi ke Home setelah 3 detik
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background putih polos
          Container(
            color: Colors.white,
          ),

          // Logo di tengah
          Center(
            child: Image.asset(
              'assets/images/Icon.png',
              width: MediaQuery.of(context).size.width * 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
