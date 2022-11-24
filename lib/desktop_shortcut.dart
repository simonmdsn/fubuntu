import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DesktopShortcut extends ConsumerStatefulWidget {
  final Icon icon;
  final String name;
  final VoidCallback onPressed;

  const DesktopShortcut({Key? key, required this.icon, required this.name, required this.onPressed})
      : super(key: key);

  @override
  ConsumerState createState() => _DesktopShortcutState();
}

class _DesktopShortcutState extends ConsumerState<DesktopShortcut> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: widget.name,
          waitDuration: const Duration(milliseconds: 250),
          preferBelow: false,
          child: Material(
            color: Colors.transparent,
            type: MaterialType.button,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
            child: IconButton(
              icon: widget.icon,
              hoverColor: Colors.grey,
              splashRadius: 35,
              iconSize: 36,
              onPressed: widget.onPressed,
            ),
          ),
        ),
      ],
    );
  }
}
