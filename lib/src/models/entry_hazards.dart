part of 'models.dart';

final class EntryHazards extends DomainValue {
  const EntryHazards._(this.stealthRock, this.spikesLayers);

  final bool stealthRock;
  final SpikesLayers spikesLayers;

  static Validation<EntryHazards> fromDto(EntryHazardsDto input) {
    final checks = _Checks();
    return checks.finish(_checkHazards(checks, input, 'entryHazards'));
  }

  EntryHazardsDto get toDto => EntryHazardsDto(
    stealthRock: stealthRock,
    spikesLayers: spikesLayers.value,
  );

  @override
  List<Object?> get _properties => [stealthRock, spikesLayers];
}
