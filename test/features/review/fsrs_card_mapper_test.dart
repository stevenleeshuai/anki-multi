import 'dart:math' as math;

import 'package:anki_multi/core/database/database.dart';
import 'package:anki_multi/features/review/domain/fsrs_card_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

void main() {
  test('state 0 映射为 fsrs learning + null S/D', () {
    const row = Card(
      id: 1,
      noteId: 1,
      deckId: 1,
      templateIdx: 0,
      due: 1000,
      stability: 0,
      difficulty: 0,
      elapsedDays: 0,
      scheduledDays: 0,
      reps: 0,
      lapses: 0,
      state: 0,
      learningStep: null,
      lastReview: null,
      createdAt: 1000,
      updatedAt: 1000,
    );

    final c = driftRowToFsrs(row);

    expect(c.state, fsrs.State.learning);
    expect(c.step, 0);
    expect(c.stability, isNull);
    expect(c.difficulty, isNull);
  });

  test('reviewCard 后 stability/difficulty 建立且 due 不早于评分时刻', () {
    final scheduler = fsrs.Scheduler.customRandom(
      math.Random(0),
      enableFuzzing: false,
    );

    final reviewUtc = DateTime.now().toUtc();
    final prev = Card(
      id: 42,
      noteId: 1,
      deckId: 1,
      templateIdx: 0,
      due: reviewUtc.millisecondsSinceEpoch,
      stability: 0,
      difficulty: 0,
      elapsedDays: 0,
      scheduledDays: 0,
      reps: 0,
      lapses: 0,
      state: 0,
      learningStep: null,
      lastReview: null,
      createdAt: 1000,
      updatedAt: 1000,
    );

    final fs = driftRowToFsrs(prev);
    final rated = scheduler.reviewCard(
      fs,
      fsrs.Rating.good,
      reviewDateTime: reviewUtc,
    ).card;

    expect(rated.stability, isNotNull);
    expect(rated.difficulty, isNotNull);
    expect(
      rated.due.isAfter(reviewUtc) || rated.due.isAtSameMomentAs(reviewUtc),
      isTrue,
    );

    final companion = fsrsResultToCompanion(
      prev: prev,
      rated: rated,
      reviewUtc: reviewUtc,
      rating: fsrs.Rating.good,
      nowMillis: reviewUtc.millisecondsSinceEpoch,
    );

    expect(companion.state.value, rated.state.value);
    expect(companion.due.value, rated.due.millisecondsSinceEpoch);
  });
}
