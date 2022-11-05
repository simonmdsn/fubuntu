import 'dart:async';
import 'dart:collection';

import 'package:file/file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fubuntu/apps/terminal/commands/command.dart';
import 'package:fubuntu/apps/terminal/readline.dart';
import 'package:fubuntu/desktop.dart';
import 'package:fubuntu/fs/fs.dart';
import 'package:google_fonts/google_fonts.dart';

class OpenTerminalIntent extends Intent {
  final String startDirectory;

  const OpenTerminalIntent({this.startDirectory = "/"});
}

class OpenTerminalAction extends Action<OpenTerminalIntent> {
  final WindowManagerNotifier windowManagerNotifier;

  OpenTerminalAction(this.windowManagerNotifier);

  @override
  Object? invoke(OpenTerminalIntent intent) {
    var window = Window(windowManagerNotifier.update!);
    var terminal = Terminal(
      window: window,
      startDirectory: intent.startDirectory,
    );
    window.windowProperties.application = terminal;
    window.windowProperties.title =
        terminal.getTitle(FS.fileSystem.directory(terminal.startDirectory));
    windowManagerNotifier.addWindow(window);
    return null;
  }
}

class Terminal extends Application {
  String getTitle(Directory directory) => "root@fubuntu: ${directory.path}";

  final Window window;
  final String startDirectory;

  Terminal({Key? key, required this.window, this.startDirectory = "~"})
      : super(key: GlobalKey(), focusNode: FocusNode(), icon: Icons.terminal);

  @override
  ConsumerState createState() => TerminalState();
}

class TerminalState extends ConsumerState<Terminal> {
  final terminalTextController = TextEditingController();
  final terminalTextFieldKey = UniqueKey();
  final overlays = ListQueue<Widget>();
  final List<TextSpan> outputs = [];
  final terminalScrollController = ScrollController();
  bool scrollLock = true;

  StreamSubscription? currentProcess;
  late Directory cwd = FS.fileSystem.directory(widget.startDirectory);

  var textStyle = const TextStyle(color: Colors.white, fontFamily: 'Ubuntu Mono', fontSize: 16);

  @override
  void initState() {
    super.initState();
    terminalScrollController.addListener(() {
      scrollLock =
          terminalScrollController.offset == terminalScrollController.position.maxScrollExtent;
    });
  }

  void changeCWD(Directory directory) {
    setState(() {
      cwd = directory;
      widget.window.windowProperties.title = "root@fubuntu: ${cwd.path}";
      widget.window.windowProperties.update!();
    });
  }

  TextSpan get _prefix => TextSpan(
          text: "root@fubuntu",
          style: textStyle.copyWith(color: const Color(0xFF26A269), fontWeight: FontWeight.bold),
          children: [
            TextSpan(text: ":", style: textStyle),
            TextSpan(
                text: cwd.path,
                style: textStyle.copyWith(
                    color: const Color(0xFF12488B), fontWeight: FontWeight.bold)),
            TextSpan(text: "\$ ", style: textStyle),
          ]);

  @override
  Widget build(BuildContext context) {
    var windowManagerNotifier = ref.watch(windowManagerProvider.notifier);
    return overlays.isEmpty
        ? Shortcuts(
            shortcuts: {
              LogicalKeySet(LogicalKeyboardKey.tab): ReadlineIntent(),
              LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC): SigintIntent(),
              LogicalKeySet(LogicalKeyboardKey.zoomIn): const ZoomIntent(2),
              LogicalKeySet(LogicalKeyboardKey.zoomOut): const ZoomIntent(-2),
              LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.add):
                  const ZoomIntent(2),
              LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.minus):
                  const ZoomIntent(-2),
            },
            child: Actions(
              actions: {
                ///TODO move to own classes
                ReadlineIntent: CallbackAction<ReadlineIntent>(onInvoke: (intent) {
                  setState(() {
                    terminalTextController.text +=
                        Readline.complete(terminalTextController.text, cwd);
                    terminalTextController.selection =
                        TextSelection.collapsed(offset: terminalTextController.text.length);
                  });
                  return null;
                }),
                SigintIntent: CallbackAction<SigintIntent>(onInvoke: (intent) {
                  currentProcess?.cancel();
                  setState(() {
                    outputs.add(TextSpan(text: "\n^C", style: textStyle));
                  });
                  if (scrollLock) {
                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                      terminalScrollController
                          .jumpTo(terminalScrollController.position.maxScrollExtent);
                    });
                  }
                  return null;
                }),
                ZoomIntent: CallbackAction<ZoomIntent>(onInvoke: (intent) {
                  setState(() {
                    textStyle =
                        textStyle.copyWith(fontSize: (textStyle.fontSize ?? 14) + intent.zoom);
                  });
                  if (scrollLock) {
                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                      terminalScrollController
                          .jumpTo(terminalScrollController.position.maxScrollExtent);
                    });
                  }
                  return null;
                }),
              },
              child: GestureDetector(
                child: Theme(
                  data: Theme.of(context).copyWith(
                      textTheme: GoogleFonts.ubuntuMonoTextTheme(),
                      scrollbarTheme: ScrollbarTheme.of(context)
                          .copyWith(thumbColor: MaterialStateProperty.all(Colors.grey))),
                  child: Container(
                    color: const Color(0xCC000000),
                    child: Scrollbar(
                      controller: terminalScrollController,
                      child: ListView(
                        controller: terminalScrollController,
                        children: [
                          outputs.isNotEmpty
                              ? SelectableText.rich(
                                  TextSpan(text: null, children: [
                                    ...outputs.map((e) => TextSpan(
                                        text: e.text,
                                        children: e.children,
                                        style: e.style?.copyWith(fontSize: textStyle.fontSize)))
                                  ]),
                                )
                              : Container(),
                          Row(
                            children: [
                              RichText(text: _prefix),
                              Flexible(
                                child: TextField(
                                  key: terminalTextFieldKey,
                                  focusNode: widget.focusNode,
                                  controller: terminalTextController,
                                  cursorColor: Colors.white,
                                  // cursorWidth: 10,
                                  // cursorHeight: 14,
                                  enableInteractiveSelection: false,
                                  onSubmitted: (command) {
                                    setState(() {
                                      if (outputs.isNotEmpty) {
                                        outputs.add(const TextSpan(text: "\n"));
                                      }
                                      outputs.add(_prefix);
                                      outputs.add(TextSpan(
                                        text: command,
                                        style: GoogleFonts.ubuntuMono()
                                            .copyWith(color: Colors.white, fontSize: 16),
                                      ));
                                    });
                                    if (command.isNotEmpty) {
                                      var split = command.split(" ");
                                      command = split.removeAt(0);
                                      Stream<TextSpan>? stream = TerminalCommands.commands
                                          .firstWhere((element) => element.command == command,
                                              orElse: () => NotFoundCommand())
                                          .run(
                                            command,
                                            split,
                                            overlays,
                                            this,
                                          );
                                      bool first = true;
                                      currentProcess = stream.listen((element) {
                                        if (first && element.text!.isNotEmpty) {
                                          outputs.add(const TextSpan(text: "\n"));
                                          first = false;
                                        }
                                        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                                          widget.focusNode.requestFocus();
                                        });
                                        setState(() {
                                          outputs.add(element);
                                          Future.delayed(const Duration(milliseconds: 50), () {
                                            if (scrollLock && overlays.isEmpty) {
                                              terminalScrollController.jumpTo(
                                                  terminalScrollController
                                                      .position.maxScrollExtent);
                                            }
                                          });
                                        });
                                      });
                                      currentProcess?.onDone(() {
                                        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                                          widget.focusNode.requestFocus();
                                        });
                                        if (scrollLock && overlays.isEmpty) {
                                          Future.delayed(const Duration(milliseconds: 50), () {
                                            terminalScrollController.jumpTo(
                                                terminalScrollController.position.maxScrollExtent);
                                          });
                                        }
                                      });
                                    }

                                    widget.focusNode.requestFocus();
                                    terminalTextController.clear();
                                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                                      if(overlays.isEmpty) {

                                      terminalScrollController.jumpTo(
                                          terminalScrollController.position.maxScrollExtent);
                                      }
                                    });
                                    // cwd = FS.fileSystem.directory("/home")
                                  },
                                  keyboardType: TextInputType.text,
                                  maxLines: null,
                                  style: textStyle,
                                  decoration: const InputDecoration(
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 0.0),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                onTap: () => widget.focusNode.requestFocus(),
              ),
            ),
          )
        : overlays.last;
  }
}

extension SpanExt on List<TextSpan> {
  List<TextSpan> onAllButLast(TextSpan textSpan) {
    final List<TextSpan> end = [];
    for (var value in this) {
      if (value != last) {
        end.add(value);
        end.add(textSpan);
      }
    }
    end.add(last);
    return end;
  }
}

extension ListExt on List {
  List onAllButLast(dynamic object) {
    final List end = [];
    for (var value in this) {
      if (value != last) {
        end.add(value);
        end.add(object);
      }
    }
    end.add(last);
    return end;
  }
}

class ReadlineIntent extends Intent {}

class SigintIntent extends Intent {}

class ZoomIntent extends Intent {
  final int zoom;

  const ZoomIntent(this.zoom);
}
