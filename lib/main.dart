import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'screens/login_page.dart';
import 'screens/navigation_bar.dart';
import 'utils/data_manager.dart';
import 'utils/food_list.dart';
import 'utils/shared_prefs.dart';

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
      home: loggedInUser != null
          ? MainScreen(email: loggedInUser!.email)
          : LoginPage(),
    );
  }
}
