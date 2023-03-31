import 'package:pilisp/pilisp.dart';
import 'package:pilisp_cli/pilisp_cli.dart';
import 'package:test/test.dart';

void main() {
  group('pilisp_cli', () {
    test('loadFile', () async {
      await loadFile(piLispEnv, 'test/pilisp_cli_test.pil', []);
      expect(PiLisp.loadString('test-answer'), 42);
    });
  });
}
