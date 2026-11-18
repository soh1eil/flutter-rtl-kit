import 'package:flutter_rtl_kit/flutter_rtl_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('convertDigits', () {
    test('round trips between the three systems', () {
      expect(toPersianDigits('0123456789'), '۰۱۲۳۴۵۶۷۸۹');
      expect(toArabicIndicDigits('0123456789'), '٠١٢٣٤٥٦٧٨٩');
      expect(toLatinDigits('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
      expect(toLatinDigits('٠١٢٣٤٥٦٧٨٩'), '0123456789');
      expect(toPersianDigits('٠١٢٣٤٥٦٧٨٩'), '۰۱۲۳۴۵۶۷۸۹');
      expect(toArabicIndicDigits('۰۱۲۳۴۵۶۷۸۹'), '٠١٢٣٤٥٦٧٨٩');
    });
    test('leaves everything else alone, including mixed text', () {
      expect(toPersianDigits('Room 12: سلام 7!'), 'Room ۱۲: سلام ۷!');
      expect(toLatinDigits('ساعت ۱۴:۳۰'), 'ساعت 14:30');
      expect(toPersianDigits(''), '');
    });
    test('mixed digit systems in one string', () {
      expect(toLatinDigits('1٢۳'), '123');
    });
    test('DigitSystem exposes its digits', () {
      expect(DigitSystem.persian.digits.join(), '۰۱۲۳۴۵۶۷۸۹');
      expect(DigitSystem.latin.digits.length, 10);
    });
    test('hasDigits and digitValue', () {
      expect(hasDigits('abc'), isFalse);
      expect(hasDigits('ab۳'), isTrue);
      expect(digitValue('٧'.runes.first), 7);
      expect(digitValue('x'.runes.first), -1);
    });
  });

  group('parseNumber', () {
    test('plain numbers in any digit system', () {
      expect(parseNumber('123'), 123);
      expect(parseNumber('۱۲۳'), 123);
      expect(parseNumber('١٢٣'), 123);
      expect(parseNumber('1۲٣'), 123);
      expect(parseNumber('۳.۱۴'), 3.14);
    });
    test('Persian separators', () {
      expect(parseNumber('۱٬۲۳۴٬۵۶۷٫۸۹'), 1234567.89);
      expect(parseNumber('١٬٢٣٤٫٥'), 1234.5);
    });
    test('grouping commas and spaces are ignored', () {
      expect(parseNumber('1,234,567'), 1234567);
      expect(parseNumber('۱،۲۳۴'), 1234);
      expect(parseNumber('1 234 567'), 1234567);
      expect(parseNumber('1\u202F234'), 1234);
    });
    test('signs', () {
      expect(parseNumber('-۵'), -5);
      expect(parseNumber('+5'), 5);
      expect(parseNumber('−۵٫۵'), -5.5);
    });
    test('decimal comma mode', () {
      expect(parseNumber('1.234,5', decimalSeparator: ','), 1234.5);
      expect(parseNumber('۱٫۲۳۴٫۵', decimalSeparator: ','), isNotNull);
      expect(parseNumber('3,14', decimalSeparator: ','), 3.14);
    });
    test('rejects garbage without throwing', () {
      for (final s in [
        '',
        ' ',
        'abc',
        '1.2.3',
        '12a',
        '--5',
        '٫',
        '1e5',
        '۱۲ سلام'
      ]) {
        expect(parseNumber(s), isNull, reason: '"$s"');
      }
    });
    test('trailing and leading dot forms', () {
      expect(parseNumber('.5'), 0.5);
      expect(parseNumber('5.'), 5);
    });
  });
}
