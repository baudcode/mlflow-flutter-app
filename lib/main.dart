import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/settings_page.dart';
import 'providers/experiment_provider.dart';
import 'providers/metric_provider.dart';
import 'providers/run_provider.dart';
import 'screens/home_screen.dart';

class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(final SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(); // Define navigatorKey globally

void main() {
  HttpOverrides.global = DevHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExperimentProvider()),
        ChangeNotifierProvider(create: (_) => RunProvider()),
        ChangeNotifierProvider(create: (_) => MetricProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey, // Use the global navigatorKey
        title: 'MLFlow Explorer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
            secondary: Colors.blueAccent,
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: false,
          ),
          cardTheme: CardTheme(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
            secondary: Colors.blueAccent,
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: false,
          ),
          cardTheme: CardTheme(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
        routes: {
          '/settings': (context) => const SettingsPage(),
        },
      ),
    );
  }
}
