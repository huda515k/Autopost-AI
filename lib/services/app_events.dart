import 'package:flutter/foundation.dart';

/// Lightweight app-wide event bus for social data changes.
///
/// Any screen that displays likes / comments / posts can listen to
/// [revision] and reload itself whenever the data changes anywhere in the
/// app (e.g. someone likes or comments on a post in the feed). Services call
/// [notifyDataChanged] after a successful mutation.
class AppEvents {
  AppEvents._();

  static final AppEvents instance = AppEvents._();

  /// Bumped every time social data is mutated. Listeners reload on change.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  void notifyDataChanged() => revision.value++;
}
