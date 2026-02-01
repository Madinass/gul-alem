import 'package:flutter_test/flutter_test.dart';
import 'package:madina/filter_options.dart';

void main() {
  group('labelForFilterOption', () {
    test('returns null when id is null', () {
      final label = labelForFilterOption(occasionFilterOptions, null);
      expect(label, isNull);
    });

    test('returns matching label for occasion id', () {
      final label = labelForFilterOption(occasionFilterOptions, 'birthday');
      expect(label, occasionFilterOptions.first.label);
    });

    test('returns matching label for recipient id', () {
      final label = labelForFilterOption(recipientFilterOptions, 'mom');
      expect(label, recipientFilterOptions[1].label);
    });

    test('returns null for unknown id', () {
      final label = labelForFilterOption(occasionFilterOptions, 'unknown');
      expect(label, isNull);
    });
  });
}
