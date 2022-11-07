import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter/foundation.dart';

class FS {
  static final _fs = MemoryFileSystem();
  static final List<VoidCallback> _toDoOnStart = [];
  static bool _loaded = false;

  static FileSystem get fileSystem => _fs;

  static void init() {
    if (_loaded) {
      throw Exception("TODO - Dont run filesystem init twice");
    }
    var root = _fs.directory("/");
    var homeDir = root.childDirectory('home');
    homeDir.create();
    var user = homeDir.childDirectory('root');
    user.create();
    var versionFile = root.childFile('version');
    versionFile.writeAsString("1.0.0");

    root.childFile('meow.dart').writeAsString('''
class Cat {
  Cat(this.name);
  final String name;
  String speak() {
    return name;
  }
}
String main() {
  final cat = Cat('Fluffy');
  return cat.speak();
}
      ''');

    for (var value in _toDoOnStart) {
      value.call();
    }
    _loaded = true;
  }

  static void addOnStart(VoidCallback voidCallback) {
    _toDoOnStart.add(voidCallback);
  }
}
