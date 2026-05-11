import 'package:anki_multi/core/database/database.dart' as db;
import 'package:drift/drift.dart' show Value;
import 'package:fsrs/fsrs.dart' as fsrs;

DateTime _utcFromMillis(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

/// drift [row] → fsrs.Card（用于调用 [fsrs.Scheduler.reviewCard]）。
fsrs.Card driftRowToFsrs(db.Card row) {
  final due = _utcFromMillis(row.due);
  final lastReview = row.lastReview != null
      ? _utcFromMillis(row.lastReview!)
      : null;

  if (row.state == 0) {
    return fsrs.Card(
      cardId: row.id,
      state: fsrs.State.learning,
      step: 0,
      stability: null,
      difficulty: null,
      due: due,
      lastReview: lastReview,
    );
  }

  final step =
      (row.state == 1 || row.state == 3) ? (row.learningStep ?? 0) : null;

  return fsrs.Card(
    cardId: row.id,
    state: fsrs.State.fromValue(row.state),
    step: step,
    stability: row.stability > 0 ? row.stability : null,
    difficulty: row.difficulty > 0 ? row.difficulty : null,
    due: due,
    lastReview: lastReview,
  );
}

/// 将 [rated]（[fsrs.Scheduler.reviewCard] 输出）与评分时刻 [reviewUtc] 同步到 drift [db.CardsCompanion]。
/// [prev]：评分前的行，用于计算 elapsed / lastElapsed、reps、lapses。
db.CardsCompanion fsrsResultToCompanion({
  required db.Card prev,
  required fsrs.Card rated,
  required DateTime reviewUtc,
  required fsrs.Rating rating,
  required int nowMillis,
}) {
  final lastReviewMs = rated.lastReview!.millisecondsSinceEpoch;
  final prevLastUtc = prev.lastReview != null
      ? _utcFromMillis(prev.lastReview!)
      : null;
  final elapsedDays = prevLastUtc != null
      ? reviewUtc.difference(prevLastUtc).inDays
      : 0;

  var scheduledDays = rated.due.difference(reviewUtc).inDays;
  if (scheduledDays < 0) {
    scheduledDays = 0;
  }
  if (scheduledDays > 365000) {
    scheduledDays = 365000;
  }

  var reps = prev.reps + 1;
  var lapses = prev.lapses;
  if (rating == fsrs.Rating.again) {
    lapses += 1;
  }

  return db.CardsCompanion(
    due: Value(rated.due.millisecondsSinceEpoch),
    stability: Value(rated.stability ?? 0),
    difficulty: Value(rated.difficulty ?? 0),
    elapsedDays: Value(elapsedDays),
    scheduledDays: Value(scheduledDays),
    reps: Value(reps),
    lapses: Value(lapses),
    state: Value(rated.state.value),
    learningStep: Value(rated.step),
    lastReview: Value(lastReviewMs),
    updatedAt: Value(nowMillis),
  );
}
