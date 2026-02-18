import 'package:flutter/material.dart';
import 'package:kartaski_blok/games_list.dart';
import 'package:kartaski_blok/remi_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  final String title = 'Kartaški blok';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red).copyWith(surface: Colors.white),
        useMaterial3: true,
      ),
      home: GamesListPage(storage: RemiStorage()),
    );
  }
}