part of 'models.dart';

final class PokemonProfile extends DomainValue {
  const PokemonProfile._(this.id, this.types, this.weight, this.gender);

  final PokemonId id;
  final List<PokemonType> types;
  final PokemonWeight weight;
  final Gender gender;

  static Validation<PokemonProfile> fromDto(PokemonProfileDto input) {
    final checks = _Checks();
    return checks.finish(_checkProfile(checks, input, 'pokemonProfile'));
  }

  PokemonProfileDto get toDto => PokemonProfileDto(
    id: id,
    types: types,
    weight: weight.value,
    gender: gender,
  );

  @override
  List<Object?> get _properties => [id, types, weight, gender];
}
