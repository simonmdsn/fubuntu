
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fubuntu/desktop.dart';
import 'package:fubuntu/fs/fs.dart';

void main() {
  FS.init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fubuntu',
      theme: ThemeData(
      ),
      home: const Desktop(),
    );
  }
}


