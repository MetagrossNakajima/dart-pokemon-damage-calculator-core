part of 'models.dart';

/// 構造による等価性を持つ、不変のドメイン値。
abstract base class DomainValue {
  const DomainValue();
  List<Object?> get _properties;
  @override
  bool operator ==(Object other) =>
      other is DomainValue &&
      runtimeType == other.runtimeType &&
      _equal(_properties, other._properties);
  @override
  int get hashCode => Object.hash(runtimeType, _hash(_properties));
}
