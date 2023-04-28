import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:pilisp/pilisp.dart';

import 'cli_repl.dart';
import 'pilisp_cli_impl.dart';

/// Run a PiLisp REPL.
///
/// Defaults to a REPL with readline-like editing capabilities and
/// auto-completion based on all bindings within scope when `TAB` is pressed.
///
/// Both the rich and simple REPL modes can handle multi-line programs.
///
/// Like Clojure's REPL, this REPL binds the symbols `*1`, `*2`, and `*3` with
/// the last three evaluation results. If an exception has been thrown, it binds
/// the exception to the symbol `*e`.
///
/// This REPL is also aware of the [PLEnv.parent] value and the fact that PiLisp
/// defines a `parent-to-string` function. It invokes that function on the
/// parent value to change the REPL prompt when the parent is set.
///
/// Auto-completion is further enhanced to complete by term key names if the
/// current parent is a map.
Future<void> repl(PLEnv env, {bool isRich = true}) async {
  env.addBindingValue(PLSymbol('*3'), null);
  env.addBindingValue(PLSymbol('*2'), null);
  env.addBindingValue(PLSymbol('*1'), null);
  env.addBindingValue(PLSymbol('*e'), null);

  String multiLineProgram = '';
  bool showPrompt = true;

  if (isRich) {
    String startingPrompt = 'pl> ';
    if (env.parent != null) {
      final parentToStringFn =
          env.getBindingValue(PLSymbol('parent-to-string'));
      if (parentToStringFn is PLFunction) {
        startingPrompt = 'pl ${parentToStringFn.invoke(env, [env.parent])}> ';
      }
    }
    var repl = Repl(
      prompt: startingPrompt,
      continuation: '... ',
      validator: alwaysValid,
      env: env,
    );
    for (var x in repl.run()) {
      if (x.trim().isEmpty) continue;
      try {
        final programSource = x;
        final programData = PiLisp.readString(programSource);
        // NB. Support loading files despite lack of dart:io in core PiLisp
        if (programData == loadFileSym ||
            (programData is PLList && programData[0] == loadFileSym)) {
          if (programData is PLList) {
            final fileName = programData.last.toString();
            print('Loading $fileName');
            loadFile(env, fileName);
          } else {
            // NB. Support pl> syntax without using that macro.
            final expr = PiLisp.readString('[ $programSource ]');
            if (expr is PLVector) {
              final fileName = expr.last.toString();
              print('Loading $fileName');
              loadFile(env, fileName);
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
      final parent = env.parent;
      if (parent == null) {
        repl.prompt = 'pl> ';
      } else {
        final printParent = env.getBindingValue(PLSymbol('parent-to-string'));
        if (printParent is PLFunction) {
          repl.prompt = 'pl ${printParent.invoke(env, [parent])}> ';
        }
      }
    }
  } else {
    while (true) {
      if (showPrompt) {
        final parent = env.parent;
        if (parent == null) {
          stdout.write('pl> ');
        } else {
          final parentToStringFn =
              env.getBindingValue(PLSymbol('parent-to-string'));
          if (parentToStringFn is PLFunction) {
            stdout.write('pl ${parentToStringFn.invoke(env, [parent])}> ');
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
            loadFile(env, fileName);
          } else {
            // NB. Support pl> syntax without using that macro.
            final expr = PiLisp.readString('[ $programSource ]');
            if (expr is PLVector) {
              final fileName = expr.last.toString();
              print('Loading $fileName');
              loadFile(env, fileName);
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
Future<Object?> loadFile(PLEnv env, String path) async {
  final programSource = readFile(path);
  final programUnawaitedResult = PiLisp.loadString(programSource, env: env);
  Object? programResult;
  if (programUnawaitedResult is PLAwait) {
    programResult = await programUnawaitedResult.value;
  } else {
    programResult = programUnawaitedResult;
  }
  return programResult;
}

/// Given a [PLEnv] instance, bind the string values of operating system
/// environment variables to symbols with the same name with `env/`
/// prefixed.
PLEnv bindingsForEnvironment(PLEnv env) {
  final platformEnv = Platform.environment;
  for (final envVar in platformEnv.keys) {
    env.addBindingValue(PLSymbol('env/$envVar'), platformEnv[envVar]);
  }
  return env;
}

class ReplCommand extends Command {
  @override
  final name = 'repl';
  @override
  final description = 'Start a PiLisp REPL.';

  final PLEnv env;

  ReplCommand(this.env) {
    argParser
      ..addFlag('rich',
          abbr: 'r',
          defaultsTo: true,
          help:
              'Rich REPL with line editing, ANSI colors, and auto-completion.')
      ..addMultiOption('load',
          abbr: 'l',
          help:
              'Load files into the PiLisp environment before starting the REPL.')
      ..addMultiOption('eval',
          abbr: 'e',
          help:
              'Eval expressions in the PiLisp environment after files passed via -l/--load, but before starting the REPL.')
      ..addFlag('env-vars',
          help:
              'If true, create env/ bindings for all system environment variables via Platform.environment',
          defaultsTo: false);
  }

  @override
  FutureOr? run() {
    final ar = argResults!;
    if (ar['env-vars']) {
      bindingsForEnvironment(env);
    }
    final filesToLoad = ar['load'];
    if (filesToLoad is Iterable<String>) {
      for (final file in filesToLoad) {
        loadFile(env, file);
      }
    }
    final exprsToEval = ar['eval'];
    if (exprsToEval is Iterable<String>) {
      handleEval(env, exprsToEval, shouldPrint: false);
    }
    repl(env, isRich: argResults!['rich']);
  }
}

class LoadCommand extends Command {
  @override
  final name = 'load';
  @override
  final description = 'Load PiLisp code saved in files.';

  final PLEnv env;

  LoadCommand(this.env) {
    argParser
      ..addMultiOption('evalBefore',
          abbr: 'b',
          help:
              'Eval expressions in the PiLisp environment before loading the file(s).')
      ..addMultiOption('evalAfter',
          abbr: 'a',
          help:
              'Eval expressions in the PiLisp environment after loading the file(s).')
      // Feature: URIs
      ..addMultiOption('file',
          abbr: 'f', help: 'File with PiLisp code to load.')
      ..addFlag('env-vars',
          help:
              'If true, create env/ bindings for all system environment variables via Platform.environment',
          defaultsTo: false);
  }

  @override
  FutureOr? run() {
    final ar = argResults!;
    if (ar['env-vars']) {
      bindingsForEnvironment(env);
    }
    final beforeExprs = ar['evalBefore'];
    if (beforeExprs is Iterable<String>) {
      handleEval(env, beforeExprs, shouldPrint: false);
    }

    final files = ar['file'];
    if (files is Iterable<String>) {
      for (final file in files) {
        loadFile(env, file);
      }
    }

    final afterExprs = ar['evalBefore'];
    if (afterExprs is Iterable<String>) {
      handleEval(env, afterExprs, shouldPrint: true);
    }
  }
}

class EvalCommand extends Command {
  @override
  final name = 'eval';
  @override
  final description = 'Evaluate PiLisp code passed as arguments.';

  final PLEnv env;

  EvalCommand(this.env) {
    argParser
      ..addMultiOption('load',
          abbr: 'l',
          help:
              'Load files into the PiLisp environment before evaluating other arguments.')
      ..addFlag('env-vars',
          help:
              'If true, create env/ bindings for all system environment variables via Platform.environment',
          defaultsTo: false);
  }

  @override
  FutureOr? run() {
    final ar = argResults!;
    if (ar['env-vars']) {
      bindingsForEnvironment(env);
    }
    final filesToLoad = ar['load'];
    if (filesToLoad is Iterable<String>) {
      for (final file in filesToLoad) {
        loadFile(env, file);
      }
    }
    handleEval(env, ar.rest, shouldPrint: true);
  }
}

/// A proxy for your [main] function, if you want this package to handle all of
/// your command-line arguments.
void cliMain(PLEnv env, List<String> mainArgs) async {
  final exeName = 'pl';
  final exeDesc = 'Run a PiLisp REPL, or try the subcommands for more options.';
  PiLisp.loadString('''
(def *command-line-args* '[${mainArgs.map((e) => '"${e.replaceAll('"', '\\"')}"').join(' ')}])
''', env: env);
  List<String> effectiveArgs = List<String>.from(mainArgs);
  if (effectiveArgs.isEmpty || effectiveArgs.first.startsWith('-')) {
    effectiveArgs.insert(0, 'repl');
  }
  CommandRunner(exeName, exeDesc)
    ..addCommand(ReplCommand(env))
    ..addCommand(LoadCommand(env))
    ..addCommand(EvalCommand(env))
    ..run(effectiveArgs).catchError((error) {
      if (error is! UsageException) throw error;
      stderr.writeln(error);
      exit(64);
    });
}
