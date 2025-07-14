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

  // Otomatis generate huruf A-Z dan gambar sibi_a.jpeg - sibi_z.jpeg
  final List<Map<String, String>> abjadList = List.generate(26, (index) {
    String letter = String.fromCharCode('A'.codeUnitAt(0) + index);
    return {
      'image': 'assets/images/sibi_${letter.toLowerCase()}.jpeg',
      'letter': letter,
    };
  });

  void _next() {
    if (currentIndex < abjadList.length - 1) {
      setState(() {
        currentIndex++;
      });
    }
  }

  void _previous() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = abjadList[currentIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4299E1), Color(0xFF3182CE)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
        title: Text(
          'Belajar Abjad',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E88E5),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${currentIndex + 1}/${abjadList.length}',
              style: GoogleFonts.poppins(
                color: const Color(0xFF1E88E5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (currentIndex + 1) / abjadList.length,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          const SizedBox(height: 60),

          // Huruf abjad
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                current['letter']!,
                style: GoogleFonts.poppins(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 80),

          // Gambar
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE3F2FD),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.asset(
                    current['image']!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Navigasi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navButton(
                icon: Icons.chevron_left,
                onPressed: currentIndex > 0 ? _previous : null,
              ),
              
              // Dots
              Row(
                children: List.generate(
                  abjadList.length > 5 ? 5 : abjadList.length,
                  (index) {
                    int dotIndex = currentIndex < 3 
                        ? index 
                        : currentIndex > abjadList.length - 3 
                            ? abjadList.length - 5 + index
                            : currentIndex - 2 + index;
                    
                    return Container(
                      width: dotIndex == currentIndex ? 12 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: dotIndex == currentIndex 
                            ? const Color(0xFF1E88E5)
                            : const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  },
                ),
              ),
              
              _navButton(
                icon: Icons.chevron_right,
                onPressed: currentIndex < abjadList.length - 1 ? _next : null,
              ),
            ],
          ),

          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: onPressed != null
              ? const LinearGradient(
                  colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                )
              : LinearGradient(
                  colors: [Colors.grey.shade200, Colors.grey.shade300],
                ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: onPressed != null ? Colors.white : Colors.grey.shade400,
          size: 20,
        ),
      ),
    );
  }
}
