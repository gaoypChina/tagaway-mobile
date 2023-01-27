// IMPORT FLUTTER PACKAGES
import 'package:flutter/material.dart';
import 'package:tagaway/views/deleteAccount.dart';
import 'package:tagaway/views/login_view.dart';
import 'package:tagaway/views/your_home_tags.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const YourHomeTagsView(),
      routes: {
        LoginScreen.id: (context) => const LoginScreen(),
        DeleteAccount.id: (context) => const DeleteAccount(),
      },
    );
  }
}
