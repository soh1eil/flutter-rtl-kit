/// Locale-aware number formatting without an `intl` dependency.
library;

import 'digits.dart';

/// Digits and separators for one locale.
class RtlNumberSymbols {
  /// Creates a symbol set.
  const RtlNumberSymbols({
    required this.decimal,
    required this.group,
    this.digits = DigitSystem.latin,
  });

  /// The decimal separator.
  final String decimal;

  /// The grouping (thousands) separator.
  final String group;

  /// The default digit system.
  final DigitSystem digits;

  /// Symbols for common locales. Keys are language codes.
  static const Map<String, RtlNumberSymbols> known = {
    'en': RtlNumberSymbols(decimal: '.', group: ','),
    'fa': RtlNumberSymbols(
        decimal: '\u066B', group: '\u066C', digits: DigitSystem.persian),
    'ur': RtlNumberSymbols(
        decimal: '\u066B', group: '\u066C', digits: DigitSystem.persian),
    'ps': RtlNumberSymbols(
        decimal: '\u066B', group: '\u066C', digits: DigitSystem.persian),
    'ar': RtlNumberSymbols(
        decimal: '\u066B', group: '\u066C', digits: DigitSystem.arabicIndic),
    'he': RtlNumberSymbols(decimal: '.', group: ','),
    'fr': RtlNumberSymbols(decimal: ',', group: '\u202F'),
    'de': RtlNumberSymbols(decimal: ',', group: '.'),
    'es': RtlNumberSymbols(decimal: ',', group: '.'),
    'tr': RtlNumberSymbols(decimal: ',', group: '.'),
    'ru': RtlNumberSymbols(decimal: ',', group: '\u00A0'),
  };

  /// Looks up [locale] (`fa`, `fa_IR`, `ar-EG`...). Unknown locales get English.
  ///
  /// Arabic locales of the Maghreb (`ar-MA`, `ar-DZ`, `ar-TN`, `ar-LY`) use
  /// Latin digits, as their users expect.
  static RtlNumberSymbols forLocale(String locale) {
    final parts = locale.split(RegExp('[-_]'));
    final lang = parts.first.toLowerCase();
    final base = known[lang] ?? known['en']!;
    if (lang == 'ar' && parts.length > 1) {
      const latin = {'MA', 'DZ', 'TN', 'LY', 'EH'};
      if (latin.contains(parts[1].toUpperCase())) {
        return RtlNumberSymbols(
            decimal: ',', group: '.', digits: DigitSystem.latin);
      }
    }
    return base;
  }
}

/// Formats and parses numbers for a locale.
///
/// ```dart
/// RtlNumberFormat('fa').format(1234567.5, maxDecimals: 2); // ۱٬۲۳۴٬۵۶۷٫۵
/// RtlNumberFormat('ar').format(42);                         // ٤٢
/// RtlNumberFormat('fa', digits: DigitSystem.latin).format(9000); // 9٬000
/// ```
class RtlNumberFormat {
  /// Creates a formatter for [locale].
  ///
  /// [digits], [decimalSeparator] and [groupSeparator] override the locale's.
  RtlNumberFormat(
    String locale, {
    DigitSystem? digits,
    String? decimalSeparator,
    String? groupSeparator,
    this.useGrouping = true,
  }) : symbols = RtlNumberSymbols(
          decimal:
              decimalSeparator ?? RtlNumberSymbols.forLocale(locale).decimal,
          group: groupSeparator ?? RtlNumberSymbols.forLocale(locale).group,
          digits: digits ?? RtlNumberSymbols.forLocale(locale).digits,
        );

  /// The resolved symbols.
  final RtlNumberSymbols symbols;

  /// Whether thousands are grouped.
  final bool useGrouping;

  /// Formats [value] with between [minDecimals] and [maxDecimals] fraction
  /// digits (trailing zeros beyond the minimum are dropped).
  ///
  /// `NaN` and infinities are returned as `NaN`, `∞` and `-∞`.
  String format(num value, {int minDecimals = 0, int maxDecimals = 0}) {
    assert(minDecimals >= 0 && maxDecimals >= minDecimals, 'bad decimals');
    if (value is double) {
      if (value.isNaN) return 'NaN';
      if (value.isInfinite) return value.isNegative ? '-\u221E' : '\u221E';
    }
    final neg = value < 0;
    final fixed = value.abs().toStringAsFixed(maxDecimals);
    if (fixed.contains('e')) {
      return convertDigits(value.toString(), symbols.digits);
    }
    final parts = fixed.split('.');
    var intPart = parts[0];
    var frac = parts.length > 1 ? parts[1] : '';
    while (frac.length > minDecimals && frac.endsWith('0')) {
      frac = frac.substring(0, frac.length - 1);
    }
    if (useGrouping && intPart.length > 3) {
      final b = StringBuffer();
      for (var i = 0; i < intPart.length; i++) {
        if (i > 0 && (intPart.length - i) % 3 == 0) b.write(symbols.group);
        b.write(intPart[i]);
      }
      intPart = b.toString();
    }
    final body = frac.isEmpty ? intPart : '$intPart${symbols.decimal}$frac';
    final isZero = fixed.replaceAll(RegExp('[0.]'), '').isEmpty;
    return convertDigits('${neg && !isZero ? '-' : ''}$body', symbols.digits);
  }

  /// Formats [fraction] (0.25) as a percentage (`۲۵٪`).
  String formatPercent(num fraction, {int maxDecimals = 0}) {
    final sign = symbols.digits == DigitSystem.latin ? '%' : '\u066A';
    return '${format(fraction * 100, maxDecimals: maxDecimals)}$sign';
  }

  /// Parses text produced by [format], or typed by a user with any digit system.
  num? parse(String input) {
    var s = input.replaceAll('\u066A', '').replaceAll('%', '');
    if (symbols.group.isNotEmpty) s = s.replaceAll(symbols.group, '');
    return parseNumber(s, decimalSeparator: symbols.decimal == ',' ? ',' : '.');
  }
}
