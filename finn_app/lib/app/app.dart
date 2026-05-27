import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes.dart';
import 'theme.dart';
import 'theme_provider.dart';

class FinanzasApp extends StatelessWidget {
  const FinanzasApp({super.key});

  @override
  Widget build(BuildContext ctx) {
    final themeProvider = Provider.of<ThemeProvider>(ctx);
    
    return MaterialApp.router(
      title: 'FinanzasApp',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: FinanzasTheme.light(),
      darkTheme: FinanzasTheme.dark(),
      routerConfig: router,
    );
  }
}
