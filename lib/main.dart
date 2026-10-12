import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

void main() {
  runApp(const StudentExpenseTrackerApp());
}

class StudentExpenseTrackerApp extends StatelessWidget {
  const StudentExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Expense Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}