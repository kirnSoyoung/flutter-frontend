import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../utils/shared_prefs.dart';
import '../utils/api_service.dart';
import '../theme/app_theme.dart';
import 'navigation_bar.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController userIdController = TextEditingController();
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
    "낮음": "활동량: 낮음 (일상적 생활만 함)",
    "보통": "활동량: 보통 (주 1-3회 가벼운 운동)",
    "높음": "활동량: 높음 (주 3-5 일 운동(헬스))",
    "매우 높음": "활동량: 매우 높음 (강도높은 운동이나 육체노동)",
  };

  final Map<String, double> activityLevelFactors = {
    "낮음": 1.2,
    "보통": 1.5,
    "높음": 1.725,
    "매우 높음": 1.9,
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
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              if (currentStep > 0) {
                setState(() => currentStep--);
              } else {
                Navigator.pop(context);
              }
            },
            padding: EdgeInsets.zero,
          ),
          SizedBox(width: 16),
          Text("회원가입", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                color: currentStep >= index ? AppTheme.primaryColor : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (currentStep) {
      case 0: return _buildPhysicalInfo();
      case 1: return _buildActivityInfo();
      case 2: return _buildAccountInfo();
      default: return Container();
    }
  }

  Widget _buildAccountInfo() {
    return Column(
      children: [
        _buildInputField(userIdController, "아이디", "사용할 아이디를 입력해주세요", Icons.person_outline, TextInputType.text, true,
        ),
        if (errorMessage.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(errorMessage, style: TextStyle(color: Colors.red)),
          ),
        SizedBox(height: 32),
        _buildNextButton("가입 완료"),
      ],
    );
  }

  Widget _buildPhysicalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGenderSelection(),
        SizedBox(height: 20),
        _buildInputField(ageController, "나이", "나이를 입력해주세요", Icons.calendar_today, TextInputType.number),
        SizedBox(height: 20),
        _buildInputField(heightController, "키 (cm)", "키를 입력해주세요", Icons.height, TextInputType.number),
        SizedBox(height: 20),
        _buildInputField(weightController, "몸무게 (kg)", "몸무게를 입력해주세요", Icons.fitness_center, TextInputType.number),
        if (errorMessage.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(errorMessage, style: TextStyle(color: Colors.red)),
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
        _buildInputField(servingController, "기본 인분 수", "예: 1.0", Icons.dining, TextInputType.number),
        SizedBox(height: 16),
        Text("평소 본인의 한 끼 기준으로 인분 수치를 알려주세요!", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        SizedBox(height: 24),
        Text(
          "활동량",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        ...activityLevels.entries.map((e) => _buildActivityOption(e.key, e.value)).toList(),
        SizedBox(height: 32),
        _buildNextButton("다음"),
      ],
    );
  }

  Widget _buildInputField(
      TextEditingController controller, String label, String hint, IconData icon, [TextInputType? keyboardType, bool isUserId = false]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: TextCapitalization.none,
            inputFormatters: isUserId
                ? [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]'))]
                : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(icon, color: AppTheme.primaryColor),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        Text("성별", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey[400]!),
              ),
              child: isSelected ? Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
            SizedBox(width: 12),
            Expanded(child: Text(description, style: TextStyle(fontSize: 14))),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton(String text) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _handleNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _handleNext() async {
    FocusScope.of(context).unfocus(); // 모든 TextField의 포커스를 해제

    if (currentStep < 2) {
      setState(() => currentStep++);
    } else {
      await _register();
    }
  }


  Future<void> _register() async {
    try {
      final userId = userIdController.text.trim();
      if (userId.isEmpty)
      {
        setState(() => errorMessage = "아이디를 입력해주세요");
        return;
        }


        final user = User(
        userId: userId,
          gender: selectedGender,
          age: int.parse(ageController.text),
          height: double.parse(heightController.text),
          weight: double.parse(weightController.text),
          activityLevel: activityLevelFactors[activityLevel] ?? 1.5,
          servingSize: double.tryParse(servingController.text) ?? 1.0,
        );

        final success = await ApiService.registerUser(user);
        if (!success) {
          setState(() => errorMessage = "이미 사용 중인 아이디입니다");
          return;
        }

        await SharedPrefs.saveUser(user);
        await SharedPrefs.saveLoggedInUser(user);

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MainScreen(),
          ),
              (route) => false,
        );
      } catch (e) {
      print("❌ 회원가입 오류: $e");
      setState(() => errorMessage = "회원가입 중 오류가 발생했습니다");
    }
  }
}