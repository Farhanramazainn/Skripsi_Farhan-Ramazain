import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aplikasi_sibisa/screens/home.dart';

class AngkaPage extends StatefulWidget {
  const AngkaPage({super.key});

  @override
  State<AngkaPage> createState() => _AngkaPageState();
}

class _AngkaPageState extends State<AngkaPage> {
  int currentIndex = 0;

  final List<Map<String, String>> abjadList = [
    {'image': 'assets/images/sibi_a.jpeg', 'letter': '0'},
    {'image': 'assets/images/sibi_b.jpeg', 'letter': '1'},
    {'image': 'assets/images/sibi_c.jpeg', 'letter': '2'},
    {'image': 'assets/images/sibi_a.jpeg', 'letter': '3'},
    {'image': 'assets/images/sibi_b.jpeg', 'letter': '4'},
    {'image': 'assets/images/sibi_c.jpeg', 'letter': '5'},
    {'image': 'assets/images/sibi_a.jpeg', 'letter': '6'},
    {'image': 'assets/images/sibi_b.jpeg', 'letter': '7'},
    {'image': 'assets/images/sibi_c.jpeg', 'letter': '8'},
    {'image': 'assets/images/sibi_c.jpeg', 'letter': '9'},
  ];

  void _next() {
    setState(() {
      currentIndex = (currentIndex + 1) % abjadList.length;
    });
  }

  void _previous() {
    setState(() {
      currentIndex = (currentIndex - 1 + abjadList.length) % abjadList.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = abjadList[currentIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header gradasi + back button
          Container(
            width: double.infinity,
            height: 60,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF305CDE),
                  Color(0xFF64A8F0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(1),
                bottomRight: Radius.circular(1),
              ),
            ),
            padding: const EdgeInsets.only(left: 1, top: 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  'Belajar Angka',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Letter
          Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 40),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Text(
              current['letter']!,
              style: GoogleFonts.poppins(
                fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF7B7B),
                 ),
              ),
          ),
           const SizedBox(height: 40),
          // Kotak gambar
          Container(
            height: 250,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                current['image']!,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Tombol panah
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _roundedBoxButton(Icons.arrow_back_ios_rounded, _previous),
              const SizedBox(width: 16),
              _roundedBoxButton(Icons.arrow_forward_ios_rounded, _next),
            ],
          ),
        ],
      ),
    );
  }

  // Tombol panah dalam kotak melengkung
  Widget _roundedBoxButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFF7B7B),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}
