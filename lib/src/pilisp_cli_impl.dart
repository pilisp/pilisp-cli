import 'dart:io';

import 'package:pilisp/pilisp.dart';

final loadFileSym = PLSymbol('repl/load-file');

final usage = r'''
PiLisp

pl                  - Run PiLisp REPL
pl -h/--help        - Print usage information
pl -l/--load <file> - Load the file as PiLisp code, binds args to *command-line-args*
pl -r/--repl        - Run PiLisp REPL
''';

String readFile(String path) {
  return File(path).readAsStringSync();
}

void handleEval(PLEnv env, Iterable<String> evalArgs,
    {bool shouldPrint = false}) {
  final l = evalArgs.toList();
  for (var i = 0; i < l.length; i++) {
    final program = l[i];
    final ret = PiLisp.loadString(program, env: env);
    if (i == l.length - 1 && ret != PLNil() && ret != null && shouldPrint) {
      print(PiLisp.printToString(ret));
    }
  }
}
