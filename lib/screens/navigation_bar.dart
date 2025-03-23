import 'package:flutter/material.dart';

import 'history_page.dart';
import 'main_page.dart';
import 'profile_page.dart';
import 'supplement_page.dart';

class MainScreen extends StatefulWidget {
  final String email;

  MainScreen({required this.email});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(widget.email),
      HistoryPage(),
      SupplementPage(),
      ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: "메인"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "식단 기록"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "영양제"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "마이 페이지"),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[500],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
