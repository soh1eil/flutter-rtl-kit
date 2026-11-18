import 'package:flutter_rtl_kit/flutter_rtl_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RtlNumberFormat', () {
    test('Persian digits and separators', () {
      final f = RtlNumberFormat('fa');
      expect(f.format(1234567), '۱٬۲۳۴٬۵۶۷');
      expect(f.format(1234567.891, maxDecimals: 2), '۱٬۲۳۴٬۵۶۷٫۸۹');
      expect(f.format(0), '۰');
      expect(f.format(999), '۹۹۹');
      expect(f.format(1000), '۱٬۰۰۰');
    });
    test('Arabic', () {
      expect(RtlNumberFormat('ar').format(1234.5, maxDecimals: 1), '١٬٢٣٤٫٥');
      expect(RtlNumberFormat('ar-EG').format(42), '٤٢');
      expect(
          RtlNumberFormat('ar-MA').format(1234.5, maxDecimals: 1), '1.234,5');
    });
    test('Latin-digit locales', () {
      expect(RtlNumberFormat('en').format(1234567.5, maxDecimals: 2),
          '1,234,567.5');
      expect(RtlNumberFormat('de').format(1234567.5, maxDecimals: 2),
          '1.234.567,5');
      expect(RtlNumberFormat('fr_FR').format(1234.5, maxDecimals: 1),
          '1\u202F234,5');
      expect(RtlNumberFormat('xx').format(1234), '1,234'); // unknown -> English
    });
    test('overrides', () {
      expect(RtlNumberFormat('fa', digits: DigitSystem.latin).format(9000),
          '9٬000');
      expect(
          RtlNumberFormat('en', digits: DigitSystem.persian).format(12), '۱۲');
      expect(RtlNumberFormat('fa', groupSeparator: ',').format(1000), '۱,۰۰۰');
      expect(
          RtlNumberFormat('en', useGrouping: false).format(1234567), '1234567');
    });
    test('decimals: minimum pads, maximum trims', () {
      final f = RtlNumberFormat('en');
      expect(f.format(2, minDecimals: 2, maxDecimals: 2), '2.00');
      expect(f.format(2.5, minDecimals: 0, maxDecimals: 3), '2.5');
      expect(f.format(2.5, minDecimals: 2, maxDecimals: 3), '2.50');
      expect(f.format(2.123456, maxDecimals: 2), '2.12');
      expect(f.format(0.999, maxDecimals: 2), '1');
    });
    test('negatives and tiny negatives', () {
      expect(RtlNumberFormat('en').format(-1234.5, maxDecimals: 1), '-1,234.5');
      expect(RtlNumberFormat('fa').format(-5), '-۵');
      expect(RtlNumberFormat('en').format(-0.001), '0');
    });
    test('special values', () {
      final f = RtlNumberFormat('fa');
      expect(f.format(double.nan), 'NaN');
      expect(f.format(double.infinity), '∞');
      expect(f.format(double.negativeInfinity), '-∞');
      expect(f.format(1e25), isNotEmpty);
    });
    test('percent', () {
      expect(RtlNumberFormat('fa').formatPercent(0.25), '۲۵٪');
      expect(
          RtlNumberFormat('en').formatPercent(0.255, maxDecimals: 1), '25.5%');
    });
    test('parse round-trips format', () {
      for (final loc in ['en', 'fa', 'ar', 'de', 'fr']) {
        final f = RtlNumberFormat(loc);
        for (final v in [0, 7, 1234, 1234567.25, -42.5]) {
          expect(f.parse(f.format(v, maxDecimals: 2)), v, reason: '$loc $v');
        }
      }
    });
    test('parse takes any digit system typed by a user', () {
      expect(RtlNumberFormat('en').parse('۱۲۳'), 123);
      expect(RtlNumberFormat('de').parse('1.234,5'), 1234.5);
      expect(RtlNumberFormat('fa').parse('abc'), isNull);
    });
  });

  group('formatRelativeTimeFa', () {
    final now = DateTime(2025, 6, 15, 12, 0, 0);
    String f(Duration d) => formatRelativeTimeFa(now.subtract(d), now: now);
    String g(Duration d) => formatRelativeTimeFa(now.add(d), now: now);

    test('now', () {
      expect(f(Duration.zero), 'همین الان');
      expect(f(const Duration(seconds: 44)), 'همین الان');
      expect(g(const Duration(seconds: 30)), 'چند لحظه دیگر');
    });
    test('minutes', () {
      expect(f(const Duration(seconds: 60)), 'یک دقیقه پیش');
      expect(f(const Duration(minutes: 5)), '۵ دقیقه پیش');
      expect(f(const Duration(minutes: 44)), '۴۴ دقیقه پیش');
      expect(g(const Duration(minutes: 10)), '۱۰ دقیقه دیگر');
    });
    test('hours', () {
      expect(f(const Duration(minutes: 60)), 'یک ساعت پیش');
      expect(f(const Duration(hours: 3)), '۳ ساعت پیش');
      expect(g(const Duration(hours: 2)), '۲ ساعت دیگر');
      expect(f(const Duration(hours: 21)), '۲۱ ساعت پیش');
    });
    test('calendar days use dates, not 24h windows', () {
      final late = DateTime(2025, 6, 15, 0, 10);
      expect(formatRelativeTimeFa(DateTime(2025, 6, 14, 23, 50), now: late),
          '۲۰ دقیقه پیش');
      expect(formatRelativeTimeFa(DateTime(2025, 6, 14, 12, 0), now: now),
          'دیروز');
      expect(formatRelativeTimeFa(DateTime(2025, 6, 13, 12, 0), now: now),
          'پریروز');
      expect(
          formatRelativeTimeFa(DateTime(2025, 6, 16, 12, 0), now: now), 'فردا');
      expect(formatRelativeTimeFa(DateTime(2025, 6, 17, 12, 0), now: now),
          'پس\u200Cفردا');
      expect(
          formatRelativeTimeFa(DateTime(2025, 6, 15, 0, 30),
              now: DateTime(2025, 6, 15, 23, 30)),
          '۲۳ ساعت پیش');
    });
    test('days, weeks, months, years', () {
      expect(f(const Duration(days: 4)), '۴ روز پیش');
      expect(f(const Duration(days: 7)), 'یک هفته پیش');
      expect(f(const Duration(days: 21)), '۳ هفته پیش');
      expect(f(const Duration(days: 60)), '۲ ماه پیش');
      expect(f(const Duration(days: 364)), '۱۲ ماه پیش');
      expect(f(const Duration(days: 400)), 'یک سال پیش');
      expect(f(const Duration(days: 365 * 3 + 5)), '۳ سال پیش');
      expect(g(const Duration(days: 14)), '۲ هفته دیگر');
    });
    test('digit system option and DateTime extension', () {
      expect(
          formatRelativeTimeFa(now.subtract(const Duration(minutes: 5)),
              now: now, digits: DigitSystem.latin),
          '5 دقیقه پیش');
      expect(now.subtract(const Duration(minutes: 5)).relativeFa(now: now),
          '۵ دقیقه پیش');
    });
  });

  group('extensions', () {
    test('String helpers', () {
      expect('12'.toPersianDigits(), '۱۲');
      expect('۱۲'.toLatinDigits(), '12');
      expect('12'.toArabicIndicDigits(), '١٢');
      expect('۱٬۲۰۰'.parseLocalizedNumber(), 1200);
      expect('علي'.normalizePersian(), 'علی');
      expect('كِتَاب'.removeHarakat(), 'كتاب');
      expect('علي'.searchKey, searchKey('علی'));
      expect('سلام'.firstStrongDirection, isNotNull);
      expect('x\u202Ey'.stripBidiOverrides(), 'xy');
      expect('x'.isolated(), '\u2068x\u2069');
    });
    test('DateTime.jalali', () {
      expect(DateTime(2025, 3, 21).jalali, Jalali(1404, 1, 1));
    });
  });
}
