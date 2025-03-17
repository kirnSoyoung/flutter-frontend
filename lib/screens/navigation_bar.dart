import 'package:flutter/material.dart';
import 'main_page.dart';
import 'history_page.dart';
import 'supplement_page.dart';
import 'profile_page.dart';

/// 앱의 메인 화면 (하단 네비게이션 바 포함)
class MainScreen extends StatefulWidget {
  final String email; // 로그인한 사용자의 이메일

  MainScreen({required this.email});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // 현재 선택된 탭 인덱스
  late final List<Widget> _pages; // 네비게이션 바에 연결된 페이지 리스트

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(widget.email), // 메인 페이지 (사진 촬영 및 영양소 분석)
      HistoryPage(), // 식단 기록 페이지
      SupplementPage(), // 영양제 추천 페이지
      ProfilePage(), // 마이 페이지 (사용자 정보 관리)
    ];
  }

  /// 네비게이션 바에서 탭을 선택할 때 호출되는 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // 선택된 페이지 표시
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: "메인"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "식단 기록"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "영양제"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "마이 페이지"),
        ],
        currentIndex: _selectedIndex, // 현재 선택된 인덱스 반영
        onTap: _onItemTapped, // 탭 클릭 시 페이지 변경
        backgroundColor: Colors.black, // 네비게이션 바 배경색
        selectedItemColor: Colors.white, // 선택된 아이템 색상
        unselectedItemColor: Colors.grey[500], // 선택되지 않은 아이템 색상
        type: BottomNavigationBarType.fixed, // 네비게이션 바 아이템 크기 고정
      ),
    );
  }
}
