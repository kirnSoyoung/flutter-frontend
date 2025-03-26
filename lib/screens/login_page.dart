import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../utils/shared_prefs.dart';
import '../theme/app_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                Text(
                  "환영합니다!",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "건강한 식단 관리를 시작해보세요",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 60),
                _buildInputField(
                  controller: emailController,
                  label: "이메일",
                  hint: "example@email.com",
                  icon: Icons.email_outlined,
                ),
                SizedBox(height: 20),
                _buildInputField(
                  controller: passwordController,
                  label: "비밀번호",
                  hint: "비밀번호를 입력하세요",
                  isPassword: true,
                  icon: Icons.lock_outline,
                ),
                SizedBox(height: 16),
                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      errorMessage,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                SizedBox(height: 24),
                _buildLoginButton(),
                SizedBox(height: 20),
                _buildSignUpButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(icon, color: AppTheme.primaryColor),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          "로그인",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return Container(
      width: double.infinity,
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SignupPage(),
            ),
          );
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        child: RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 14),
            children: [
              TextSpan(
                text: "아직 계정이 없으신가요? ",
                style: TextStyle(color: Colors.black54),
              ),
              TextSpan(
                text: "회원가입",
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    try {
      List<User> users = await SharedPrefs.getUsers();
      for (var user in users) {
        if (user.email == emailController.text &&
            user.password == passwordController.text) {
          await SharedPrefs.saveLoginInfo(user.email, user.password);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(email: user.email),
            ),
                (route) => false,
          );
          return;
        }
      }
      setState(() {
        errorMessage = "이메일 또는 비밀번호가 올바르지 않습니다.";
      });
    } catch (e) {
      setState(() {
        errorMessage = "로그인 중 오류가 발생했습니다.";
      });
    }
  }
}
