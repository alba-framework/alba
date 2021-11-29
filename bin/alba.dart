import 'dart:io';

import 'commands/init.dart';

Future<void> main(List<String> args) async {
  if (1 == args.length && 'init' == args[0]) {
    exitCode = await (Init())();
  } else {
    stdout.write('Usage: flutter pub run alba [command]\n\n'
        'Commands:\n'
        '  init - Init Alba project\n'
        '  help - Show help\n');
  }
}
