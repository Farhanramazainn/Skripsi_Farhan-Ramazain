import 'package:aplikasi_sibisa/menu/belajar/abjad.dart';
import 'package:aplikasi_sibisa/menu/belajar/angka.dart';
import 'package:aplikasi_sibisa/menu/test/alphabet.dart';
import 'package:aplikasi_sibisa/menu/test/number.dart';
import 'package:aplikasi_sibisa/screens/home.dart';
import 'package:aplikasi_sibisa/screens/info.dart';
import 'package:aplikasi_sibisa/screens/splash.dart';
import 'package:flutter/material.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sibisa',
      initialRoute: '/splash',
      routes: {
        '/': (context) => const HomePage(),
        '/alphabet': (context) => const AlphabetPage(),
        '/number': (context) => const NumberPage(),
        '/abjad': (context) => const AbjadPage(),
        '/angka': (context) => const AngkaPage(),
        '/info': (context) => const InfoPage(),
        '/splash': (context) => const SplashPage(),

      },
    );
  }
}
