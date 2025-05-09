import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/user_provider.dart';
import 'screens/user_setup_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // TODO: PlanProvider, RecordProvider 등 추가
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exercise Analyzer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const UserSetupScreen(),
      routes: {
        '/home': (_) => const HomeScreen(),
        // TODO: '/goal': (_) => const GoalScreen(), ...
      },
    );
  }
}
