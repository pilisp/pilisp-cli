import 'package:pilisp/pilisp.dart';
import 'package:pilisp_cli/pilisp_cli.dart' as pcli;

void main(List<String> args) async {
  // Start a REPL
  await pcli.repl(piLispEnv, isRich: true);
}
