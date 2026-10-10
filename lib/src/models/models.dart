import '../rules/move_rules.dart';
import 'dto.dart';
import 'validation.dart';
import 'value_objects.dart';

part 'checks.dart';

part 'domain_value.dart';
part 'stats.dart';
part 'stat_stages.dart';
part 'pokemon_profile.dart';
part 'pokemon_state.dart';
part 'move.dart';
part 'battle_field.dart';
part 'attack.dart';
part 'entry_hazards.dart';
part 'battle_setup.dart';
part 'calculation_limits.dart';
part 'damage_request.dart';
part 'combined_damage_request.dart';
part 'damage_weights.dart';

T _checked<T>(Validation<T> result) => (result as Valid<T>).value;

bool _equal(Object? a, Object? b) {
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_equal(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_equal(a[key], b[key])) return false;
    }
    return true;
  }
  if (a is Set && b is Set) return a.length == b.length && a.containsAll(b);
  return a == b;
}

int _hash(Object? value) => switch (value) {
  final List value => Object.hashAll(value.map(_hash)),
  final Map value => Object.hashAllUnordered(
    value.entries.map((e) => Object.hash(_hash(e.key), _hash(e.value))),
  ),
  final Set value => Object.hashAllUnordered(value.map(_hash)),
  _ => value.hashCode,
};
