import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Screens
import 'package:aplikasi_sibisa/screens/home.dart';
import 'package:aplikasi_sibisa/screens/info.dart';
import 'package:aplikasi_sibisa/screens/splash.dart';

// Menu
import 'package:aplikasi_sibisa/menu/belajar/abjad.dart';
import 'package:aplikasi_sibisa/menu/belajar/angka.dart';
import 'package:aplikasi_sibisa/menu/test/alphabet.dart';
import 'package:aplikasi_sibisa/menu/test/number.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = ThemeData.light().textTheme; 
    return MaterialApp(
      title: 'Sibisa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(baseTextTheme),
      ),
      initialRoute: '/splash',
      routes: {
        '/': (context) => const HomePage(),
        '/splash': (context) => const SplashPage(),
        '/info': (context) => const InfoPage(),
        '/abjad': (context) => const AbjadPage(),
        '/angka': (context) => const AngkaPage(),
        '/alphabet': (context) => const AlphabetPage(),
        '/number': (context) => const NumberPage(),
      },
    );
  }
}
