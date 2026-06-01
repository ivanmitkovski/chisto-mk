library;

import 'dart:async';

import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/app_error_localizations.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/widgets/state_rebuild_mixin.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_back_button.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/application/events_providers.dart';
import 'package:feature_events/src/data/organizer_quiz_payload.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'organizer_quiz/organizer_quiz_models.dart';
part 'organizer_quiz/organizer_quiz_question_page.dart';
part 'organizer_quiz/organizer_quiz_result_screen.dart';

/// Pops the current route after it is fully installed.
///
/// Calling [Navigator.pop]/[Navigator.maybePop] in the first [addPostFrameCallback]
/// after [Navigator.push] can hit `ModalRoute` `scope != null` assertions because the
/// route's modal scope is not ready yet. Scheduling two frames defers until safe.
void _scheduleNavigatorPopWhenRouteReady(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }
      final NavigatorState? nav = Navigator.maybeOf(context);
      if (nav != null && nav.canPop()) {
        nav.pop();
      }
    });
  });
}

Future<void> _persistOrganizerCertifiedAt(WidgetRef ref, DateTime at) async {
  if (!ref.read(appBootstrapProvider).isInitialized) {
    return;
  }
  await ref.read(tokenStorageProvider).writeOrganizerCertifiedAt(at);
}

class OrganizerQuizScreen extends ConsumerStatefulWidget {
  const OrganizerQuizScreen({super.key, this.onCertified});

  final VoidCallback? onCertified;

  @override
  ConsumerState<OrganizerQuizScreen> createState() =>
      _OrganizerQuizScreenState();
}

class _OrganizerQuizScreenState extends ConsumerState<OrganizerQuizScreen>
    with StateRebuildMixin {
  String? _quizSession;
  List<_QuizQuestion>? _questions;
  final Map<String, String> _selectedOptionByQuestionId = <String, String>{};
  String? _loadErrorDetail;
  bool _loading = true;
  bool _loadFailed = false;
  bool _submitting = false;
  _QuizResult? _result;

  @override
  void initState() {
    super.initState();
    final AuthState auth = ref.read(authStateProvider);
    if (ref.read(appBootstrapProvider).isInitialized &&
        auth.isOrganizerCertified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _scheduleNavigatorPopWhenRouteReady(context);
      });
      return;
    }
    unawaited(_fetchQuiz());
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchQuiz() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = true;
      _loadFailed = false;
      _loadErrorDetail = null;
      _quizSession = null;
      _questions = null;
      _selectedOptionByQuestionId.clear();
    });
    try {
      final payload = await ref
          .read(organizerCertificationRepositoryProvider)
          .fetchQuiz();
      final List<_QuizQuestion> parsed = <_QuizQuestion>[];
      for (final dynamic q in payload.rawQuestions) {
        final Map<String, dynamic>? qm = asJsonObject(q);
        if (qm == null) {
          if (mounted) {
            final String detail = context.l10n.organizerQuizLoadInvalidResponse;
            setState(() {
              _loading = false;
              _loadFailed = true;
              _loadErrorDetail = detail;
            });
          }
          return;
        }
        final Object? rawOpts = qm['options'];
        final List<dynamic> opts = rawOpts is List
            ? List<dynamic>.from(rawOpts)
            : const <dynamic>[];
        final List<_QuizOption> options = <_QuizOption>[];
        for (final dynamic o in opts) {
          final Map<String, dynamic>? om = asJsonObject(o);
          if (om == null) {
            if (mounted) {
              final String detail =
                  context.l10n.organizerQuizLoadInvalidResponse;
              setState(() {
                _loading = false;
                _loadFailed = true;
                _loadErrorDetail = detail;
              });
            }
            return;
          }
          options.add(
            _QuizOption(
              id: om['id'] as String? ?? '',
              text: om['text'] as String? ?? '',
            ),
          );
        }
        parsed.add(
          _QuizQuestion(
            id: qm['id'] as String? ?? '',
            text: qm['text'] as String? ?? '',
            options: options,
          ),
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _quizSession = payload.session;
        _questions = parsed;
        _loading = false;
        _loadFailed = false;
      });
    } on AppError catch (e) {
      if (!mounted) {
        return;
      }
      if (e.code == 'ORGANIZER_CERTIFICATION_ALREADY_CERTIFIED' &&
          ref.read(appBootstrapProvider).isInitialized) {
        final AuthState auth = ref.read(authStateProvider);
        if (!auth.isOrganizerCertified) {
          auth.markOrganizerCertified(DateTime.now());
        }
        await _persistOrganizerCertifiedAt(ref, DateTime.now());
        if (!mounted) {
          return;
        }
        setState(() {
          _loading = false;
          _loadFailed = false;
        });
        AppSnack.show(
          context,
          message: localizedAppErrorMessage(context.l10n, e),
          type: AppSnackType.success,
        );
        _scheduleNavigatorPopWhenRouteReady(context);
        return;
      }
      final String detail = localizedAppErrorMessage(context.l10n, e);
      setState(() {
        _loading = false;
        _loadFailed = true;
        _loadErrorDetail = detail;
      });
      AppSnack.show(context, message: detail, type: AppSnackType.warning);
    } on Object catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadFailed = true;
        _loadErrorDetail = context.l10n.organizerQuizLoadFailed;
      });
      AppSnack.show(
        context,
        message: context.l10n.organizerQuizLoadFailed,
        type: AppSnackType.warning,
      );
    }
  }

  Future<void> _submit() async {
    final List<_QuizQuestion>? questions = _questions;
    final String? session = _quizSession;
    if (questions == null || session == null) {
      return;
    }
    if (questions.length != _selectedOptionByQuestionId.length) {
      return;
    }
    if (_submitting) {
      return;
    }

    setState(() => _submitting = true);
    AppHaptics.tap();

    final List<Map<String, String>> answers = questions
        .map(
          (_QuizQuestion q) => <String, String>{
            'questionId': q.id,
            'selectedOptionId': _selectedOptionByQuestionId[q.id]!,
          },
        )
        .toList();

    try {
      final result = await ref
          .read(organizerCertificationRepositoryProvider)
          .submitCertification(quizSession: session, answers: answers);
      if (!mounted) {
        return;
      }

      final bool passed = result.passed;
      final bool alreadyCertified = result.alreadyCertified;
      final int correctCount = result.correctCount;
      final int totalQuestions = result.totalQuestions > 0
          ? result.totalQuestions
          : questions.length;
      final int pointsAwarded = result.pointsAwarded;
      final DateTime? parsed = result.organizerCertifiedAt;

      if (passed && parsed != null) {
        ref.read(authStateProvider).markOrganizerCertified(parsed);
        await _persistOrganizerCertifiedAt(ref, parsed);
      }
      if (!mounted) {
        return;
      }

      if (alreadyCertified && passed) {
        setState(() {
          _submitting = false;
          _result = _QuizResult(
            passed: true,
            correctCount: totalQuestions,
            totalQuestions: totalQuestions,
            pointsAwarded: pointsAwarded,
          );
        });
        AppHaptics.success();
        return;
      }

      setState(() {
        _result = _QuizResult(
          passed: passed,
          correctCount: correctCount,
          totalQuestions: totalQuestions,
          pointsAwarded: pointsAwarded,
        );
        _submitting = false;
      });

      if (passed) {
        AppHaptics.success();
      } else {
        AppHaptics.warning();
      }
    } on AppError catch (e) {
      if (!mounted) {
        return;
      }
      if (e.code == 'ORGANIZER_CERTIFICATION_ALREADY_CERTIFIED' &&
          ref.read(appBootstrapProvider).isInitialized) {
        ref.read(authStateProvider).markOrganizerCertified(DateTime.now());
        await _persistOrganizerCertifiedAt(ref, DateTime.now());
        if (!mounted) {
          return;
        }
        AppSnack.show(
          context,
          message: localizedAppErrorMessage(context.l10n, e),
          type: AppSnackType.success,
        );
        setState(() {
          _submitting = false;
          _result = _QuizResult(
            passed: true,
            correctCount: questions.length,
            totalQuestions: questions.length,
            pointsAwarded: 0,
          );
        });
        return;
      }
      setState(() => _submitting = false);
      AppSnack.show(
        context,
        message: localizedAppErrorMessage(context.l10n, e),
        type: AppSnackType.warning,
      );
    } on Object catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      AppSnack.show(
        context,
        message: context.l10n.organizerQuizSubmitFailed,
        type: AppSnackType.warning,
      );
    }
  }

  Future<void> _retryAfterResult() async {
    AppHaptics.tap();
    setState(() {
      _result = null;
      _selectedOptionByQuestionId.clear();
    });
    await _fetchQuiz();
  }

  /// Matches [OrganizerToolkitScreen]: back + title on one row (toolbar).
  Widget _quizPageHeader(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const AppBackButton(backgroundColor: AppColors.inputFill),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                context.l10n.organizerQuizTitle,
                style: AppTypography.eventsScreenTitle(textTheme),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _semanticOptionLabel(
    BuildContext context, {
    required int questionIndex1Based,
    required int total,
    required String optionText,
  }) {
    const int maxLen = 180;
    final String t = optionText.trim();
    final String excerpt = t.length <= maxLen
        ? t
        : '${t.substring(0, maxLen)}…';
    return context.l10n.organizerQuizOptionSemantic(
      questionIndex1Based,
      total,
      excerpt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.appBackground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _quizPageHeader(context),
              const Expanded(
                child: Center(child: CupertinoActivityIndicator(radius: 14)),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadFailed && _questions == null) {
      return Scaffold(
        backgroundColor: AppColors.appBackground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _quizPageHeader(context),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        _loadErrorDetail ??
                            context.l10n.organizerQuizLoadFailed,
                        style: AppTypography.eventsBodyMuted(textTheme),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      PrimaryButton(
                        label: context.l10n.organizerQuizRetryLoad,
                        onPressed: _fetchQuiz,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final _QuizResult? result = _result;
    if (result != null) {
      return OrganizerQuizResultScreen(
        result: result,
        onRetry: _retryAfterResult,
        onCreateEvent: () {
          widget.onCertified?.call();
          Navigator.of(
            context,
          ).popUntil((Route<dynamic> route) => route.isFirst);
        },
      );
    }

    final List<_QuizQuestion> questions = _questions ?? <_QuizQuestion>[];
    final bool allAnswered =
        questions.isNotEmpty &&
        questions.every(
          (_QuizQuestion q) => _selectedOptionByQuestionId.containsKey(q.id),
        );

    return buildOrganizerQuizQuestionPage(
      context,
      questions,
      textTheme,
      allAnswered: allAnswered,
    );
  }
}
