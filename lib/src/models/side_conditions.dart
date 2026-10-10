part of 'dto.dart';

/// 片側の場に有効な、ダメージ軽減条件。
final class SideConditions {
  const SideConditions({this.reflect = false, this.lightScreen = false});
  final bool reflect;
  final bool lightScreen;

  @override
  bool operator ==(Object other) =>
      other is SideConditions &&
      reflect == other.reflect &&
      lightScreen == other.lightScreen;

  @override
  int get hashCode => Object.hash(reflect, lightScreen);
}
