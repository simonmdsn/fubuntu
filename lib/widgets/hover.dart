import 'package:flutter/material.dart';

class Hover extends StatefulWidget {
  final Widget child;
  final Color color;

  const Hover({Key? key, required this.child, required this.color}) : super(key: key);

  @override
  _HoverState createState() => _HoverState();
}

class _HoverState extends State<Hover> {
  var hovering = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: hovering ? widget.color : null,
      child: InkWell(
        onHover: (hover) {
          hovering = hover;
        },
        child: widget.child,
      ),
    );
  }
}
