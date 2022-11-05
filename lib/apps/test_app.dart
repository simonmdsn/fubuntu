
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fubuntu/desktop.dart';

class TestApp extends Application {
  TestApp({super.key}) : super(focusNode: FocusNode(),icon: Icons.question_mark);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => TestAppState();
}

class TestAppState extends ConsumerState<TestApp> {
  bool i = true;
  String text = "Big test";
  final TextEditingController textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      child: Column(
        children: [
          Center(
            child: GestureDetector(
              onTap: () {
                i = !i;
                setState(() {
                  text = i ? "Test" : "Big Test";
                });
              },
              child: Text(text),
            ),
          ),
          TextField(
            controller: textEditingController,
          ),
        ],
      ),
    );
  }
}
