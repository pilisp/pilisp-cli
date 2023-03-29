import 'dart:convert';
import 'dart:io';

import 'package:pilisp/pilisp.dart';

final loadFileSym = PLSymbol('repl/load-file');

void repl(PLEnv env) {
  env.addBindingValue(PLSymbol('*3'), null);
  env.addBindingValue(PLSymbol('*2'), null);
  env.addBindingValue(PLSymbol('*1'), null);
  env.addBindingValue(PLSymbol('*e'), null);

  String multiLineProgram = '';
  bool showPrompt = true;

  // TODO Handle interrupts.
  while (true) {
    if (showPrompt) {
      final parent = env.parent;
      if (parent == null) {
        stdout.write('pl> ');
      } else {
        final printParent = env.getBindingValue(PLSymbol('parent-to-string'));
        if (printParent is PLFunction) {
          stdout.write('${printParent.invoke(env, [parent])}> ');
        }
      }
    }
    final line = stdin.readLineSync(encoding: Encoding.getByName('utf-8')!);
    if (line == null) break;
    final programSource =
        multiLineProgram.isEmpty ? line : '$multiLineProgram\n$line';

    try {
      final programData = PiLisp.readString(programSource);
      // NB. Support loading files despite lack of dart:io in core PiLisp
      if (programData == loadFileSym ||
          (programData is PLList && programData[0] == loadFileSym)) {
        if (programData is PLList) {
          final fileName = programData.last.toString();
          print('Loading $fileName');
          loadFile(env, fileName, []);
        } else {
          final expr = PiLisp.readString('[ $programSource ]');
          if (expr is PLVector) {
            final fileName = expr.last.toString();
            print('Loading $fileName');
            loadFile(env, fileName, []);
          }
        }
      } else {
        final programResult =
            PiLisp.loadString('(pl>\n$programSource\n)', env: env);
        // final programResult = PiLisp.loadString(programSource, env: env);
        // NB: Make it stress-free to eval these REPL-specific bindings.
        if (programData != PLSymbol('*3') &&
            programData != PLSymbol('*2') &&
            programData != PLSymbol('*1') &&
            programData != PLSymbol('*e')) {
          env.addBindingValue(
              PLSymbol('*3'), env.getBindingValue(PLSymbol('*2')));
          env.addBindingValue(
              PLSymbol('*2'), env.getBindingValue(PLSymbol('*1')));
          env.addBindingValue(PLSymbol('*1'), programResult);
        }
        stdout.writeln(PiLisp.printToString(programResult, env: env));
        // Clean-up
        showPrompt = true;
        multiLineProgram = '';
      }
    } on UnexpectedEndOfInput {
      // In practice, these are async errors (see above) because the function is async.
      showPrompt = false;
      multiLineProgram += '\n$line';
    } catch (e, st) {
      env.addBindingValue(PLSymbol('*e'), e);
      showPrompt = true;
      multiLineProgram = '';
      stderr.writeln(e);
      stderr.writeln(st);
    }
  }
}

String readFile(String path) {
  return File(path).readAsStringSync();
}

Future<void> loadFile(PLEnv env, String path, Iterable<String> args) async {
  final programSource = readFile(path);
  PiLisp.loadString('''
(def *command-line-args* '[${args.map((e) => '"${e.replaceAll('"', '\\"')}"').join(' ')}])
''', env: env);
  stdout.writeln(PiLisp.printToString(
      PiLisp.loadString(programSource, env: env),
      env: env));
  await env.shutDown();
}

final usage = r'''
PiLisp

pl                  - Run PiLisp REPL
pl -h/--help        - Print usage information
pl -l/--load <file> - Load the file as PiLisp code, binds args to *command-line-args*
pl -r/--repl        - Run PiLisp REPL
''';

void cliMain(PLEnv env, List<String> mainArgs) async {
  if (mainArgs.isEmpty) {
    repl(env);
  } else if (mainArgs.isNotEmpty) {
    final arg = mainArgs[0].trim();
    if (arg == '-h' || arg == '--help') {
      print(usage);
      exit(0);
    } else if (arg == '-r' || arg == '--repl') {
      repl(env);
    } else if (arg == '-l' || arg == '--load') {
      if (mainArgs.length >= 2) {
        await loadFile(env, mainArgs[1], mainArgs.skip(2));
      } else {
        print(usage);
        exit(1);
      }
    } else {
      // Assume single file name to load, no further args
      await loadFile(env, mainArgs[0], []);
    }
    exit(0);
  } else {
    print(usage);
    exit(1);
  }
}
