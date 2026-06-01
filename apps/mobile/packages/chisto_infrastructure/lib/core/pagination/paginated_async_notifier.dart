import 'package:chisto_core/chisto_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod base for cursor-paginated lists with [loadMore].
abstract class PaginatedAsyncNotifier<TItem>
    extends AutoDisposeNotifier<PaginatedLoadMoreState<TItem>> {
  @override
  PaginatedLoadMoreState<TItem> build() => PaginatedLoadMoreState<TItem>();

  /// First page; subclasses set phase-specific loading flags if needed.
  Future<void> loadInitial();

  /// Fetches the next page using [state.nextCursor].
  Future<void> loadMore() async {
    if (!state.canLoadMore) return;
    final PaginatedLoadMoreState<TItem> previous = state;
    state = previous.copyWith(loadingMore: true, clearLoadMoreError: true);
    try {
      final PaginatedLoadMoreResult<TItem> page = await fetchPage(
        cursor: previous.nextCursor,
      );
      state = paginatedLoadMoreTransition<TItem>(
        previous: previous,
        success: page,
      );
    } catch (e) {
      state = paginatedLoadMoreTransition<TItem>(
        previous: previous,
        error: mapLoadMoreError(e),
      );
    }
  }

  Future<PaginatedLoadMoreResult<TItem>> fetchPage({required String? cursor});

  /// Maps thrown values to [PaginatedLoadMoreState.loadMoreError].
  Object mapLoadMoreError(Object error) => error;
}
