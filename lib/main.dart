import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/user_provider.dart';
import 'providers/plan_provider.dart';
import 'providers/record_provider.dart';

import 'screens/start_screen.dart';
import 'screens/user_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/goal_screen.dart';
import 'screens/record_screen.dart';
import 'screens/video_analysis_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PlanProvider()),
        ChangeNotifierProvider(create: (_) => RecordProvider()),
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

      home: const StartScreen(),
      routes: {
        '/start'      : (_) => const StartScreen(),
        '/user_setup' : (_) => const UserSetupScreen(),
        '/home'       : (_) => const HomeScreen(),
        '/goal'       : (_) => const GoalScreen(),
        '/record'     : (_) => const RecordScreen(),
        '/ai'         : (_) => const VideoAnalysisScreen(),
      },
    );
  }
}
