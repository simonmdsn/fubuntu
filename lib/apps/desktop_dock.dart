import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fubuntu/desktop.dart';

class DesktopDock extends ConsumerStatefulWidget {

  bool showDock;

  DesktopDock({required this.showDock,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState createState() => _DesktopDockState();
}

class _DesktopDockState extends ConsumerState<DesktopDock> {
  var inDockArea = false;

  @override
  Widget build(BuildContext context) {
    var windowManager = ref.watch(windowManagerProvider);
    var windowManagerNotifier = ref.watch(windowManagerProvider.notifier);

    return AnimatedPositioned(
      bottom: inDockArea || widget.showDock ? 5 : -50,
      duration: const Duration(milliseconds: 200),
      child: MouseRegion(
        onEnter: (enter) => onDockAreaEntered(enter),
        onExit: (exit) => onDockAreaExited(exit),
        child: inDockArea || widget.showDock
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
                              message: e.windowProperties.application?.appName,
                              waitDuration: const Duration(milliseconds: 250),
                              verticalOffset: 35,
                              preferBelow: false,
                              child: Material(
                                color: Colors.transparent,
                                type: MaterialType.button,
                                child: IconButton(
                                  icon: Icon(e.windowProperties.application?.icon),
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
    );
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
