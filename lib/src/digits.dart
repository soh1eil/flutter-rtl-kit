/// Digit systems and number parsing.
library;

/// A numeral system.
enum DigitSystem {
  /// `0123456789`
  latin(0x30),

  /// Extended Arabic-Indic digits used for Persian and Urdu: `۰۱۲۳۴۵۶۷۸۹`.
  persian(0x06F0),

  /// Arabic-Indic digits: `٠١٢٣٤٥٦٧٨٩`.
  arabicIndic(0x0660);

  const DigitSystem(this._zero);
  final int _zero;

  /// The ten digit characters, from zero to nine.
  List<String> get digits =>
      List<String>.generate(10, (i) => String.fromCharCode(_zero + i));
}

/// The Persian decimal separator, U+066B.
const String arabicDecimalSeparator = '\u066B';

/// The Arabic thousands separator, U+066C.
const String arabicThousandsSeparator = '\u066C';

/// Returns the digit value of [rune] in any supported system, or `-1`.
int digitValue(int rune) {
  if (rune >= 0x30 && rune <= 0x39) return rune - 0x30;
  if (rune >= 0x06F0 && rune <= 0x06F9) return rune - 0x06F0;
  if (rune >= 0x0660 && rune <= 0x0669) return rune - 0x0660;
  return -1;
}

/// Rewrites every digit in [input], from any system, into [to].
///
/// Everything that is not a digit is left alone, so this is safe to run on
/// whole sentences.
String convertDigits(String input, DigitSystem to) {
  final out = StringBuffer();
  for (final rune in input.runes) {
    final v = digitValue(rune);
    out.writeCharCode(v < 0 ? rune : to._zero + v);
  }
  return out.toString();
}

/// Converts every digit to `0-9`.
String toLatinDigits(String input) => convertDigits(input, DigitSystem.latin);

/// Converts every digit to Persian digits (`۰-۹`).
String toPersianDigits(String input) =>
    convertDigits(input, DigitSystem.persian);

/// Converts every digit to Arabic-Indic digits (`٠-٩`).
String toArabicIndicDigits(String input) =>
    convertDigits(input, DigitSystem.arabicIndic);

/// Whether [input] contains at least one digit of any supported system.
bool hasDigits(String input) => input.runes.any((r) => digitValue(r) >= 0);

/// Parses a number typed with any mix of Latin, Persian or Arabic-Indic digits.
///
/// Accepted:
///
/// * the Persian/Arabic decimal separator `٫` and the ASCII `.`;
/// * thousands separators `٬`, `,` and `،`, spaces, NBSP and narrow NBSP,
///   which are ignored;
/// * a leading `-`, `+`, or the Unicode minus `−`.
///
/// A lone `,` is always a *grouping* separator. If your users type a decimal
/// comma (German, French, Turkish...), pass `decimalSeparator: ','` and
/// `.` is then treated as grouping.
///
/// Returns `null` when the text is not a number, and never throws.
num? parseNumber(String input, {String decimalSeparator = '.'}) {
  var s = toLatinDigits(input.trim());
  if (s.isEmpty) return null;
  s = s
      .replaceAll('\u2212', '-')
      .replaceAll('\u066B', '.')
      .replaceAll(RegExp('[\u066C\u060C\u00A0\u202F\u2009 ]'), '');
  if (decimalSeparator == ',') {
    s = s.replaceAll('.', '').replaceAll(',', '.');
  } else {
    s = s.replaceAll(',', '');
  }
  if (!RegExp(r'^[+-]?(\d+\.?\d*|\.\d+)$').hasMatch(s)) return null;
  return num.tryParse(s);
}
