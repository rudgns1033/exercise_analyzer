// lib/screens/home_screen.dart

import 'package:flutter/material.dart';

import '../screens/home_tab_screen.dart';
import '../screens/goal_screen.dart';
import '../screens/record_screen.dart';
import '../screens/video_analysis_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 0: 홈, 1: 목표, 2: 기록, 3: AI 교정
  int _currentIndex = 0;

  // 각 탭에 보여줄 화면
  static const List<Widget> _pages = [
    HomeTabScreen(),
    GoalScreen(),
    RecordScreen(),
    VideoAnalysisScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 선택된 인덱스에 따라 화면 전환
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed, // 4개 이상일 때도 고정형
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: '목표',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: '기록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.videocam),
            label: 'AI 교정',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
