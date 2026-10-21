import 'package:flutter/material.dart';
import 'data.dart';
import 'screens.dart';
import 'theme.dart';

void main() {
  runApp(const CrediApp());
}

class CrediApp extends StatelessWidget {
  const CrediApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return MaterialApp(
          title: 'CrediAPP',
          debugShowCheckedModeBanner: false,
          theme: crediTheme(),
          home: const LoginPage(),
        );
      },
    );
  }
}
