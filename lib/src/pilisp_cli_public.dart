import 'dart:convert';
import 'dart:io';

import 'package:pilisp/pilisp.dart';

import 'cli_repl.dart';
import 'pilisp_cli_impl.dart';

/// Run a PiLisp REPL.
///
/// The REPL can handle multi-line programs, but otherwise provides no
/// readline-like capabilities.
///
/// Like Clojure's REPL, this REPL binds the symbols `*1`, `*2`, and `*3` with
/// the last three evaluation results. If an exception has been thrown, it binds
/// the exception to the symbol `*e`.
///
/// This REPL is also aware of the [PLEnv.parent] value and the fact that PiLisp
/// defines a `parent-to-string` function. It invokes that function on the
/// parent value to change the REPL prompt when the parent is set.
Future<void> repl(PLEnv env, {bool isRich = false}) async {
  env.addBindingValue(PLSymbol('*3'), null);
  env.addBindingValue(PLSymbol('*2'), null);
  env.addBindingValue(PLSymbol('*1'), null);
  env.addBindingValue(PLSymbol('*e'), null);

  String multiLineProgram = '';
  bool showPrompt = true;

  if (isRich) {
    var repl =
        Repl(prompt: 'pl> ', continuation: '... ', validator: alwaysValid);
    await for (var x in repl.runAsync()) {
      if (x.trim().isEmpty) continue;
      final parent = env.parent;
      if (parent == null) {
        repl.prompt = 'pl> ';
      } else {
        final printParent = env.getBindingValue(PLSymbol('parent-to-string'));
        if (printParent is PLFunction) {
          repl.prompt = '${printParent.invoke(env, [parent])}> ';
        }
      }

      try {
        final programSource = x;
        final programData = PiLisp.readString(programSource);
        // NB. Support loading files despite lack of dart:io in core PiLisp
        if (programData == loadFileSym ||
            (programData is PLList && programData[0] == loadFileSym)) {
          if (programData is PLList) {
            final fileName = programData.last.toString();
            print('Loading $fileName');
            loadFile(env, fileName, []);
          } else {
            // NB. Support pl> syntax without using that macro.
            final expr = PiLisp.readString('[ $programSource ]');
            if (expr is PLVector) {
              final fileName = expr.last.toString();
              print('Loading $fileName');
              loadFile(env, fileName, []);
            }
          }
          continue;
        }
        final programUnawaitedResult =
            PiLisp.loadString('(pl>\n$programSource\n)', env: env);
        // final programUnawaitedResult = PiLisp.loadString(programSource, env: env);
        Object? programResult;
        if (programUnawaitedResult is PLAwait) {
          programResult = await programUnawaitedResult.value;
        } else {
          programResult = programUnawaitedResult;
        }
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
        // } on UnexpectedEndOfInput {
        //   // In practice, these are async errors (see above) because the function is async.
        //   showPrompt = false;
        //   multiLineProgram += '\n$line';
      } catch (e, st) {
        env.addBindingValue(PLSymbol('*e'), e);
        showPrompt = true;
        multiLineProgram = '';
        stderr.writeln(e);
        stderr.writeln(st);
      }
    }
  } else {
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
            // NB. Support pl> syntax without using that macro.
            final expr = PiLisp.readString('[ $programSource ]');
            if (expr is PLVector) {
              final fileName = expr.last.toString();
              print('Loading $fileName');
              loadFile(env, fileName, []);
            }
          }
          continue;
        }
        final programUnawaitedResult =
            PiLisp.loadString('(pl>\n$programSource\n)', env: env);
        // final programUnawaitedResult = PiLisp.loadString(programSource, env: env);
        Object? programResult;
        if (programUnawaitedResult is PLAwait) {
          programResult = await programUnawaitedResult.value;
        } else {
          programResult = programUnawaitedResult;
        }
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
}

/// Load (read + eval) the file at the given [path], returning the final value
/// evaluated in the program.
Future<Object?> loadFile(PLEnv env, String path, Iterable<String> args) async {
  final programSource = readFile(path);
  PiLisp.loadString('''
(def *command-line-args* '[${args.map((e) => '"${e.replaceAll('"', '\\"')}"').join(' ')}])
''', env: env);
  final programUnawaitedResult = PiLisp.loadString(programSource, env: env);
  Object? programResult;
  if (programUnawaitedResult is PLAwait) {
    programResult = await programUnawaitedResult.value;
  } else {
    programResult = programUnawaitedResult;
  }
  return programResult;
}

/// A proxy for your [main] function, if you want this package to handle all of
/// your command-line arguments.
void cliMain(PLEnv env, List<String> mainArgs) async {
  if (mainArgs.isEmpty) {
    await repl(env);
  } else if (mainArgs.isNotEmpty) {
    final arg = mainArgs[0].trim();
    if (arg == '-h' || arg == '--help') {
      print(usage);
      exit(0);
    } else if (arg == '-e' || arg == '--eval') {
      final programs = mainArgs.skip(1);
      handleEval(env, programs);
    } else if (arg == '-r' || arg == '--repl') {
      repl(env);
    } else if (arg == '-l' || arg == '--load') {
      if (mainArgs.length >= 2) {
        final programResult =
            await loadFile(env, mainArgs[1], mainArgs.skip(2));
        stdout.writeln(PiLisp.printToString(programResult, env: env));
        await env.shutDown();
        exit(0);
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
