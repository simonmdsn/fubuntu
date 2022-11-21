import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fubuntu/apps/fimp/fimp_painter.dart';
import 'package:fubuntu/desktop.dart';
import 'package:google_fonts/google_fonts.dart';

class Fimp extends Application {
  final Window window;

  Fimp({
    Key? key,
    required this.window,
  }) : super(key: GlobalKey(), appName: "FIMP", icon: Icons.palette, focusNode: FocusNode());

  @override
  ConsumerState createState() => _FimpState();
}

class _FimpState extends ConsumerState<Fimp> {
  List<Offset> points = [];

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {},
      child: Actions(
        actions: {},
        child: Theme(
          data: Theme.of(context).copyWith(textTheme: GoogleFonts.ubuntuMonoTextTheme()),
          child: Container(
            color: const Color(0xff2d2b2b),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Column(),
                Column(children: [
                  Listener(
                    onPointerMove: (details) {
                      Offset pos = (context.findRenderObject() as RenderBox)
                          .globalToLocal(details.position);
                      points = List<Offset>.from(points)..add(pos);
                      setState(() {});
                    },
                    child: RepaintBoundary(
                      child: Container(
                        height: 200,
                        width: 200,
                        color: Colors.red,
                        child: ClipRect(child: CustomPaint(painter: FimpPainter(points))),
                      ),
                    ),
                  ),
                ]),
                Column(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
