import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../utils/shared_prefs.dart';

/// 사용자가 회원가입을 할 수 있는 페이지
class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = ""; // 오류 메시지 표시

  String selectedGender = "남성"; // 기본 성별
  int age = 20; // 기본 나이
  double height = 170.0; // 기본 키 (cm)
  double weight = 60.0; // 기본 몸무게 (kg)
  String activityLevel = "보통"; // 기본 활동 수준

  /// 이메일 형식 검사
  bool isValidEmail(String email) => email.contains('@') && email.contains('.');

  /// 비밀번호 유효성 검사 (최소 5자, 영어+숫자 포함)
  bool isValidPassword(String password) =>
      password.length >= 5 &&
          RegExp(r'[a-zA-Z]').hasMatch(password) &&
          RegExp(r'\d').hasMatch(password);

  /// 회원가입 처리 함수
  Future<void> register() async {
    if (!isValidEmail(emailController.text)) {
      setState(() => errorMessage = "올바른 이메일 형식이 아닙니다.");
      return;
    }
    if (!isValidPassword(passwordController.text)) {
      setState(() => errorMessage = "비밀번호는 5자 이상이며 영어와 숫자를 포함해야 합니다.");
      return;
    }

    // 사용자 정보 저장
    await SharedPrefs.saveUser(User(
      email: emailController.text,
      password: passwordController.text,
      gender: selectedGender,
      age: age,
      height: height,
      weight: weight,
      activityLevel: activityLevel,
    ));

    // 회원가입 완료 후 로그인 페이지로 이동
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("회원가입")),
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

            // 성별 선택 드롭다운
            DropdownButton<String>(
              value: selectedGender,
              onChanged: (newValue) => setState(() => selectedGender = newValue!),
              items: ["남성", "여성"]
                  .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
            ),

            // 나이 입력 필드
            TextField(
              decoration: InputDecoration(labelText: "나이"),
              keyboardType: TextInputType.number,
              onChanged: (value) => age = int.tryParse(value) ?? 20,
            ),

            // 키 입력 필드
            TextField(
              decoration: InputDecoration(labelText: "키 (cm)"),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => height = double.tryParse(value) ?? 170.0,
            ),

            // 몸무게 입력 필드
            TextField(
              decoration: InputDecoration(labelText: "몸무게 (kg)"),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => weight = double.tryParse(value) ?? 60.0,
            ),

            // 활동 수준 선택 드롭다운
            DropdownButton<String>(
              value: activityLevel,
              onChanged: (newValue) => setState(() => activityLevel = newValue!),
              items: [
                DropdownMenuItem(value: "낮음", child: Text("활동량: 낮음 (거의 운동 안 함)")),
                DropdownMenuItem(value: "보통", child: Text("활동량: 보통 (주 1~2회 가벼운 운동)")),
                DropdownMenuItem(value: "높음", child: Text("활동량: 높음 (주 3회 이상 운동)")),
              ],
            ),

            SizedBox(height: 10),

            // 오류 메시지 표시
            Text(errorMessage, style: TextStyle(color: Colors.red)),

            SizedBox(height: 10),

            // 회원가입 버튼
            ElevatedButton(
              onPressed: register,
              child: Text("회원가입"),
            ),
          ],
        ),
      ),
    );
  }
}
