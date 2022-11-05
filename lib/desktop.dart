import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:fubuntu/apps/terminal/terminal.dart';
import 'package:fubuntu/desktop_clock.dart';

class Desktop extends ConsumerStatefulWidget {
  const Desktop({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => DesktopState();
}

class ShowApplicationsIntent extends Intent {
  const ShowApplicationsIntent();
}

class ShowApplicationsAction extends Action<ShowApplicationsIntent> {
  @override
  Object? invoke(ShowApplicationsIntent intent) {
    print("TODO open all applications!");
    return null;
  }
}

class DesktopState extends ConsumerState<Desktop> {
  final desktopFocusNode = FocusNode();

  var showDock = false;
  var inDockArea = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(
        const Duration(milliseconds: 10),
        () => OpenTerminalAction(ref.read(windowManagerProvider.notifier))
            .invoke(const OpenTerminalIntent()));
  }

  @override
  void dispose() {
    desktopFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var windowManager = ref.watch(windowManagerProvider);
    var windowManagerNotifier = ref.watch(windowManagerProvider.notifier);
    ref.watch(windowManagerProvider.notifier).setUpdate(() => setState(() {}));
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyT):
            const OpenTerminalIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA):
            const ShowApplicationsIntent(),
      },
      child: Actions(
        dispatcher: LoggingActionDispatcher(),
        actions: <Type, Action<Intent>>{
          OpenTerminalIntent: OpenTerminalAction(ref.read(windowManagerProvider.notifier)),
          ShowApplicationsIntent: ShowApplicationsAction(),
        },
        child: GestureDetector(
          onTap: () => desktopFocusNode.requestFocus(),
          child: Focus(
            autofocus: true,
            focusNode: desktopFocusNode,
            child: Scaffold(
              body: SizedBox(
                child: Column(
                  children: [
                    Container(
                      height: 20,
                      color: Colors.black,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Clock(),
                        ],
                      ),
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height - 20,
                          child: Image.network(
                            "https://149366088.v2.pressablecdn.com/wp-content/uploads/2022/03/jammy-jellyfish-wallpaper.jpg",
                            fit: BoxFit.cover,
                          ),
                        ),
                        ...windowManager
                            .map((e) => Positioned(
                                  left: e.windowProperties.x,
                                  top: e.windowProperties.y,
                                  child: e,
                                ))
                            .toList(),
                        Positioned(
                          left: 0,
                          bottom: 0,
                          right: 0,
                          child: MouseRegion(
                            onEnter: (enter) => onDockActivateAreaEntered(enter),
                            onExit: (exit) => onDockActiveAreaExited(exit),
                            child: const SizedBox(
                              height: 32,
                            ),
                          ),
                        ),
                        AnimatedPositioned(
                          bottom: inDockArea || showDock ? 5 : -50,
                          duration: const Duration(milliseconds: 200),
                          child: MouseRegion(
                            onEnter: (enter) => onDockAreaEntered(enter),
                            onExit: (exit) => onDockAreaExited(exit),
                            child: inDockArea || showDock
                                ? Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16.0),
                                        color: const Color(0xFF2C2828),
                                        border: Border.all(color: Colors.grey)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: windowManager
                                            .map((e) => Tooltip(
                                                  message: e.windowProperties.application.hashCode
                                                      .toString(),
                                                  waitDuration: const Duration(milliseconds: 250),
                                                  verticalOffset: 35,
                                                  preferBelow: false,
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    type: MaterialType.button,
                                                    child: IconButton(
                                                      icon: Icon(
                                                          e.windowProperties.application?.icon),
                                                      hoverColor: Colors.grey,
                                                      splashRadius: 35,
                                                      iconSize: 36,
                                                      onPressed: () {
                                                        windowManagerNotifier.putWindowToFront(e);
                                                      },
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  )
                                : Container(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  onDockActivateAreaEntered(PointerEnterEvent enter) {
    setState(() {
      showDock = true;
    });
  }

  onDockActiveAreaExited(PointerExitEvent exit) {
    setState(() {
      showDock = false;
    });
  }

  onDockAreaEntered(PointerEnterEvent enter) {
    setState(() {
      inDockArea = true;
    });
  }

  onDockAreaExited(PointerExitEvent exit) {
    setState(() {
      inDockArea = false;
    });
  }
}

class WindowManagerNotifier extends StateNotifier<List<Window>> {
  WindowManagerNotifier() : super([]);

  VoidCallback? update;

  get frontWindow => state.last;

  void setUpdate(VoidCallback update) {
    this.update = update;
  }

  void addWindow(Window window) {
    state = [...state, window];
    window.windowProperties.application?.focusNode.requestFocus();
  }

  void removeWindow(Window window) {
    state.remove(window);
  }

  void removeWindowByApplication(Application application) {
    var windowToRemove =
        state.firstWhere((element) => element.windowProperties.application == application);
    state.remove(windowToRemove);
  }

  /// actually it is the back because of how Stack() works.
  void putWindowToFront(Window window) {
    if (window == state.last) return;
    state.remove(window);
    state = [...state, window];
    window.windowProperties.application?.focusNode.requestFocus();
  }

  void setWindowTitle(Window window, String title) {
    window.windowProperties.title = title;
  }

  void setWindowTitleByApplication(Application application, String title) {
    var window = state.firstWhere((element) => element.windowProperties.application == application);
    setWindowTitle(window, title);
  }
}

final windowManagerProvider =
    StateNotifierProvider<WindowManagerNotifier, List<Window>>((ref) => WindowManagerNotifier());

class WindowProperties with ChangeNotifier {
  double x = 100;
  double y = 100;
  double _width = 400;
  double _height = 250;
  String title = "";
  Application? application;
  VoidCallback? update;

  set width(double width) {
    _width = width;
    notifyListeners();
  }

  double get width => _width;

  set height(double height) {
    _height = height;
    notifyListeners();
  }

  double get height => _height;
}

class Window extends ConsumerStatefulWidget {
  final VoidCallback update;
  final WindowProperties windowProperties = WindowProperties();

  Window(this.update, {super.key, Application? application}) {
    windowProperties.application = application;
  }

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return WindowState();
  }
}

class WindowState extends ConsumerState<Window> {
  @override
  void initState() {
    super.initState();
    widget.windowProperties.update = () => setState(() {});
  }

  bool resizing = false;

  @override
  Widget build(BuildContext context) {
    var windowManagerNotifier = ref.watch(windowManagerProvider.notifier);
    return SizedBox(
      width: widget.windowProperties.width,
      height: widget.windowProperties.height.toDouble(),
      child: GestureDetector(
        onTap: () => windowManagerNotifier.putWindowToFront(widget),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: .5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    child: Container(
                      height: 30,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        color: Color(0xFF333333),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              widget.windowProperties.title,
                              style: const TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: -4,
                            child: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                windowManagerNotifier.removeWindow(widget);
                                widget.update();
                              },
                              color: Colors.white,
                              iconSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () => windowManagerNotifier.putWindowToFront(widget),

                    /// doesnt put to front, buggy if trying to use the windowManagerNotifier
                    onPanUpdate: (details) => setState(() {
                      // if (details.delta.dx + widget.windowProperties.x <= 0) {
                      //   widget.windowProperties.x = 0;
                      // } else {
                      widget.windowProperties.x += details.delta.dx;
                      // }
                      if (details.delta.dy + widget.windowProperties.y <= 0) {
                        widget.windowProperties.y = 0;
                      } else {
                        widget.windowProperties.y += details.delta.dy;
                      }
                      widget.update();
                    }),
                    onPanEnd: (details) => widget.update(),
                  ),
                  SizedBox(
                      height: widget.windowProperties.height - 31,
                      width: widget.windowProperties.width,
                      child: Stack(
                        children: [
                          if (widget.windowProperties.application != null)
                            widget.windowProperties.application!,
                          if (resizing)
                            Center(
                              child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24.0),
                                    color: const Color(0xFF2C2828),
                                    border: Border.all(color: Colors.grey)),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    '${widget.windowProperties.width.round()} × ${widget.windowProperties.height.round()}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )),
                ],
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: 10,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeLeft,
                child: GestureDetector(
                  onPanUpdate: (details) => onHorizontalDragLeft(details),
                  onPanEnd: onDragStop,
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: 4,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeRight,
                child: GestureDetector(
                  onPanUpdate: (details) => onHorizontalDragRight(details),
                  onPanEnd: onDragStop,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 10,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeUp,
                child: GestureDetector(
                  onPanUpdate: (details) => onHorizontalDragTop(details),
                  onPanEnd: onDragStop,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 10,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeDown,
                child: GestureDetector(
                  onPanUpdate: (details) => onHorizontalDragBottom(details),
                  onPanEnd: onDragStop,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              width: 10,
              height: 10,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeUpLeft,
                child: GestureDetector(
                  onPanUpdate: (details) => onHorizontalDragTopLeft(details),
                  onPanEnd: onDragStop,
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              width: 10,
              height: 10,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeUpRight,
                child: GestureDetector(
                  onPanUpdate: (details) => onHorizontalDragTopRight(details),
                  onPanEnd: onDragStop,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              width: 10,
              height: 10,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeDownRight,
                child: GestureDetector(
                  onPanUpdate: (details) => onHorizontalDragBottomRight(details),
                  onPanEnd: onDragStop,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              width: 10,
              height: 10,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeDownLeft,
                child: GestureDetector(
                  onPanUpdate: (details) => onHorizontalDragBottomLeft(details),
                  onPanEnd: onDragStop,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onHorizontalDragLeft(DragUpdateDetails details) {
    resizing = true;
    if (widget.windowProperties.width - details.delta.dx <= 100) {
      return;
    }
    setState(() {
      widget.windowProperties.width -= details.delta.dx;
    });
    widget.windowProperties.x += details.delta.dx;
    widget.update();
  }

  void onHorizontalDragRight(DragUpdateDetails details) {
    resizing = true;
    setState(() {
      widget.windowProperties.width += details.delta.dx;
    });
  }

  void onHorizontalDragTop(DragUpdateDetails details) {
    resizing = true;
    if (widget.windowProperties.height - details.delta.dy <= 40) {
      return;
    }
    setState(() {
      widget.windowProperties.height -= details.delta.dy;
    });
    widget.windowProperties.y += details.delta.dy;
    widget.update();
  }

  void onHorizontalDragBottom(DragUpdateDetails details) {
    resizing = true;
    setState(() {
      widget.windowProperties.height += details.delta.dy;
    });
  }

  void onHorizontalDragTopLeft(DragUpdateDetails details) {
    onHorizontalDragLeft(details);
    onHorizontalDragTop(details);
  }

  void onHorizontalDragTopRight(DragUpdateDetails details) {
    onHorizontalDragRight(details);
    onHorizontalDragTop(details);
  }

  void onHorizontalDragBottomLeft(DragUpdateDetails details) {
    onHorizontalDragLeft(details);
    onHorizontalDragBottom(details);
  }

  void onHorizontalDragBottomRight(DragUpdateDetails details) {
    onHorizontalDragRight(details);
    onHorizontalDragBottom(details);
  }

  void onDragStop(DragEndDetails details) {
    setState(() {
      resizing = false;
    });
  }
}

abstract class Application extends ConsumerStatefulWidget {
  final FocusNode focusNode;
  final IconData icon;

  const Application({super.key, required this.focusNode, required this.icon});
}

class LoggingActionDispatcher extends ActionDispatcher {
  @override
  Object? invokeAction(
    covariant Action<Intent> action,
    covariant Intent intent, [
    BuildContext? context,
  ]) {
    print('Action invoked: $action($intent) from $context');
    super.invokeAction(action, intent, context);

    return null;
  }
}
