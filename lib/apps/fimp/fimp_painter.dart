import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'drawing.dart';

class FimpPainter extends CustomPainter {
  List<Drawing> drawings;

  final TextPainter textPainter = TextPainter(
    text: const TextSpan(text: "Hello, world!",style: TextStyle(color: Colors.black)),
    textDirection: TextDirection.ltr,
  );

  FimpPainter(this.drawings);

  @override
  void paint(Canvas canvas, Size size) {
    textPainter.layout(minWidth: 0, maxWidth:size.width);
    textPainter.paint(canvas, Offset(10, 10));
    for (var drawing in drawings) {
      for (var i = 0; i < drawing.length - 1; i++) {
        var path = Path();
        path.moveTo(drawing[0].dx, drawing[0].dy);

        if (drawing.length < 2) {
          path.addOval(Rect.fromCircle(center: Offset(drawing[0].dx,drawing[0].dy), radius: 1));
        }

        for (int i = 1; i < drawing.length - 1; ++i) {
          final p0 = drawing[i];
          final p1 = drawing[i + 1];
          path.quadraticBezierTo(
            p0.dx,
            p0.dy,
            (p0.dx + p1.dx) / 2,
            (p0.dy + p1.dy) / 2,
          );
        }

        canvas.drawPath(
            path,
            Paint()
              ..color = drawing.color
              ..strokeWidth = drawing.size
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round);

      }
    }
  }

  @override
  bool shouldRepaint(covariant FimpPainter oldDelegate) {
    return true;
  }
}
