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

Object? handleEval(PLEnv env, Iterable<String> evalArgs) {
  for (final program in evalArgs) {
    final ret = PiLisp.loadString(program, env: env);
    if (ret != PLNil() && ret != null) {
      print(PiLisp.printToString(ret));
    }
  }
}
