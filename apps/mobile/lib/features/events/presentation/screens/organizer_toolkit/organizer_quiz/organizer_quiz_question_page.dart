part of 'package:chisto_mobile/features/events/presentation/screens/organizer_toolkit/organizer_quiz_screen.dart';

extension OrganizerQuizQuestionPage on _OrganizerQuizScreenState {
  Widget buildOrganizerQuizQuestionPage(BuildContext context, List<_QuizQuestion> questions, bool allAnswered, TextTheme textTheme) {
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
                                      rebuildState(
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
