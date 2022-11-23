import 'dart:collection';

import 'package:flutter/material.dart';

class Drawing with ListMixin<Offset> {
  final List<Offset> points;
  final double size;
  final Color color;

  Drawing({required this.points, required this.size, required this.color, length = 0});


  @override
  int get length => points.length;

  @override
  Offset operator [](int index) {
    return points[index];
  }

  @override
  void operator []=(int index, Offset value) {
    points[index] = value;
  }

  @override
  set length(int newLength) {
    length = points.length;
  }
}
