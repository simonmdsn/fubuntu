import 'dart:collection';

import 'package:dart_eval/dart_eval.dart';
import 'package:file/file.dart';
import 'package:flutter/material.dart';
import 'package:fubuntu/apps/terminal/nano.dart';
import 'package:fubuntu/fs/fs.dart';

import '../terminal.dart';

class TerminalCommands {
  static List<TerminalCommand> commands = [
    LS(),
    MKDIR(),
    NANO(),
    CAT(),
    CD(),
    PWD(),
    ECHO(),
    SLEEP(),
    DART(),
  ];
}

abstract class TerminalCommand {
  final String command;

  TerminalCommand({required this.command});

  Stream<TextSpan> run(
      String command, List<String> args, ListQueue<Widget> overlays, TerminalState state);
}

class NotFoundCommand extends TerminalCommand {
  NotFoundCommand() : super(command: "");

  @override
  Stream<TextSpan> run(
      String command, List<String> args, ListQueue<Widget> overlays, TerminalState state) async* {
    yield TextSpan(
        text: "$command: command not found", style: const TextStyle(color: Colors.white));
  }
}

class LS extends TerminalCommand {
  LS() : super(command: "ls");

  @override
  Stream<TextSpan> run(
      String command, List<String> args, ListQueue<Widget> overlays, TerminalState state) async* {
    var listSync = state.cwd.listSync();
    yield TextSpan(
        text: listSync.map((e) => e.basename).join("\n"),
        style: const TextStyle(color: Colors.white));
  }
}

class MKDIR extends TerminalCommand {
  MKDIR() : super(command: "mkdir");

  @override
  Stream<TextSpan> run(
      String command, List<String> args, ListQueue<Widget> overlays, TerminalState state) async* {
    var childDirectory = state.cwd.childDirectory(args.first);
    childDirectory.create();
    yield const TextSpan(text: "");
  }
}

class NANO extends TerminalCommand {
  NANO() : super(command: "nano");

  @override
  Stream<TextSpan> run(
      String command, List<String> args, ListQueue<Widget> overlays, TerminalState state) async* {
    overlays.add(Nano(state, file: FS.fileSystem.file(state.cwd.path + args.first),));
    yield const TextSpan(text: "");
  }
}

class CAT extends TerminalCommand {
  CAT() : super(command: "cat");

  @override
  Stream<TextSpan> run(
      String command, List<String> args, ListQueue<Widget> overlays, TerminalState state) async* {
    var childFile = state.cwd.childFile(args.first);
    try {
      yield TextSpan(
          text: childFile.readAsStringSync(), style: const TextStyle(color: Colors.white));
    } on FileSystemException catch (e, _) {
      yield TextSpan(
          text: "$command: ${args.first}: ${e.message}",
          style: const TextStyle(color: Colors.white));
    }
  }
}

class CD extends TerminalCommand {
  CD() : super(command: "cd");

  @override
  Stream<TextSpan> run(
      String command, List<String> args, ListQueue<Widget> overlays, TerminalState state) async* {
    var newDir = FS.fileSystem.directory(state.cwd.path);
    var split = args.first.split("/");
    bool exists = true;
    for (var element in split) {
      if (exists == false) {
        break;
      }
      switch (element) {
        case ".":
          break;
        case "..":
          newDir = newDir.parent;
          break;
        default:
          newDir = FS.fileSystem
              .directory("${newDir.path == "/" ? newDir.path : "${newDir.path}/"}$element");
          var existsSync = newDir.existsSync();
          exists = existsSync;
          break;
      }
    }
    if (exists) {
      state.changeCWD(newDir);
      yield const TextSpan(text: "");
      return;
    }
    yield TextSpan(
        text: "cd: ${args.first}: No such directory", style: const TextStyle(color: Colors.white));
  }
}

class PWD extends TerminalCommand {
  PWD() : super(command: "pwd");

  @override
  Stream<TextSpan> run(
      String command, List<String> args, ListQueue<Widget> overlays, TerminalState state) async* {
    yield TextSpan(text: state.cwd.path, style: const TextStyle(color: Colors.white));
  }
}

class ECHO extends TerminalCommand {
  ECHO() : super(command: "echo");

  @override
  Stream<TextSpan> run(
      String command, List<String> args, ListQueue<Widget> overlays, TerminalState state) async* {
    yield TextSpan(text: args.join(" "), style: const TextStyle(color: Colors.white));
  }
}

class SLEEP extends TerminalCommand {
  SLEEP() : super(command: "sleep");

  @override
  Stream<TextSpan> run(
      String command, List<String> args, ListQueue<Widget> overlays, TerminalState state) async* {
    await Future.delayed(Duration(seconds: int.parse(args.first)));
    yield TextSpan(
        text: "slept for  ${args.first} seconds", style: const TextStyle(color: Colors.white));
  }
}

class DART extends TerminalCommand {
  DART() : super(command: "dart");

  @override
  Stream<TextSpan> run(
      String command, List<String> args, ListQueue<Widget> overlays, TerminalState state) async* {
    if (FS.fileSystem.isFileSync(state.cwd.path + args.first)) {
      yield TextSpan(
          text: eval(
            FS.fileSystem.file(state.cwd.path + args.first).readAsStringSync(),
          ).toString(),
          style: const TextStyle(color: Colors.white));
      return;
    }
    yield TextSpan(
        text: eval(
          args.first,
        ).toString(),
        style: const TextStyle(color: Colors.white));
  }
}

