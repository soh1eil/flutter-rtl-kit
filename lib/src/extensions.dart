/// `String` and `DateTime` extensions over the toolkit's functions.
library;

import 'dart:ui' show TextDirection;

import 'bidi.dart' as bidi;
import 'digits.dart' as digits;
import 'jalali.dart';
import 'normalize.dart' as norm;
import 'relative_time.dart';

/// Digit, normalisation and bidi helpers on [String].
extension RtlStringX on String {
  /// See [digits.toPersianDigits].
  String toPersianDigits() => digits.toPersianDigits(this);

  /// See [digits.toArabicIndicDigits].
  String toArabicIndicDigits() => digits.toArabicIndicDigits(this);

  /// See [digits.toLatinDigits].
  String toLatinDigits() => digits.toLatinDigits(this);

  /// See [digits.parseNumber].
  num? parseLocalizedNumber({String decimalSeparator = '.'}) =>
      digits.parseNumber(this, decimalSeparator: decimalSeparator);

  /// See [norm.normalizePersian].
  String normalizePersian({digits.DigitSystem? digits, bool zwnj = true}) =>
      norm.normalizePersian(this, digits: digits, zwnj: zwnj);

  /// See [norm.removeHarakat].
  String removeHarakat() => norm.removeHarakat(this);

  /// See [norm.searchKey].
  String get searchKey => norm.searchKey(this);

  /// See [bidi.firstStrongDirection].
  TextDirection? get firstStrongDirection => bidi.firstStrongDirection(this);

  /// See [bidi.isolate].
  String isolated({TextDirection? direction}) =>
      bidi.isolate(this, direction: direction);

  /// See [bidi.stripBidiOverrides].
  String stripBidiOverrides({bool stripMarks = false}) =>
      bidi.stripBidiOverrides(this, stripMarks: stripMarks);
}

/// Calendar and relative-time helpers on [DateTime].
extension RtlDateTimeX on DateTime {
  /// This date in the Jalali calendar.
  Jalali get jalali => Jalali.fromDateTime(this);

  /// See [formatRelativeTimeFa].
  String relativeFa(
          {DateTime? now,
          digits.DigitSystem digits = digits.DigitSystem.persian}) =>
      formatRelativeTimeFa(this, now: now, digits: digits);
}
