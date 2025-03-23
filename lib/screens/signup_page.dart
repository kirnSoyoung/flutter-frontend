import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../utils/shared_prefs.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_labeled_dropdown.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  String selectedGender = "남성";
  String activityLevel = "보통";
  String errorMessage = "";

  bool isValidEmail(String email) => email.contains('@') && email.contains('.');
  bool isValidPassword(String password) =>
      password.length >= 5 &&
          RegExp(r'[a-zA-Z]').hasMatch(password) &&
          RegExp(r'\d').hasMatch(password);

  Future<void> register() async {
    if (!isValidEmail(emailController.text)) {
      setState(() => errorMessage = "올바른 이메일 형식이 아닙니다.");
      return;
    }
    if (!isValidPassword(passwordController.text)) {
      setState(() => errorMessage = "비밀번호는 5자 이상이며 영어와 숫자를 포함해야 합니다.");
      return;
    }

    await SharedPrefs.saveUser(User(
      email: emailController.text,
      password: passwordController.text,
      gender: selectedGender,
      age: int.tryParse(ageController.text) ?? 20,
      height: double.tryParse(heightController.text) ?? 170.0,
      weight: double.tryParse(weightController.text) ?? 60.0,
      activityLevel: activityLevel,
    ));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("회원가입")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              CustomInputField(
                label: "이메일",
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 10),
              CustomInputField(
                label: "비밀번호",
                controller: passwordController,
                isPassword: true,
              ),
              SizedBox(height: 10),
              CustomDropdown(
                label: "성별",
                value: selectedGender,
                items: ["남성", "여성"],
                onChanged: (value) => setState(() => selectedGender = value!),
              ),
              SizedBox(height: 10),
              CustomInputField(
                label: "나이",
                controller: ageController,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              CustomInputField(
                label: "키 (cm)",
                controller: heightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 10),
              CustomInputField(
                label: "몸무게 (kg)",
                controller: weightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 10),
              CustomLabeledDropdown(
                label: "활동 수준",
                value: activityLevel,
                items: {
                  "낮음": "활동량: 낮음 (거의 운동 안 함)",
                  "보통": "활동량: 보통 (주 1~2회 가벼운 운동)",
                  "높음": "활동량: 높음 (주 3회 이상 운동)",
                },
                onChanged: (value) => setState(() => activityLevel = value!),
              ),
              SizedBox(height: 10),
              Text(errorMessage, style: TextStyle(color: Colors.red)),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: register,
                child: Text("회원가입"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
