import 'package:aplikasi_sibisa/menu/belajar/abjad.dart';
import 'package:aplikasi_sibisa/menu/belajar/angka.dart';
import 'package:aplikasi_sibisa/menu/test/alphabet.dart';
import 'package:aplikasi_sibisa/menu/test/number.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'info.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InfoPage()),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 0,
        unselectedFontSize: 0,
        backgroundColor: Colors.white,
        elevation: 10,
        items: [
          _buildNavItem(icon: Icons.house_rounded, label: 'Home', isSelected: _selectedIndex == 0),
          _buildNavItem(icon: Icons.info_outline_rounded, label: 'Info', isSelected: _selectedIndex == 1),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              height: 250,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF305CDE), Color(0xFF64A8F0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello,',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: Color.fromRGBO(255, 255, 255, 0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Yuk Belajar Bahasa Isyarat SIBI!',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Image.asset(
                        'assets/images/Icon.png',
                        width: 70,
                        height: 70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Learning Section
            const Padding(
              padding: EdgeInsets.only(right: 240, top: 20),
              child: Text(
                "Learning",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(right: 0, top: 5),
              child: Text(
                "Belajar bahasa isyarat SIBI abjad dan angka",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black45,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _horizontalMenuSection(context, isTest: false),
            const SizedBox(height: 24),

            // Test Section
            const Padding(
              padding: EdgeInsets.only(right: 280, top: 20),
              child: Text(
                "Test",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(right: 100, top: 5),
              child: Text(
                "Test kemampuan gerakan SIBI",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black45,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _horizontalMenuSection(context, isTest: true),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return BottomNavigationBarItem(
      label: '',
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF305CDE), Color(0xFF64A8F0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _horizontalMenuSection(BuildContext context, {required bool isTest}) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: isTest ? 160 : 140,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildMenuCard(
              title: 'Abjad',
              subtitle: 'Sign',
              color: isTest ? const Color(0xFFFF86E0) : const Color(0xFFFFC567),
              iconPath: 'assets/images/a.png',
              context: context,
              screenWidth: screenWidth,
              isTest: isTest,
            ),
            const SizedBox(width: 16),
            _buildMenuCard(
              title: 'Angka',
              subtitle: 'Sign',
              color: isTest ? const Color(0xFF6EE9BE) : const Color(0xFFFF7B7B),
              iconPath: 'assets/images/1.png',
              context: context,
              screenWidth: screenWidth,
              isTest: isTest,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required Color color,
    required String iconPath,
    required BuildContext context,
    required double screenWidth,
    bool isTest = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (!isTest) {
          if (title == 'Abjad') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AbjadPage()));
          } else if (title == 'Angka') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AngkaPage()));
          }
        }
      },
      child: Container(
        width: isTest ? screenWidth * 0.7 : screenWidth * 0.45,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: const Color.fromRGBO(255, 255, 255, 0.85),
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isTest)
                      ElevatedButton(
                        onPressed: () {
                          if (title == 'Abjad') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AlphabetPage()));
                          } else if (title == 'Angka') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const NumberPage()));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Start'),
                      ),
                    Image.asset(
                      iconPath,
                      height: screenWidth * 0.15,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
