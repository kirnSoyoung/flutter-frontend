import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../utils/shared_prefs.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/custom_labeled_dropdown.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController ageController;
  late TextEditingController heightController;
  late TextEditingController weightController;
  String selectedGender = "남성";
  String activityLevel = "보통";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    ageController = TextEditingController();
    heightController = TextEditingController();
    weightController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = await SharedPrefs.getLoggedInUser();
    if (user != null) {
      setState(() {
        selectedGender = user.gender;
        activityLevel = user.activityLevel;
        ageController.text = user.age.toString();
        heightController.text = user.height.toString();
        weightController.text = user.weight.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _saveUserData() async {
    User? currentUser = await SharedPrefs.getLoggedInUser();
    if (currentUser != null) {
      User updatedUser = User(
        email: currentUser.email,
        password: currentUser.password,
        gender: selectedGender,
        age: int.tryParse(ageController.text) ?? 20,
        height: double.tryParse(heightController.text) ?? 170.0,
        weight: double.tryParse(weightController.text) ?? 60.0,
        activityLevel: activityLevel,
      );
      await SharedPrefs.saveUser(updatedUser);
      _loadUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("사용자 정보가 업데이트되었습니다.")),
      );
    }
  }

  Future<void> _logout() async {
    await SharedPrefs.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("마이 페이지")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("마이 페이지")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("사용자 정보 수정", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),

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
                "높음": "활동량: 높음 (주 3회 이상 운동)"
              },
              onChanged: (value) => setState(() => activityLevel = value!),
            ),
            SizedBox(height: 20),

            Center(
              child: ElevatedButton(
                onPressed: _saveUserData,
                child: Text("저장"),
              ),
            ),
            SizedBox(height: 20),

            Center(
              child: ElevatedButton(
                onPressed: _logout,
                child: Text("로그아웃"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}