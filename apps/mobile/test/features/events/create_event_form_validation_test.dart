import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/utils/create_event_form_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('createEventFormIsSubmittable requires all gates', () {
    expect(
      createEventFormIsSubmittable(
        hasSite: true,
        hasDate: true,
        category: EcoEventCategory.generalCleanup,
        titleTrimmed: 'abc',
        timeRangeValid: true,
      ),
      isTrue,
    );
    expect(
      createEventFormIsSubmittable(
        hasSite: false,
        hasDate: true,
        category: EcoEventCategory.generalCleanup,
        titleTrimmed: 'abc',
        timeRangeValid: true,
      ),
      isFalse,
    );
    expect(
      createEventFormIsSubmittable(
        hasSite: true,
        hasDate: true,
        category: null,
        titleTrimmed: 'abc',
        timeRangeValid: true,
      ),
      isFalse,
    );
    expect(
      createEventFormIsSubmittable(
        hasSite: true,
        hasDate: true,
        category: EcoEventCategory.generalCleanup,
        titleTrimmed: 'ab',
        timeRangeValid: true,
      ),
      isFalse,
    );
  });

  test('createEventFormCompletedSteps tracks milestones', () {
    expect(
      createEventFormCompletedSteps(
        hasSite: true,
        hasDate: false,
        category: null,
        titleTrimmed: '',
        timeRangeValid: false,
      ),
      1,
    );
    expect(
      createEventFormCompletedSteps(
        hasSite: true,
        hasDate: true,
        category: EcoEventCategory.generalCleanup,
        titleTrimmed: 'abc',
        timeRangeValid: true,
      ),
      5,
    );
  });
}
