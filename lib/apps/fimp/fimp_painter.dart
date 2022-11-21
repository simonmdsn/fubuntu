import 'package:flutter/material.dart';

class FimpPainter extends CustomPainter {
  List<Offset> points;

  FimpPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < points.length - 1; i++) {
      var path = Path();
      path.moveTo(points[0].dx, points[0].dy);

      if (points.length < 2) {
        path.addOval(Rect.fromCircle(center: points[i], radius: 5));
      }

      for (int i = 1; i < points.length - 1; ++i) {
        final p0 = points[i];
        final p1 = points[i + 1];
        path.quadraticBezierTo(
          p0.dx,
          p0.dy,
          (p0.dx + p1.dx) / 2,
          (p0.dy + p1.dy) / 2,
        );
      }
      // path.lineTo(points[i + 1].dx, points[i + 1].dy);
      // path.addOval(Rect.fromCircle(center: points[i], radius: 5));

      canvas.drawPath(
          path,
          Paint()
            ..color = Colors.black
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant FimpPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
