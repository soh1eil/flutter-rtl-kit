import 'dart:ui' show TextDirection;

import 'package:flutter_rtl_kit/flutter_rtl_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('firstStrongDirection', () {
    const rtl = TextDirection.rtl, ltr = TextDirection.ltr;
    final cases = <String, TextDirection?>{
      'hello': ltr,
      'سلام': rtl,
      'مرحبا': rtl,
      'שלום': rtl,
      'Hello سلام': ltr,
      'سلام Hello': rtl,
      '123 سلام': rtl, // digits are neutral
      '123 hello': ltr,
      '۱۲۳ سلام': rtl,
      '"سلام"': rtl, // leading punctuation is neutral
      '(Soheil) سهیل': ltr,
      '!!!': null,
      '': null,
      '123': null,
      '😀': null,
      'ی': rtl,
      'ä': ltr,
      '日本語': ltr,
      '\u200Fabc': rtl, // an RLM is strong
      '\u200Eسلام': ltr,
    };
    for (final e in cases.entries) {
      test('"${e.key}" -> ${e.value}', () {
        expect(firstStrongDirection(e.key), e.value);
      });
    }

    test('text inside an isolate is skipped (UAX #9 rule P2)', () {
      expect(firstStrongDirection('\u2067سلام\u2069 hello'), ltr);
      expect(firstStrongDirection('\u2066hello\u2069 سلام'), rtl);
      expect(firstStrongDirection('\u2068abc\u2069'), isNull);
      // Unterminated isolate hides the rest, a stray PDI is ignored.
      expect(firstStrongDirection('\u2067سلام'), isNull);
      expect(firstStrongDirection('\u2069abc'), ltr);
    });

    test('resolveDirection falls back for neutral text', () {
      expect(resolveDirection('123', TextDirection.rtl), TextDirection.rtl);
      expect(resolveDirection('abc', TextDirection.rtl), TextDirection.ltr);
    });
  });

  group('stripBidiOverrides', () {
    test('removes every embedding, override and isolate', () {
      for (final c in [
        '\u202A', '\u202B', '\u202C', '\u202D', '\u202E', //
        '\u2066', '\u2067', '\u2068', '\u2069',
      ]) {
        expect(stripBidiOverrides('a${c}b'), 'ab',
            reason: c.runes.first.toRadixString(16));
        expect(containsBidiControls('a${c}b'), isTrue);
      }
    });
    test('Trojan Source filename example loses its override', () {
      const evil = 'invoice\u202Etxt.exe';
      expect(containsBidiControls(evil), isTrue);
      expect(stripBidiOverrides(evil), 'invoicetxt.exe');
      expect(containsBidiControls(stripBidiOverrides(evil)), isFalse);
    });
    test('marks and joiners are legitimate and kept by default', () {
      const s = 'می\u200Cخواهم\u200F';
      expect(stripBidiOverrides(s), s);
      expect(containsBidiControls(s), isFalse);
      expect(stripBidiOverrides(s, stripMarks: true), 'می\u200Cخواهم');
    });
    test('plain text is untouched', () {
      expect(stripBidiOverrides('سلام Hello 123'), 'سلام Hello 123');
    });
  });

  group('isolate', () {
    test('wraps with FSI ... PDI by default', () {
      expect(isolate('Ali'), '\u2068Ali\u2069');
    });
    test('explicit directions', () {
      expect(isolate('x', direction: TextDirection.ltr), '\u2066x\u2069');
      expect(isolate('x', direction: TextDirection.rtl), '\u2067x\u2069');
    });
    test('a hostile string cannot close the isolate early', () {
      final s = isolate('evil\u2069 injected \u202E');
      expect(s.startsWith('\u2068'), isTrue);
      expect(s.endsWith('\u2069'), isTrue);
      expect(
          s
              .substring(1, s.length - 1)
              .contains(RegExp('[\u202A-\u202E\u2066-\u2069]')),
          isFalse);
    });
    test('isolated text does not change the direction of the sentence', () {
      final sentence = 'Message from ${isolate('سهیل')}: hi';
      expect(firstStrongDirection(sentence), TextDirection.ltr);
    });
    test('unisolate undoes it', () {
      expect(unisolate(isolate('Ali')), 'Ali');
    });
    test('withDirectionMark', () {
      expect(withDirectionMark('x', TextDirection.rtl), '\u200Fx');
      expect(withDirectionMark('x', TextDirection.ltr), '\u200Ex');
    });
  });
}
