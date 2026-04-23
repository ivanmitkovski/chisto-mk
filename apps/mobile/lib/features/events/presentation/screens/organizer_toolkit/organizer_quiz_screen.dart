import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/app_error_localizations.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/features/events/data/organizer_quiz_payload.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

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

Future<void> _persistOrganizerCertifiedAt(DateTime at) async {
  if (!ServiceLocator.instance.isInitialized) {
    return;
  }
  await ServiceLocator.instance.tokenStorage.writeOrganizerCertifiedAt(at);
}

class OrganizerQuizScreen extends StatefulWidget {
  const OrganizerQuizScreen({super.key, this.onCertified});

  final VoidCallback? onCertified;

  @override
  State<OrganizerQuizScreen> createState() => _OrganizerQuizScreenState();
}

class _OrganizerQuizScreenState extends State<OrganizerQuizScreen> {
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
    final ServiceLocator sl = ServiceLocator.instance;
    if (sl.isInitialized && sl.authState.isOrganizerCertified) {
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
      final response = await ServiceLocator.instance.apiClient.get(
        '/auth/me/organizer-certification/quiz',
      );
      final OrganizerQuizApiPayload? payload = parseOrganizerQuizPayload(
        response.json,
        rawBody: response.body,
      );
      if (payload == null) {
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
              final String detail = context.l10n.organizerQuizLoadInvalidResponse;
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
          ServiceLocator.instance.isInitialized) {
        final AuthState auth = ServiceLocator.instance.authState;
        if (!auth.isOrganizerCertified) {
          auth.markOrganizerCertified(DateTime.now());
        }
        await _persistOrganizerCertifiedAt(DateTime.now());
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
      AppSnack.show(
        context,
        message: detail,
        type: AppSnackType.warning,
      );
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
      final response = await ServiceLocator.instance.apiClient.post(
        '/auth/me/organizer-certification',
        body: <String, dynamic>{
          'quizSession': session,
          'answers': answers,
        },
      );
      final Map<String, dynamic>? json = response.json;
      if (json == null) {
        if (mounted) {
          setState(() => _submitting = false);
        }
        return;
      }

      final bool passed = json['passed'] as bool? ?? false;
      final bool alreadyCertified = json['alreadyCertified'] as bool? ?? false;
      final int correctCount = (json['correctCount'] as num?)?.toInt() ?? 0;
      final int totalQuestions = (json['totalQuestions'] as num?)?.toInt() ?? questions.length;
      final int pointsAwarded = (json['pointsAwarded'] as num?)?.toInt() ?? 0;
      final String? certifiedAt = json['organizerCertifiedAt'] as String?;

      if (passed && certifiedAt != null) {
        final DateTime? parsed = DateTime.tryParse(certifiedAt);
        if (parsed != null) {
          ServiceLocator.instance.authState.markOrganizerCertified(parsed);
          await _persistOrganizerCertifiedAt(parsed);
        }
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
          ServiceLocator.instance.isInitialized) {
        ServiceLocator.instance.authState.markOrganizerCertified(DateTime.now());
        await _persistOrganizerCertifiedAt(DateTime.now());
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
            AppBackButton(backgroundColor: AppColors.inputFill),
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
    final String excerpt = t.length <= maxLen ? t : '${t.substring(0, maxLen)}…';
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
                child: Center(
                  child: CupertinoActivityIndicator(radius: 14),
                ),
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
                        _loadErrorDetail ?? context.l10n.organizerQuizLoadFailed,
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
      return _ResultScreen(
        result: result,
        onRetry: _retryAfterResult,
        onCreateEvent: () {
          widget.onCertified?.call();
          Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
        },
      );
    }

    final List<_QuizQuestion> questions = _questions ?? <_QuizQuestion>[];
    final bool allAnswered = questions.isNotEmpty &&
        questions.every(
          (_QuizQuestion q) => _selectedOptionByQuestionId.containsKey(q.id),
        );

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _quizPageHeader(context),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                itemCount: questions.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(height: AppSpacing.xl),
                itemBuilder: (BuildContext context, int qIndex) {
                  final _QuizQuestion q = questions[qIndex];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${qIndex + 1}. ${q.text}',
                        style: AppTypography.eventsPanelTitle(textTheme),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...q.options.map((_QuizOption opt) {
                        final bool selected =
                            _selectedOptionByQuestionId[q.id] == opt.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Semantics(
                            button: true,
                            selected: selected,
                            label: _semanticOptionLabel(
                              context,
                              questionIndex1Based: qIndex + 1,
                              total: questions.length,
                              optionText: opt.text,
                            ),
                            child: Material(
                              color: AppColors.transparent,
                              child: InkWell(
                                onTap: () {
                                  AppHaptics.light();
                                  setState(
                                    () => _selectedOptionByQuestionId[q.id] = opt.id,
                                  );
                                },
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusLg),
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primary.withValues(alpha: 0.08)
                                        : AppColors.panelBackground,
                                    borderRadius:
                                        BorderRadius.circular(AppSpacing.radiusLg),
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.divider.withValues(alpha: 0.5),
                                      width: selected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Icon(
                                        selected
                                            ? CupertinoIcons.checkmark_circle_fill
                                            : CupertinoIcons.circle,
                                        size: 22,
                                        color: selected
                                            ? AppColors.primaryDark
                                            : AppColors.divider,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          opt.text,
                                          style: AppTypography.eventsBodyProse(textTheme),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: SizedBox(
                height: 72,
                child: Center(
                  child: PrimaryButton(
                    label: context.l10n.organizerQuizSubmit,
                    enabled: allAnswered && !_submitting,
                    isLoading: _submitting,
                    onPressed: _submit,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizOption {
  const _QuizOption({required this.id, required this.text});
  final String id;
  final String text;
}

class _QuizQuestion {
  const _QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
  });
  final String id;
  final String text;
  final List<_QuizOption> options;
}

class _QuizResult {
  const _QuizResult({
    required this.passed,
    required this.correctCount,
    required this.totalQuestions,
    required this.pointsAwarded,
  });
  final bool passed;
  final int correctCount;
  final int totalQuestions;
  final int pointsAwarded;
}

class _ResultScreen extends StatelessWidget {
  const _ResultScreen({
    required this.result,
    required this.onRetry,
    required this.onCreateEvent,
  });

  final _QuizResult result;
  final Future<void> Function() onRetry;
  final VoidCallback onCreateEvent;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool passed = result.passed;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: (passed ? AppColors.primary : AppColors.accentDanger)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    passed
                        ? CupertinoIcons.checkmark_seal_fill
                        : CupertinoIcons.xmark_circle_fill,
                    size: 48,
                    color: passed ? AppColors.primaryDark : AppColors.accentDanger,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  passed
                      ? context.l10n.organizerQuizPassedTitle
                      : context.l10n.organizerQuizFailedTitle,
                  style: AppTypography.eventsDetailHeadline(textTheme),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  passed
                      ? context.l10n.organizerQuizPassedBody
                      : context.l10n.organizerQuizFailedBody(
                          result.correctCount,
                          result.totalQuestions,
                        ),
                  style: AppTypography.eventsBodyMuted(textTheme),
                  textAlign: TextAlign.center,
                ),
                if (passed && result.pointsAwarded > 0) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '+${result.pointsAwarded} pts',
                    style: AppTypography.eventsMetricValue(textTheme).copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: passed
                        ? context.l10n.organizerQuizCreateEvent
                        : context.l10n.organizerQuizRetry,
                    onPressed: passed
                        ? onCreateEvent
                        : () {
                            unawaited(onRetry());
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
