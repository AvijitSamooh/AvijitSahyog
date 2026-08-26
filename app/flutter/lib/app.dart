import 'package:flutter/material.dart';

import 'features/home/home_page.dart';

class AvijitSahyogApp extends StatelessWidget {
  const AvijitSahyogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avijit Sahyog',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}