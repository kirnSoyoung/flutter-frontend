import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../utils/shared_prefs.dart';
import '../utils/api_service.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/custom_labeled_dropdown.dart';

class EditProfilePage extends StatefulWidget {
  final User user;
  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController ageController;
  late TextEditingController heightController;
  late TextEditingController weightController;
  late TextEditingController servingController;
  late String selectedGender;
  late String selectedActivityLabel;

  final Map<String, double> activityLevelMap = {
    '일상적 생활만 한다': 1.2,
    '가벼운 운동을 주 1-3회': 1.5,
    '주 3-5일 운동을 한다(헬스)': 1.725,
    '강도높은 운동이나 육체노동': 1.9,
  };

  @override
  void initState() {
    super.initState();
    selectedGender = widget.user.gender;
    selectedActivityLabel = activityLevelMap.entries
        .firstWhere((e) => e.value == widget.user.activityLevel,
        orElse: () => const MapEntry("가벼운 운동을 주 1-3회", 1.5))
        .key;
    ageController = TextEditingController(text: widget.user.age.toString());
    heightController = TextEditingController(text: widget.user.height.toString());
    weightController = TextEditingController(text: widget.user.weight.toString());
    servingController = TextEditingController(text: widget.user.servingSize.toString());
  }

  Future<void> _saveUserData() async {
    User updatedUser = User(
      userId: widget.user.userId,
      gender: selectedGender,
      age: int.tryParse(ageController.text) ?? 20,
      height: double.tryParse(heightController.text) ?? 170.0,
      weight: double.tryParse(weightController.text) ?? 60.0,
      activityLevel: activityLevelMap[selectedActivityLabel] ?? 1.5,
      servingSize: double.tryParse(servingController.text) ?? 1.0,
    );
    await SharedPrefs.saveUser(updatedUser);
    await SharedPrefs.saveLoggedInUser(updatedUser);
    await ApiService.saveUserProfile(updatedUser);

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("사용자 정보가 저장되었습니다.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit, color: AppTheme.primaryColor, size: 20),
                    SizedBox(width: 6),
                    Text(
                      "정보 수정",
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CustomDropdown(
                      label: "성별",
                      value: selectedGender,
                      items: ["남성", "여성"],
                      onChanged: (value) => setState(() => selectedGender = value!),
                    ),
                    const SizedBox(height: 16),
                    CustomInputField(
                      label: "나이",
                      controller: ageController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    CustomInputField(
                      label: "키 (cm)",
                      controller: heightController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    CustomInputField(
                      label: "몸무게 (kg)",
                      controller: weightController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    CustomLabeledDropdown(
                      label: "활동 수준",
                      value: selectedActivityLabel,
                      items: {
                        for (var entry in activityLevelMap.entries)
                          entry.key: "활동량: ${entry.key}"
                      },
                      onChanged: (value) => setState(() => selectedActivityLabel = value!),
                    ),
                    const SizedBox(height: 16),
                    CustomInputField(
                      label: "기본 인분 수",
                      controller: servingController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveUserData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("저장하기", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
