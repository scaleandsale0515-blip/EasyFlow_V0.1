import 'package:flutter/material.dart';
import 'services/hive_service.dart';
import 'services/auth_service.dart';
import 'utils/app_theme.dart';
import 'screens/auth/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await AuthService.ensureInitialized();
  runApp(const EasyFlowApp());
}

class EasyFlowApp extends StatelessWidget {
  const EasyFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const LockScreen(),
    );
  }
}
