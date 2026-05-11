import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../../../core/database/database_provider.dart';
import 'review_service.dart';

final fsrsSchedulerProvider = Provider<fsrs.Scheduler>((ref) {
  return fsrs.Scheduler(
    enableFuzzing: true,
  );
});

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService(
    ref.watch(databaseProvider),
    ref.watch(fsrsSchedulerProvider),
  );
});
