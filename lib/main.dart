
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data.dart';
import 'screens.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ijlqgyvjqnrdinolekil.supabase.co',
    publishableKey: 'sb_publishable_7krO34CKxmKQxdYeQwtbxQ_DOnd1xrG',
  );

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
