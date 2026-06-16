part of 'package:feature_events/src/presentation/screens/organizer_toolkit/organizer_quiz_screen.dart';

class OrganizerQuizResultScreen extends StatelessWidget {
  const OrganizerQuizResultScreen({
    super.key,
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
                    color: (passed ? AppColors.primary : AppColors.error)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    passed
                        ? CupertinoIcons.checkmark_seal_fill
                        : CupertinoIcons.xmark_circle_fill,
                    size: 48,
                    color: passed ? AppColors.primaryDark : AppColors.error,
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
                    style: AppTypography.eventsMetricValue(
                      textTheme,
                    ).copyWith(color: AppColors.primaryDark),
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
