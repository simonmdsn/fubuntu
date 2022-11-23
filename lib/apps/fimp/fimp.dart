import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fubuntu/apps/fimp/drawing.dart';
import 'package:fubuntu/apps/fimp/fimp_painter.dart';
import 'package:fubuntu/desktop.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class FimpTool {
  final String toolName;

  FimpTool(this.toolName);

  void onDragStart(FimpState state, DragStartDetails event);

  void onDragMove(FimpState state, DragUpdateDetails event);

  void onDragEnd(FimpState state, DragEndDetails event);
}

class SelectTool extends FimpTool {
  SelectTool() : super("Select");

  final startOffset = ValueNotifier<Offset?>(null);
  Widget overlay = Positioned(child: Container());
  var areaSelected = false;
  double width = 0;
  double height = 0;

  @override
  void onDragEnd(FimpState state, DragEndDetails event) {
    print("Hello from $SelectTool");
    print(
        "Created select rectangle with start pos ${startOffset.value} and end pos ${startOffset.value?.translate(width,height)}");
    areaSelected = true;

  }

  @override
  void onDragMove(FimpState state, DragUpdateDetails event) {
    Offset endPos = (state.painterKey.currentContext?.findRenderObject() as RenderBox)
        .globalToLocal(event.globalPosition);
    Offset startPos = startOffset.value!;
    if (startPos > endPos) {
      Offset temp = startPos;
      startPos = endPos;
      endPos = temp;
    } else if (startPos.dx > endPos.dx) {
      double temp = startPos.dx;
      startPos = Offset(endPos.dx, startPos.dy);
      endPos = Offset(temp, endPos.dy);
    } else if (startPos.dy > endPos.dy) {
      double temp = startPos.dy;
      startPos = Offset(startPos.dx, endPos.dy);
      endPos = Offset(endPos.dx, temp);
    }
    width = endPos.dx - startPos.dx;
    height = endPos.dy - startPos.dy;

    overlay = Positioned(
      left: startPos.dx,
      top: startPos.dy,
      width: width,
      height: height,
      child: GestureDetector(
        onPanStart: (event) {
        },
        onPanUpdate: (event) {
          state.setState(() {

          for (var drawing in state.drawings) {
            for(int i = 0; i < drawing.length; i++) {
              var point = drawing[i];
              if (point.dx > startOffset.value!.dx &&
                  point.dy > startOffset.value!.dy &&
                  point.dx < startOffset.value!.dx + (width) &&
                  point.dy < startOffset.value!.dy + (height)) {
                drawing[i] = Offset(point.dx + event.delta.dx, point.dy  + event.delta.dy);
              }
            }
          }
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey,
              width: .5,
            ),
          ),
        ),
      ),
    );
    state.overlay = overlay;
  }

  @override
  void onDragStart(FimpState state, DragStartDetails event) {
    startOffset.value = (state.painterKey.currentContext?.findRenderObject() as RenderBox)
        .globalToLocal(event.globalPosition);
    state.overlay = overlay;
  }
}

class PencilTool extends FimpTool {
  PencilTool() : super('Pencil');

  @override
  void onDragStart(FimpState state, DragStartDetails event) {
    Offset pos = (state.painterKey.currentContext?.findRenderObject() as RenderBox)
        .globalToLocal(event.globalPosition);
    state.currentDrawing = Drawing(
      points: [Offset(pos.dx, pos.dy)],
      color: Colors.black,
      size: 5,
    );
    state.drawings.add(state.currentDrawing!);
  }

  @override
  void onDragMove(FimpState state, DragUpdateDetails event) {
    Offset pos = (state.painterKey.currentContext?.findRenderObject() as RenderBox)
        .globalToLocal(event.globalPosition);
    state.currentDrawing?.points.add(Offset(pos.dx, pos.dy));
  }

  @override
  void onDragEnd(FimpState state, DragEndDetails event) {
    state.currentDrawing = null;
  }
}

class Fimp extends Application {
  final Window window;

  Fimp({
    Key? key,
    required this.window,
  }) : super(key: GlobalKey(), appName: "FIMP", icon: Icons.palette, focusNode: FocusNode()) {}

  @override
  ConsumerState createState() => FimpState();
}

class FimpState extends ConsumerState<Fimp> {
  Drawing? currentDrawing;
  final List<Drawing> drawings = [];

  final canvasScrollController = ScrollController();
  final painterKey = GlobalKey();
  Widget overlay = Container();

  FimpTool currentTool = PencilTool();

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                    width: 80,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Material(
                          color: currentTool is PencilTool ? Colors.black : Colors.transparent,
                          type: MaterialType.button,
                          child: IconButton(
                            icon: Icon(Icons.edit),
                            padding: EdgeInsets.zero,
                            color: Colors.grey,
                            onPressed: () {
                              setState(() {
                                currentTool = PencilTool();
                              });
                            },
                            hoverColor: Color(0xff232222),
                            splashRadius: 35,
                            iconSize: 18,
                          ),
                        ),
                        Material(
                          color: currentTool is SelectTool ? Colors.black : Colors.transparent,
                          type: MaterialType.button,
                          child: IconButton(
                            icon: Icon(Icons.crop_square),
                            padding: EdgeInsets.zero,
                            color: Colors.grey,
                            onPressed: () {
                              setState(() {
                                currentTool = SelectTool();
                              });
                            },
                            hoverColor: Color(0xff232222),
                            splashRadius: 35,
                            iconSize: 18,
                          ),
                        )
                      ],
                    )),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: GestureDetector(
                      onPanStart: (details) {
                        if (kDebugMode) {
                          print("Drawing started");
                        }
                        currentTool.onDragStart(this, details);
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          currentTool.onDragMove(this, details);
                        });
                      },
                      onPanEnd: (details) {
                        if (kDebugMode) {
                          print("Drawing ended");
                        }
                        setState(() {
                          currentTool.onDragEnd(this, details);
                        });
                      },
                      child: Stack(
                        children: [
                          RepaintBoundary(
                            child: Container(
                              key: painterKey,
                              height: 200,
                              width: 200,
                              color: Colors.white,
                              child: ClipRect(child: CustomPaint(painter: FimpPainter(drawings))),
                            ),
                          ),
                          overlay,
                        ],
                      ),
                    ),
                  ),
                ),
                Container(width: 80, child: Column()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
