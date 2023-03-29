/// PiLisp CLI
///
/// A rudimentary CLI entry-point for the PiLisp language. Originally designed
/// for use with the core pilisp language package as well as pilisp-native.
///
/// Use the `cliMain` function from your Dart program's `main` function. See the
/// README for details.
///
/// Alternatively, use these functions directly as needed:
///
///   * [repl] expects a [PLEnv] instance and starts an interactive PiLisp REPL
///   * [loadFile] expects a [PLEnv] instance, a [String] path to a file on your
///     computer, and an [Iterable<String>] of arguments that will be bound to
///     the `*command-line-args*` symbol in PiLisp for your script.
library pilisp_cli;

export 'src/pilisp_cli_public.dart';
