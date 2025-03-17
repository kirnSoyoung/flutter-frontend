import 'package:flutter/material.dart';

/// 영양제 추천 페이지 (현재 개발 중)
class SupplementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("영양제 추천")),
      body: Center(
        child: Text(
          "개발 중입니다.",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ),
    );
  }
}
