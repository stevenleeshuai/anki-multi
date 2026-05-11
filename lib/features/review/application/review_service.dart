import 'package:anki_multi/core/database/daos/cards_dao.dart';
import 'package:anki_multi/core/database/database.dart' as db;
import 'package:anki_multi/features/review/domain/fsrs_card_mapper.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

class ReviewService {
  ReviewService(this._db, this._scheduler);

  final db.AppDatabase _db;
  final fsrs.Scheduler _scheduler;

  Future<CardWithNote?> peekNextDue(int deckId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.cardsDao.getNextDueWithNote(deckId: deckId, nowMillis: now);
  }

  Future<void> rateCard({
    required int deckId,
    required int cardId,
    required fsrs.Rating rating,
  }) async {
    final reviewUtc = DateTime.now().toUtc();
    final nowMillis = DateTime.now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      final row = await _db.cardsDao.getById(cardId);
      if (row == null || row.deckId != deckId) {
        throw ArgumentError('card not in deck');
      }

      final fsrsCard = driftRowToFsrs(row);
      final rated = _scheduler
          .reviewCard(
            fsrsCard,
            rating,
            reviewDateTime: reviewUtc,
          )
          .card;

      final companion = fsrsResultToCompanion(
        prev: row,
        rated: rated,
        reviewUtc: reviewUtc,
        rating: rating,
        nowMillis: nowMillis,
      );

      await _db.cardsDao.updateCard(cardId, companion);

      await _db.reviewsDao.insertReview(
        db.ReviewsCompanion.insert(
          cardId: cardId,
          reviewedAt: reviewUtc.millisecondsSinceEpoch,
          rating: rating.value,
          state: rated.state.value,
          due: rated.due.millisecondsSinceEpoch,
          stability: rated.stability ?? 0,
          difficulty: rated.difficulty ?? 0,
          elapsedDays: companion.elapsedDays.value,
          lastElapsedDays: row.elapsedDays,
          scheduledDays: companion.scheduledDays.value,
        ),
      );
    });
  }
}
