import 'package:flutter/material.dart';
import 'goal_screen.dart';
import 'record_screen.dart';
import 'video_analysis_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _pages = const [
    GoalScreen(),
    RecordScreen(),
    VideoAnalysisScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: '목표'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '기록'),
          BottomNavigationBarItem(icon: Icon(Icons.videocam), label: 'AI 교정'),
        ],
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
