import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/reviews_table.dart';

part 'reviews_dao.g.dart';

@DriftAccessor(tables: [Reviews])
class ReviewsDao extends DatabaseAccessor<AppDatabase> with _$ReviewsDaoMixin {
  ReviewsDao(super.db);

  Future<int> insertReview(ReviewsCompanion entry) => into(reviews).insert(entry);
}
