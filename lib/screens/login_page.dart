import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../utils/shared_prefs.dart';
import 'navigation_bar.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = "";

  /// 로그인 처리 함수
  Future<void> login() async {
    List<User> users = await SharedPrefs.getUsers();
    for (var user in users) {
      if (user.email == emailController.text && user.password == passwordController.text) {
        await SharedPrefs.saveLoginInfo(user.email, user.password);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainScreen(email: user.email)),
              (route) => false,
        );
        return;
      }
    }
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
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "이메일"),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "비밀번호"),
            ),
            SizedBox(height: 10),
            Text(errorMessage, style: TextStyle(color: Colors.red)),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: login,
              child: Text("로그인"),
            ),
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