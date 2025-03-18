import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'screens/login_page.dart';
import 'screens/navigation_bar.dart';
import 'utils/shared_prefs.dart';
import 'utils/data_manager.dart';
import 'utils/food_list.dart';
import '../models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  await saveFoodList();

  User? loggedInUser = await SharedPrefs.getLoggedInUser();

  // DataManager에서 저장된 식단 불러오기
  DataManager dataManager = DataManager();
  await dataManager.loadMeals(); // ✅ 앱 실행 시 기존 식단 데이터 불러오기

  runApp(
    ChangeNotifierProvider(
      create: (context) => dataManager,
      child: MyApp(loggedInUser: loggedInUser),
    ),
  );
}


// 앱의 최상위 위젯
class MyApp extends StatelessWidget {
  final User? loggedInUser;
  MyApp({this.loggedInUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 디버그 배너 제거
      home: loggedInUser != null
          ? MainScreen(email: loggedInUser!.email) // 자동 로그인 시 메인 화면 이동
          : LoginPage(), // 로그인 필요 시 로그인 페이지로 이동
    );
  }
}
