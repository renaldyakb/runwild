import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/interval/interval_engine.dart';

final intervalSelectionProvider =
    NotifierProvider<IntervalSelection, IntervalConfig?>(IntervalSelection.new);

class IntervalSelection extends Notifier<IntervalConfig?> {
  @override
  IntervalConfig? build() => null;

  void select(IntervalConfig? config) => state = config;
}
