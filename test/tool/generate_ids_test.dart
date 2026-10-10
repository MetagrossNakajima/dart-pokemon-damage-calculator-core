import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import '../../tool/generate_ids.dart' as generator;
import '../support/id_generator_fixtures.dart' as ids;

void main() {
  test(
    'acronyms and interpolation symbols generate valid exact Dart literals',
    () {
      final generated = generator.generateIds(
        ids.input(moves: [r'Future$Move']),
      );
      expect(generator.constantName('RKSSystem'), 'rksSystem');
      expect(
        generated['lib/src/models/value_objects/ability_id.dart'],
        contains('static const staticAbility'),
      );
      expect(
        generated['lib/src/models/value_objects/move_id.dart'],
        contains(r'Future\$Move'),
      );
    },
  );

  test(
    'generation is deterministic with explicit naming overrides and numeric prefix',
    () {
      final source = ids.input(
        moves: ['TeraBlast', '10000000VoltThunderbolt', 'Return'],
      );
      final a = generator.generateIds(source);
      expect(generator.generateIds(source), a);
      expect(
        a['lib/src/models/value_objects/move_id.dart'],
        contains('static const teraBlast'),
      );
      expect(
        a['lib/src/models/value_objects/move_id.dart'],
        contains('static const id10000000VoltThunderbolt'),
      );
      expect(
        a['lib/src/models/value_objects/move_id.dart'],
        contains('static const returnMove'),
      );
      expect(
        a['lib/src/models/value_objects/pokemon_id.dart'],
        contains('nidoranFemale'),
      );
      expect(
        a['lib/src/models/value_objects/pokemon_id.dart'],
        contains('nidoranMale'),
      );
      expect(
        a['lib/src/models/value_objects/item_id.dart'],
        contains('heavyDutyBoots'),
      );
    },
  );

  test(
    'generator rejects malformed input duplicate IDs and unresolved names',
    () {
      for (final bad in <Object?>[
        null,
        [],
        {},
        {...ids.input(), 'unexpected': []},
        {...ids.input()}..remove('item'),
        {...ids.input(), 'move': 'TeraBlast'},
        ids.input(moves: []),
        ids.input(moves: ['']),
        ids.input(moves: [42]),
        ids.input(moves: ['TeraBlast', 'TeraBlast']),
        ids.input(moves: ['Foo-Bar', 'FooBar']),
        ids.input(moves: ['Class']),
        ids.input(moves: ['KnownValues']),
        ids.input(moves: ['α']),
      ]) {
        expect(
          () => generator.generateIds(bad),
          throwsFormatException,
          reason: '$bad',
        );
      }
    },
  );

  test(
    'CLI regenerates offline and check detects missing or stale files',
    () async {
      final script = File('tool/generate_ids.dart').absolute.path;
      final dir = Directory.systemTemp.createTempSync('id-generator-test-');
      addTearDown(() => dir.deleteSync(recursive: true));
      Directory(p.join(dir.path, 'data')).createSync();
      Directory(
        p.join(dir.path, 'lib', 'src', 'models', 'value_objects'),
      ).createSync(recursive: true);
      File(
        '${dir.path}/data/known_ids.json',
      ).writeAsStringSync(jsonEncode(ids.input()));
      Future<ProcessResult> run(List<String> args) => Process.run(
        Platform.resolvedExecutable,
        [script, ...args],
        workingDirectory: dir.path,
      );
      expect((await run(['--invalid'])).exitCode, 64);
      expect((await run(['--check'])).exitCode, 1);
      expect((await run([])).exitCode, 0);
      expect((await run(['--check'])).exitCode, 0);
      final target = File(
        p.join(
          dir.path,
          'lib',
          'src',
          'models',
          'value_objects',
          'move_id.dart',
        ),
      );
      final before = target.readAsStringSync();
      expect((await run([])).exitCode, 0);
      expect(target.readAsStringSync(), before);
      target.writeAsStringSync('$before\n// stale\n');
      final stale = await run(['--check']);
      expect(stale.exitCode, 1);
      expect(stale.stderr, contains('move_id.dart'));
      expect(target.readAsStringSync(), endsWith('// stale\n'));
    },
  );
}
