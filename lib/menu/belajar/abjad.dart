import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aplikasi_sibisa/screens/home.dart';

class AbjadPage extends StatefulWidget {
  const AbjadPage({super.key});

  @override
  State<AbjadPage> createState() => _AbjadPageState();
}

class _AbjadPageState extends State<AbjadPage> {
  int currentIndex = 0;

  final List<Map<String, String>> abjadList = [
    {'image': 'assets/images/sibi_a.jpeg', 'letter': 'A'},
    {'image': 'assets/images/sibi_b.jpeg', 'letter': 'B'},
    {'image': 'assets/images/sibi_c.jpeg', 'letter': 'C'},
    {'image': 'assets/images/sibi_a.jpeg', 'letter': 'D'},
    {'image': 'assets/images/sibi_b.jpeg', 'letter': 'E'},
    {'image': 'assets/images/sibi_c.jpeg', 'letter': 'F'},
    {'image': 'assets/images/sibi_a.jpeg', 'letter': 'G'},
    {'image': 'assets/images/sibi_b.jpeg', 'letter': 'H'},
    {'image': 'assets/images/sibi_c.jpeg', 'letter': 'I'},
    {'image': 'assets/images/sibi_a.jpeg', 'letter': 'J'},
    {'image': 'assets/images/sibi_b.jpeg', 'letter': 'K'},
    {'image': 'assets/images/sibi_c.jpeg', 'letter': 'L'},
    {'image': 'assets/images/sibi_a.jpeg', 'letter': 'M'},
    {'image': 'assets/images/sibi_b.jpeg', 'letter': 'N'},
    {'image': 'assets/images/sibi_c.jpeg', 'letter': 'O'},
    {'image': 'assets/images/sibi_a.jpeg', 'letter': 'P'},
    {'image': 'assets/images/sibi_b.jpeg', 'letter': 'Q'},
    {'image': 'assets/images/sibi_c.jpeg', 'letter': 'R'},
    {'image': 'assets/images/sibi_a.jpeg', 'letter': 'S'},
    {'image': 'assets/images/sibi_b.jpeg', 'letter': 'T'},
    {'image': 'assets/images/sibi_c.jpeg', 'letter': 'U'},
    {'image': 'assets/images/sibi_a.jpeg', 'letter': 'V'},
    {'image': 'assets/images/sibi_b.jpeg', 'letter': 'W'},
    {'image': 'assets/images/sibi_c.jpeg', 'letter': 'X'},
    {'image': 'assets/images/sibi_a.jpeg', 'letter': 'Y'},
    {'image': 'assets/images/sibi_b.jpeg', 'letter': 'Z'},
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
          // Header dengan gradasi dan tombol back
          Container(
            width: double.infinity,
            height: 60,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF305CDE), Color(0xFF64A8F0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(1)),
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
                  'Belajar Abjad',
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

          // Huruf abjad
          Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 40),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.1),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Text(
              current['letter']!,
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFC567),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Gambar abjad
          Container(
            height: 250,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(128, 128, 128, 0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
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

          // Navigasi panah kiri-kanan
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

  // Tombol panah dengan box melengkung dan bayangan
  Widget _roundedBoxButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFC567),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 6,
            offset: Offset(0, 2),
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
