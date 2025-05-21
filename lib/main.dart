import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'screens/navigation_bar.dart';
import 'screens/onboarding_page.dart';
import 'utils/data_manager.dart';
import 'utils/food_list.dart';
import 'utils/shared_prefs.dart';

import 'theme/app_theme.dart';
import '../models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  await saveFoodList();

  User? loggedInUser = await SharedPrefs.getLoggedInUser();

  DataManager dataManager = DataManager();
  await dataManager.loadMeals();

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
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: loggedInUser != null
          ? MainScreen()
          : OnboardingPage(),
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Material(
            child: Container(
              color: Colors.white,
              child: Center(
                child: Text(
                  '앱을 다시 실행해주세요.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          );
        };
        return child ?? Container();
      },
    );
  }
}
