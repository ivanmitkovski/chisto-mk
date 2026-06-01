/// Cursor/page state for list screens with a load-more affordance.
class PaginatedLoadMoreState<TItem> {
  const PaginatedLoadMoreState({
    this.items = const <Never>[],
    this.nextCursor,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final List<TItem> items;
  final String? nextCursor;
  final bool loadingMore;
  final Object? loadMoreError;

  bool get canLoadMore => nextCursor != null && !loadingMore;

  PaginatedLoadMoreState<TItem> copyWith({
    List<TItem>? items,
    String? nextCursor,
    bool? loadingMore,
    Object? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return PaginatedLoadMoreState<TItem>(
      items: items ?? this.items,
      nextCursor: nextCursor ?? this.nextCursor,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreError: clearLoadMoreError
          ? null
          : (loadMoreError ?? this.loadMoreError),
    );
  }
}

/// Outcome of a single load-more fetch (used by app-layer Riverpod notifiers).
class PaginatedLoadMoreResult<TItem> {
  const PaginatedLoadMoreResult({
    required this.items,
    required this.nextCursor,
  });

  final List<TItem> items;
  final String? nextCursor;
}

/// Applies a load-more page to [previous], surfacing [error] on failure.
PaginatedLoadMoreState<TItem> paginatedLoadMoreTransition<TItem>({
  required PaginatedLoadMoreState<TItem> previous,
  PaginatedLoadMoreResult<TItem>? success,
  Object? error,
}) {
  if (error != null) {
    return previous.copyWith(loadingMore: false, loadMoreError: error);
  }
  final PaginatedLoadMoreResult<TItem> page = success!;
  return previous.copyWith(
    items: <TItem>[...previous.items, ...page.items],
    nextCursor: page.nextCursor,
    loadingMore: false,
    clearLoadMoreError: true,
  );
}
