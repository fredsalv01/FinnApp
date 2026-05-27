import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme.dart';

class FinanzasApp extends StatelessWidget {
  const FinanzasApp({super.key});

  @override
  Widget build(BuildContext ctx) {
    return MaterialApp.router(
      title: 'FinanzasApp',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: FinanzasTheme.light(),
      darkTheme: FinanzasTheme.dark(),
      routerConfig: router,
    );
  }
}
