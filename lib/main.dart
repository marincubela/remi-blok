import 'package:flutter/material.dart';
import 'package:remi_blok/remi.dart';
import 'package:remi_blok/remi_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remi Blok',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: RemiPage(title: 'Remi blok - Dobro došli!', storage: RemiStorage()),
    );
  }
}