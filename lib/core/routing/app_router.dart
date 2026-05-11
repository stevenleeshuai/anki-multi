import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/cards/presentation/pages/card_edit_page.dart';
import '../../features/review/presentation/pages/review_page.dart';
import '../../features/decks/presentation/pages/deck_detail_page.dart';
import '../../features/decks/presentation/pages/deck_edit_page.dart';
import '../../features/decks/presentation/pages/deck_list_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DeckListPage(),
      ),
      GoRoute(
        path: '/decks/new',
        builder: (context, state) => const DeckEditPage(),
      ),
      GoRoute(
        path: '/decks/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return DeckDetailPage(deckId: id);
        },
      ),
      GoRoute(
        path: '/decks/:id/study',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ReviewPage(deckId: id);
        },
      ),
      GoRoute(
        path: '/decks/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return DeckEditPage(deckId: id);
        },
      ),
      GoRoute(
        path: '/decks/:id/cards/new',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return CardEditPage(deckId: id);
        },
      ),
      GoRoute(
        path: '/cards/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return CardEditPage(editingCardId: id);
        },
      ),
    ],
  );
});
