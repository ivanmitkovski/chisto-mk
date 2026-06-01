// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_draft_summary_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$reportDraftSummaryNotifierHash() =>
    r'400d9a8472233c7fd1b673cb1fc04dcb3fc2f82f';

/// Latest wizard draft summary for resume UI (backed by [ReportDraftRepository]).
///
/// Copied from [ReportDraftSummaryNotifier].
@ProviderFor(ReportDraftSummaryNotifier)
final reportDraftSummaryNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      ReportDraftSummaryNotifier,
      ReportDraftSummary
    >.internal(
      ReportDraftSummaryNotifier.new,
      name: r'reportDraftSummaryNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$reportDraftSummaryNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ReportDraftSummaryNotifier =
    AutoDisposeAsyncNotifier<ReportDraftSummary>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
