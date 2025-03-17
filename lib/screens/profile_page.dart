import 'package:flutter/material.dart';
import '../utils/shared_prefs.dart';
import '../models/user_model.dart';
import 'login_page.dart';

/// 사용자가 자신의 정보를 확인하고 수정할 수 있는 페이지
class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController ageController;
  late TextEditingController heightController;
  late TextEditingController weightController;
  String selectedGender = "남성"; // 기본 성별
  String activityLevel = "보통"; // 기본 활동 수준
  bool isLoading = true; // 사용자 정보 로딩 상태

  @override
  void initState() {
    super.initState();
    ageController = TextEditingController();
    heightController = TextEditingController();
    weightController = TextEditingController();
    _loadUserData(); // 저장된 사용자 정보 불러오기
  }

  /// 저장된 사용자 정보를 불러와 입력 필드에 설정하는 함수
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

  /// 수정된 사용자 정보를 저장하는 함수
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
      _loadUserData(); // 저장 후 UI 갱신

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("사용자 정보가 업데이트되었습니다.")),
      );
    }
  }

  /// 로그아웃 기능 (저장된 로그인 정보 삭제 후 로그인 페이지로 이동)
  Future<void> _logout() async {
    await SharedPrefs.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false, // 기존 모든 화면 제거 후 로그인 페이지로 이동
    );
  }

  @override
  Widget build(BuildContext context) {
    // 사용자 정보가 로딩 중일 경우 로딩 화면 표시
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("마이 페이지")),
        body: Center(child: CircularProgressIndicator()), // 로딩 스피너 표시
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

            // 성별 선택 드롭다운
            DropdownButton<String>(
              value: selectedGender,
              onChanged: (newValue) => setState(() => selectedGender = newValue!),
              items: ["남성", "여성"].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
            ),

            // 나이 입력 필드
            TextField(
              controller: ageController,
              decoration: InputDecoration(labelText: "나이"),
              keyboardType: TextInputType.number,
            ),

            // 키 입력 필드
            TextField(
              controller: heightController,
              decoration: InputDecoration(labelText: "키 (cm)"),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),

            // 몸무게 입력 필드
            TextField(
              controller: weightController,
              decoration: InputDecoration(labelText: "몸무게 (kg)"),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
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

            SizedBox(height: 20),

            // 사용자 정보 저장 버튼
            Center(
              child: ElevatedButton(
                onPressed: _saveUserData,
                child: Text("저장"),
              ),
            ),

            SizedBox(height: 20),

            // 로그아웃 버튼
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
