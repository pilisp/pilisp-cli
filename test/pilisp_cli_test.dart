import 'package:pilisp/pilisp.dart';
import 'package:pilisp_cli/pilisp_cli.dart';
import 'package:test/test.dart';

void main() {
  group('pilisp_cli', () {
    group('loadFile', () {
      test('environment is mutated', () async {
        expect(await loadFile(piLispEnv, 'test/pilisp_cli_test.pil', []), 42);
        expect(PiLisp.loadString('test-answer'), 42);
      });
      test('future/await is awaited', () async {
        expect(await loadFile(piLispEnv, 'test/pilisp_cli_await_test.pil', []),
            21);
      });
    });
  });
}
