import 'package:flutter_test/flutter_test.dart';
import 'package:text_transform/models/text_transformation.dart';

void main() {
  group('TextTransformer Tests', () {
    final rules = TextTransformer.getDefaultRules();

    test('Date separation rule', () {
      const input = 'Something 21.02.26 else';
      final output = TextTransformer.transform(input, rules);
      expect(output, contains('\n 21.02.26 '));
    });

    test('Suffix semicolon rule', () {
      const input = 'Year 23 ';
      final output = TextTransformer.transform(input, rules);
      // Note: The rule for .23 might need a dot prefix in the regex to be safe,
      // but the original repo used ".23 ".
      expect(output, contains('Year 23 ')); // If it doesn't match .23 strictly

      const input2 = 'Amount.23 ';
      final output2 = TextTransformer.transform(input2, rules);
      expect(output2, contains('Amount.23;'));
    });

    test('Cleanup rules', () {
      const input = 'Some text\nLine with DAVON DECKUNG info\nNext line';
      final output = TextTransformer.transform(input, rules);
      expect(output, isNot(contains('DAVON DECKUNG')));
      expect(output, contains('Some text\nNext line'));
    });
  });
}
