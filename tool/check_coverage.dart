import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

// VMの行・分岐レポートを両方確認し、分岐レポートの欠落も失敗にする。
// パッケージの実行可能な実装ファイルや行は除外しない。
void main(List<String> args) {
  final report = jsonDecode(File(args.single).readAsStringSync()) as Map;
  final entries = report['coverage'] as List;
  final missing = <String>[];
  var lines = 0;
  var branches = 0;
  final sources = <String>{};
  final merged = <String, Map<String, Map<int, int>>>{};
  for (final entry in entries.cast<Map>()) {
    final source = entry['source'] as String;
    if (!source.startsWith('package:pokemon_damage_calculator_core/')) continue;
    sources.add(source);
    for (final key in ['hits', 'branchHits']) {
      final hits = entry[key] as List?;
      if (hits == null || hits.isEmpty) {
        missing.add('$source: missing $key');
        continue;
      }
      final byLine = merged
          .putIfAbsent(source, () => {})
          .putIfAbsent(key, () => {});
      for (var i = 0; i < hits.length; i += 2) {
        final line = hits[i] as int;
        byLine[line] = (byLine[line] ?? 0) + (hits[i + 1] as int);
      }
    }
  }
  // dart testはファイルごとに別のisolateで実行する。
  // LCOV整形と同様に実行結果の和集合を取る。
  for (final source in merged.entries) {
    for (final metric in source.value.entries) {
      for (final hit in metric.value.entries) {
        if (metric.key == 'hits') {
          lines++;
        } else {
          branches++;
        }
        if (hit.value == 0) {
          missing.add('${source.key}:${hit.key} (${metric.key})');
        }
      }
    }
  }
  for (final file in Directory(
    'lib',
  ).listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;
    final unit = parseString(content: file.readAsStringSync()).unit;
    final executable = unit.declarations.any((declaration) {
      // 定数だけのenumには、Dart VMが計測する実行可能な本体がない。
      // メソッドや実行時の初期化を持つenumは、引き続き収集必須にする。
      if (declaration is EnumDeclaration) {
        return declaration.body.members.any(
          (member) =>
              member is MethodDeclaration &&
                  member.body is! EmptyFunctionBody ||
              member is ConstructorDeclaration &&
                  member.body is! EmptyFunctionBody ||
              member is FieldDeclaration &&
                  member.isStatic &&
                  !member.fields.isConst &&
                  member.fields.variables.any(
                    (field) => field.initializer != null,
                  ),
        );
      }
      return declaration is! TopLevelVariableDeclaration ||
          !declaration.variables.isConst;
    });
    final path = file.path.substring(4).replaceAll('\\', '/');
    if (executable &&
        !sources.contains('package:pokemon_damage_calculator_core/$path')) {
      missing.add('Missing implementation: $path');
    }
  }
  if (lines == 0 || branches == 0 || missing.isNotEmpty) {
    stderr.writeln(
      'Coverage must be 100% for lines and branches:\n${missing.join('\n')}',
    );
    exitCode = 1;
    return;
  }
  stdout.writeln(
    '100% lines ($lines/$lines), 100% VM branches ($branches/$branches).',
  );
}
