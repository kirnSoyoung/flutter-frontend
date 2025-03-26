import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'main_page.dart';
import 'history_page.dart';
import 'supplement_page.dart';
import 'profile_page.dart';

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
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  CustomBottomNavigation({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(
            icon: Icon(currentIndex == 0
                ? Icons.camera_alt
                : Icons.camera_alt_outlined),
            label: '메인',
          ),
          BottomNavigationBarItem(
            icon: Icon(currentIndex == 1
                ? Icons.calendar_month
                : Icons.calendar_month_outlined),
            label: '식단 기록',
          ),
          BottomNavigationBarItem(
            icon: Icon(currentIndex == 2
                ? Icons.medication
                : Icons.medication_outlined),
            label: '영양제',
          ),
          BottomNavigationBarItem(
            icon: Icon(currentIndex == 3
                ? Icons.person
                : Icons.person_outline),
            label: '마이페이지',
          ),
        ],
      ),
    );
  }
}
