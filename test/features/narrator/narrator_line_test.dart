import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NarratorLine', () {
    test('GenericLine carries only text', () {
      const line = GenericLine('Nice work — 3 days in a row!');
      expect(line.text, 'Nice work — 3 days in a row!');
      expect(line, isA<GenericLine>());
    });

    test('PersonalLine carries text and dataBasis', () {
      const line = PersonalLine(
        text: 'Tuesday is your strongest day — 6 weeks in a row.',
        dataBasis: 'Tuesday 6-week streak',
      );
      expect(line.text, contains('Tuesday'));
      expect(line.dataBasis, 'Tuesday 6-week streak');
      expect(line, isA<PersonalLine>());
    });

    test('pattern match is exhaustive', () {
      const NarratorLine line = GenericLine('hi');
      final kind = switch (line) {
        GenericLine() => 'generic',
        PersonalLine() => 'personal',
      };
      expect(kind, 'generic');
    });
  });
}
