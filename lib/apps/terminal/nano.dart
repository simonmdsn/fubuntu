import 'package:file/file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fubuntu/apps/terminal/terminal.dart';

class _NanoSaveIntent extends Intent {}

class _NanoExitIntent extends Intent {}

class Nano extends ConsumerStatefulWidget {
  final File? file;
  final TerminalState state;

  const Nano(this.state, {Key? key, this.file}) : super(key: key);

  @override
  ConsumerState createState() => _NanoState();
}

class _NanoState extends ConsumerState<Nano> {
  final textInputController = TextEditingController();
  final scrollController = ScrollController();

  final textInputFocusNode = FocusNode();

  late final windowListener = () => setState(() {});

  @override
  void initState() {
    super.initState();
    textInputController.text = widget.file?.readAsStringSync() ?? "";
    widget.state.widget.window.windowProperties.addListener(windowListener);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      textInputFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): _NanoSaveIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyX): _NanoExitIntent(),
      },
      child: Actions(
        actions: {
          _NanoSaveIntent: CallbackAction<_NanoSaveIntent>(
            onInvoke: (intent) {
              widget.file?.writeAsString(textInputController.text);
              return null;
            },
          ),
          _NanoExitIntent: CallbackAction<_NanoExitIntent>(
            onInvoke: (intent) {
              widget.state.widget.window.windowProperties.removeListener(windowListener);
              widget.state.overlays.remove(widget);
              widget.state.setState(() {
                WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                  widget.state.terminalScrollController.jumpTo(widget.state.terminalScrollController.position.maxScrollExtent);
                });
              });
              return null;
            },
          )
        },
        child: Container(
          color: const Color(0xFF380C2A),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        "GNU nano 6.2",
                        style: widget.state.textStyle.copyWith(color: const Color(0xFF380C2A)),
                      ),
                    ),
                    Container(),
                    Text(
                      "New Buffer",
                      style: widget.state.textStyle.copyWith(color: const Color(0xFF380C2A)),
                    ),
                    Container(),
                    Container(),
                  ],
                ),
              ),
              Expanded(
                child: TextField(
                  controller: textInputController,
                  focusNode: textInputFocusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(color: Colors.white, fontSize: widget.state.textStyle.fontSize),
                  cursorColor: Colors.white,
                  cursorWidth: (widget.state.textStyle.fontSize ?? 14) / 2,
                  decoration: const InputDecoration(
                    focusedBorder: InputBorder.none,
                    border: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.only(bottom: 14, top: 6),
                    isDense: true,
                  ),
                ),
              ),
              Container(
                color: const Color(0xFF380C2A),
                child: Row(
                  children: [
                    Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              color: Colors.white,
                              child: Text(
                                "^G",
                                style: widget.state.textStyle.copyWith(color: Color(0xFF380C2A)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                "Help",
                                style: widget.state.textStyle.copyWith(color: Colors.white),
                              ),
                            )
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              color: Colors.white,
                              child: Text(
                                "^X",
                                style: widget.state.textStyle.copyWith(color: Color(0xFF380C2A)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                "Exit",
                                style: widget.state.textStyle.copyWith(color: Colors.white),
                              ),
                            )
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
