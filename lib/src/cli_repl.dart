library cli_repl;

import 'dart:async';

import 'package:pilisp/pilisp.dart';

import 'cli_repl/repl_adapter.dart';

class Repl {
  /// The PiLisp environment for evaluation at this REPL
  PLEnv env;

  /// Text displayed when prompting the user for a new statement.
  String prompt;

  /// Text displayed at start of continued statement line.
  String continuation;

  /// Called when a newline is entered to determine whether the queue a
  /// completed statement or allow for a continuation.
  StatementValidator validator;

  Repl(
      {required this.env,
      this.prompt = '',
      String? continuation,
      StatementValidator? validator,
      this.maxHistory = 50})
      : continuation = continuation ?? ' ' * prompt.length,
        validator = validator ?? alwaysValid {
    _adapter = ReplAdapter(this);
  }

  late ReplAdapter _adapter;

  /// Run the REPL, yielding complete statements synchronously.
  Iterable<String> run() => _adapter.run();

  /// Run the REPL, yielding complete statements asynchronously.
  ///
  /// Note that the REPL will continue if you await in an "await for" loop.
  Stream<String> runAsync() => _adapter.runAsync();

  /// Kills and cleans up the REPL.
  FutureOr<void> exit() => _adapter.exit();

  Iterable<String> completionsFor(String prefix) => env.completionsFor(prefix);

  void clearBuffer() => _adapter.clearBuffer();

  void rewriteBuffer() => _adapter.rewriteBuffer();

  /// History is by line, not by statement.
  ///
  /// The first item in the list is the most recent history item.
  List<String> history = [];

  /// Maximum history that will be kept in the list.
  ///
  /// Defaults to 50.
  int maxHistory;
}

/// Returns true if [text] is a complete statement or false otherwise.
typedef StatementValidator = bool Function(String text);

bool alwaysValid(String text) => true;
