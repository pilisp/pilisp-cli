import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:pilisp/pilisp.dart';

import '../pilisp_cli.dart';

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

Future<Object?> handleEval(PLEnv env, Iterable<String> evalArgs,
    {bool shouldPrint = false}) async {
  final l = evalArgs.toList();
  Object? finalRet;
  for (var i = 0; i < l.length; i++) {
    final program = l[i];
    final ret = PiLisp.loadString(program, env: env);
    Object? effectiveRet;
    if (ret is PLAwait) {
      effectiveRet = await ret.value;
    } else {
      effectiveRet = ret;
    }
    if (i == l.length - 1 &&
        effectiveRet != PLNil() &&
        effectiveRet != null &&
        shouldPrint) {
      print(PiLisp.printToString(effectiveRet));
    }
    finalRet = effectiveRet;
  }
  return finalRet;
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
      ..addMultiOption('eval-before',
          abbr: 'b',
          help:
              'Eval expressions in the PiLisp environment before loading the file(s).')
      ..addMultiOption('eval-after',
          abbr: 'a',
          help:
              'Eval expressions in the PiLisp environment after loading the file(s).')
      // Feature: URIs
      ..addMultiOption('file',
          abbr: 'f', help: 'File with PiLisp code to load.')
      ..addFlag('env-vars',
          help:
              'If true, create env/ bindings for all system environment variables via Platform.environment',
          defaultsTo: false)
      ..addFlag('print',
          abbr: 'p',
          help:
              'If true, prints the last thing evaluated (whether the last file loaded, or --eval-after expression).',
          defaultsTo: true);
  }

  @override
  FutureOr? run() async {
    final ar = argResults!;
    final files = ar['file'];
    if (files is Iterable<String> && files.isEmpty) {
      stderr.writeln(
          'You must supply at least one --file argument to the load command.');
      exit(64);
    }

    env.isScript = true;

    if (ar['env-vars']) {
      bindingsForEnvironment(env);
    }
    final beforeExprs = ar['eval-before'];
    if (beforeExprs is Iterable<String>) {
      await handleEval(env, beforeExprs, shouldPrint: false);
    }

    Object? finalLoadRet;
    if (files is Iterable<String>) {
      for (final file in files) {
        finalLoadRet = await loadFile(env, file);
      }
    }

    final afterExprs = ar['eval-after'];
    Object? finalEvalRet;
    if (afterExprs is Iterable<String>) {
      finalEvalRet = await handleEval(env, afterExprs, shouldPrint: false);
    }

    final ret = finalLoadRet ?? finalEvalRet;
    if (ret != null && ret != PLNil() && ar['print']) {
      print(PiLisp.printToString(ret));
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
          defaultsTo: false)
      ..addFlag('print',
          abbr: 'p',
          help:
              'If true, prints the last thing evaluated (whether the last file loaded, or --eval-after expression).',
          defaultsTo: true);
  }

  @override
  FutureOr? run() {
    env.isScript = true;

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
    handleEval(env, ar.rest, shouldPrint: ar['print']);
  }
}

final dartCompileCoreSourceTemplate = r'''
import 'package:pilisp/pilisp.dart';

final env = piLispEnv.loadString(r"""
{{PROGRAM_SOURCE}}
""");

void main(List<String> args) {
   PiLisp.loadString("""
(def *command-line-args* '[${args.map((e) => '"${e.replaceAll('"', '\\"')}"').join(' ')}])
(apply main *command-line-args*)
""", env: env);
}

''';

class CompileExeCommand extends Command {
  @override
  final name = 'exe';
  @override
  final description =
      'Create a self-contained executable from a PiLisp program.';

  CompileExeCommand() {
    argParser
      ..addOption('output',
          abbr: 'o',
          help: 'Write the compiled executable to the provided file name.',
          defaultsTo: 'build/pl-script-exe')
      ..addFlag('source-only',
          abbr: 's',
          negatable: false,
          defaultsTo: false,
          help:
              'Only write the Dart source wrapper for compiling the PiLisp program, do not immediately compile it.')
      ..addOption('verbosity',
          help: 'Set the verbosity of the underlying Dart compilation.',
          allowed: ['all', 'error', 'info', 'warning'],
          defaultsTo: 'all');
  }

  @override
  FutureOr? run() async {
    final ar = argResults!;
    final rest = ar.rest;
    if (rest.isEmpty) {
      stderr.writeln('You must provide a file to compile.');
      exit(64);
    } else {
      final outputFilePath = ar['output'];
      final verbosity = ar['verbosity'];
      final pilispFilePath = rest[0];
      final programSource = await File(pilispFilePath).readAsString();
      final dartFile = await File('build/pilisp_compile_source.dart')
          .create(recursive: true);
      dartFile.writeAsString(dartCompileCoreSourceTemplate.replaceFirst(
          '{{PROGRAM_SOURCE}}', programSource));
      // dart compile exe -o pl ./bin/cli.dart
      if (ar['source-only']) {
        print('Finished writing Dart wrapper to ${dartFile.path}');
      } else {
        Process.run('dart', [
          'compile',
          'exe',
          '-o',
          outputFilePath,
          '--verbosity',
          verbosity,
          dartFile.path,
        ]);
      }
    }
  }
}

class CompileCommand extends Command {
  @override
  final name = 'compile';
  @override
  final description = 'Compile a PiLisp program as a Dart program.';

  CompileCommand() {
    addSubcommand(CompileExeCommand());
  }

  @override
  FutureOr? run() {
    final ar = argResults!;
    ar;
  }
}
