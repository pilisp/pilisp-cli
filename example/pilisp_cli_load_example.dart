import 'package:pilisp/pilisp.dart';
import 'package:pilisp_cli/pilisp_cli.dart' as pcli;

void main() {
  // NB. The pilisp package ships with piLispEnv as the default.
  pcli.cliMain(
      piLispEnv, ['load', '--file', 'example/example.pil', 'a', 'b', 'c']);
}
