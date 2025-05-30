import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../utils/shared_prefs.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await SharedPrefs.getLoggedInUser();
    setState(() {
      currentUser = user;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 24),
              _buildTitle(),
              const SizedBox(height: 24),
              _buildProfileCard(),
              const SizedBox(height: 24),
              if (currentUser != null) _buildUserInfo(),
              const SizedBox(height: 24),
              _buildActionItem(Icons.edit, "정보 수정", onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(user: currentUser!),
                  ),
                ).then((_) => _loadUser());
              }),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text(
              "마이페이지",
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
            child: Icon(Icons.person, color: AppTheme.primaryColor, size: 32),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "사용자 ID",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 4),
              Text(
                currentUser?.userId ?? "알 수 없음",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildInfoRow("키", "${currentUser!.height.toStringAsFixed(1)} cm"),
          _buildInfoRow("몸무게", "${currentUser!.weight.toStringAsFixed(1)} kg"),
          _buildInfoRow("목표 섭취 칼로리", "${_calculateTargetCalories(currentUser!)} kcal"),
          _buildInfoRow("성별", currentUser!.gender),
          _buildInfoRow("나이", "${currentUser!.age}세"),
          _buildInfoRow("활동량", currentUser!.activityLevel.toString()),
          _buildInfoRow("기본 인분 수", "${currentUser!.servingSize.toStringAsFixed(1)} 인분"),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 16, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateTargetCalories(User user) {
    double bmr;
    if (user.gender == "남성") {
      bmr = 10 * user.weight + 6.25 * user.height - 5 * user.age + 5;
    } else {
      bmr = 10 * user.weight + 6.25 * user.height - 5 * user.age - 161;
    }

    return (bmr * user.activityLevel).round(); // activityLevel은 숫자(double)
  }
}
