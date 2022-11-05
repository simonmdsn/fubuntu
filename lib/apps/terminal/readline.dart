import 'package:file/file.dart';
import 'package:fubuntu/apps/terminal/commands/command.dart';
import 'package:fubuntu/apps/terminal/terminal.dart';

/// based on the GNU Readline library for auto-completion used by bash.
/// https://tiswww.case.edu/php/chet/readline/rltop.html
///
/// triggered on tab from [Terminal]
/// atm must naive solution ever. Autocomplete command name if single word from the input,
/// otherwise autocomplete for path
class Readline {
  static String complete(String cmd, Directory directory) {
    var split = cmd.split(" ");
    if (split.length == 1) {
      var where =
          TerminalCommands.commands.where((element) => element.command.contains(split.first));
      if (where.length == 1 && where.first.command != split.first) {
        return "${where.first.command.substring(split.first.length)} ";
      }
    }
    if (split.length == 2) {
      var where = directory.listSync().where((element) => element.basename.contains(split[1]));
      if(where.length == 1 && where.first.basename != split[1]) {
        return where.first.basename.substring(split[1].length);
      }
    }
    return "";
  }
}
