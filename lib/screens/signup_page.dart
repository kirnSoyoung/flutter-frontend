import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../utils/shared_prefs.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';

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
  final TextEditingController servingController = TextEditingController();

  String selectedGender = "남성";
  String activityLevel = "보통";
  String errorMessage = "";
  int currentStep = 0;

  final List<String> genders = ["남성", "여성"];
  final Map<String, String> activityLevels = {
    "낮음": "활동량: 낮음 (거의 운동 안 함)",
    "보통": "활동량: 보통 (주 1~2회 가벼운 운동)",
    "높음": "활동량: 높음 (주 3회 이상 운동)",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: _buildCurrentStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  if (currentStep > 0) {
                    setState(() {
                      currentStep--;
                    });
                  } else {
                    Navigator.pop(context);
                  }
                },
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
              SizedBox(width: 16),
              Text(
                "회원가입",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _getStepDescription(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(
          3,
              (index) => Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: currentStep >= index
                    ? AppTheme.primaryColor
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getStepDescription() {
    switch (currentStep) {
      case 0:
        return "계정 정보를 입력해주세요";
      case 1:
        return "신체 정보를 입력해주세요";
      case 2:
        return "활동량 정보를 입력해주세요";
      default:
        return "";
    }
  }

  Widget _buildCurrentStep() {
    switch (currentStep) {
      case 0:
        return _buildAccountInfo();
      case 1:
        return _buildPhysicalInfo();
      case 2:
        return _buildActivityInfo();
      default:
        return Container();
    }
  }

  Widget _buildAccountInfo() {
    return Column(
      children: [
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
          hint: "비밀번호를 입력해주세요",
          isPassword: true,
          icon: Icons.lock_outline,
        ),
        if (errorMessage.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.red),
            ),
          ),
        SizedBox(height: 32),
        _buildNextButton("다음"),
      ],
    );
  }

  Widget _buildPhysicalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGenderSelection(),
        SizedBox(height: 20),
        _buildInputField(
          controller: ageController,
          label: "나이",
          hint: "나이를 입력해주세요",
          icon: Icons.calendar_today,
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 20),
        _buildInputField(
          controller: heightController,
          label: "키 (cm)",
          hint: "키를 입력해주세요",
          icon: Icons.height,
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 20),
        _buildInputField(
          controller: weightController,
          label: "몸무게 (kg)",
          hint: "몸무게를 입력해주세요",
          icon: Icons.fitness_center,
          keyboardType: TextInputType.number,
        ),
        if (errorMessage.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.red),
            ),
          ),
        SizedBox(height: 32),
        _buildNextButton("다음"),
      ],
    );
  }

  Widget _buildActivityInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "활동량",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 20),
        _buildInputField(
          controller: servingController,
          label: "기본 인분 수",
          hint: "예: 1.0",
          icon: Icons.dining,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        ),
        SizedBox(height: 16),
        ...activityLevels.entries.map((entry) => _buildActivityOption(entry.key, entry.value)).toList(),
        SizedBox(height: 32),
        _buildNextButton("가입 완료"),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
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
            keyboardType: keyboardType,
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

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "성별",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: genders.map((gender) {
            bool isSelected = selectedGender == gender;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => selectedGender = gender),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    gender,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActivityOption(String level, String description) {
    bool isSelected = activityLevel == level;
    return GestureDetector(
      onTap: () => setState(() => activityLevel = level),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                description,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton(String text) {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _handleNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _handleNext() async {
    if (currentStep == 0) {
      if (_validateAccountInfo()) {
        setState(() => currentStep = 1);
      }
    } else if (currentStep == 1) {
      if (_validatePhysicalInfo()) {
        setState(() => currentStep = 2);
      }
    } else {
      await _register();
    }
  }

  bool _validateAccountInfo() {
    if (!emailController.text.contains('@')) {
      setState(() => errorMessage = "올바른 이메일 형식이 아닙니다");
      return false;
    }
    if (passwordController.text.length < 5) {
      setState(() => errorMessage = "비밀번호는 5자 이상이어야 합니다");
      return false;
    }
    setState(() => errorMessage = "");
    return true;
  }

  bool _validatePhysicalInfo() {
    if (ageController.text.isEmpty ||
        heightController.text.isEmpty ||
        weightController.text.isEmpty) {
      setState(() => errorMessage = "모든 정보를 입력해주세요");
      return false;
    }
    setState(() => errorMessage = "");
    return true;
  }

  Future<void> _register() async {
    print("📦 회원가입 시도 중");
    try {
      User newUser = User(
        email: emailController.text,
        password: passwordController.text,
        gender: selectedGender,
        age: int.parse(ageController.text),
        height: double.parse(heightController.text),
        weight: double.parse(weightController.text),
        activityLevel: activityLevel,
        servingSize: double.tryParse(servingController.text) ?? 1.0, // ✅ 추가

      );

      List<User> users = await SharedPrefs.getUsers();
      if (users.any((user) => user.email == newUser.email)) {
        setState(() => errorMessage = "이미 등록된 이메일입니다");
        return;
      }

      await SharedPrefs.saveUser(newUser);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => LoginPage(),
        ),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      print("Registration error: $e");
      setState(() => errorMessage = "회원가입 중 오류가 발생했습니다");
    }
  }
}
