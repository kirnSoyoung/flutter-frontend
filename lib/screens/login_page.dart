import 'package:flutter/material.dart';
import 'signup_page.dart';
import '../utils/shared_prefs.dart';
import '../models/user_model.dart';
import 'navigation_bar.dart';

/// 사용자가 로그인할 수 있는 페이지
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController(); // 이메일 입력 컨트롤러
  final TextEditingController passwordController = TextEditingController(); // 비밀번호 입력 컨트롤러
  String errorMessage = ""; // 로그인 실패 메시지

  /// 로그인 처리 함수
  Future<void> login() async {
    List<User> users = await SharedPrefs.getUsers(); // 저장된 사용자 목록 가져오기
    for (var user in users) {
      if (user.email == emailController.text && user.password == passwordController.text) {
        await SharedPrefs.saveLoginInfo(user.email, user.password); // 자동 로그인 정보 저장

        // 로그인 성공 시 메인 화면으로 이동 (이전 화면 제거)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainScreen(email: user.email)),
              (route) => false,
        );
        return;
      }
    }
    // 로그인 실패 시 에러 메시지 표시
    setState(() {
      errorMessage = "이메일 또는 비밀번호가 잘못되었습니다.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("로그인")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 이메일 입력 필드
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "이메일"),
            ),

            // 비밀번호 입력 필드
            TextField(
              controller: passwordController,
              obscureText: true, // 비밀번호 숨김 처리
              decoration: InputDecoration(labelText: "비밀번호"),
            ),

            SizedBox(height: 10),

            // 로그인 실패 메시지 표시
            Text(errorMessage, style: TextStyle(color: Colors.red)),

            SizedBox(height: 10),

            // 로그인 버튼
            ElevatedButton(
              onPressed: login,
              child: Text("로그인"),
            ),

            // 회원가입 페이지로 이동 버튼
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignupPage()),
                );
              },
              child: Text("회원가입하기"),
            ),
          ],
        ),
      ),
    );
  }
}
