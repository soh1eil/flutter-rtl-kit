/// The Jalali (Solar Hijri, Persian) calendar.
library;

import 'package:flutter/foundation.dart' show immutable;

import 'digits.dart';

/// First year with a well-defined conversion.
const int _minYear = 1;

/// Last supported year.
const int _maxYear = 3177;

// Years in which the leap pattern changes (Borkowski). The 33-year rule is
// exact between two consecutive entries.
const List<int> _breaks = [
  -61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181, 1210, //
  1635, 2060, 2097, 2192, 2262, 2324, 2394, 2456, 3178,
];

typedef _JalCal = ({int leap, int gy, int march});

// For Jalali year [jy]: the Gregorian year it starts in, the day of March on
// which 1 Farvardin falls, and the number of years since the last leap year
// (0 means [jy] is leap).
_JalCal _jalCal(int jy) {
  final gy = jy + 621;
  var leapJ = -14;
  var jp = _breaks[0];
  var jump = 0;
  var i = 1;
  for (; i < _breaks.length; i++) {
    final jm = _breaks[i];
    jump = jm - jp;
    if (jy < jm) break;
    leapJ += (jump ~/ 33) * 8 + (jump % 33) ~/ 4;
    jp = jm;
  }
  var n = jy - jp;
  leapJ += (n ~/ 33) * 8 + ((n % 33) + 3) ~/ 4;
  if (jump % 33 == 4 && jump - n == 4) leapJ += 1;
  final leapG = gy ~/ 4 - ((gy ~/ 100 + 1) * 3) ~/ 4 - 150;
  final march = 20 + leapJ - leapG;
  if (jump - n < 6) n = n - jump + ((jump + 4) ~/ 33) * 33;
  var leap = (((n + 1) % 33) - 1).remainder(4);
  if (leap == -1) leap = 4;
  return (leap: leap, gy: gy, march: march);
}

int _epochDay(int y, int m, int d) =>
    DateTime.utc(y, m, d).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

/// A date in the Jalali calendar. Immutable, comparable, and free of time zones.
///
/// ```dart
/// final d = Jalali.fromDateTime(DateTime(2025, 3, 21));
/// d.format('EEEE d MMMM yyyy'); // جمعه 1 فروردین 1404
/// ```
///
/// The conversion follows the Iranian civil calendar. It was checked against
/// the officially published start of the Persian year and against round trips
/// of every day between 1200 and 1600 (see the tests).
@immutable
class Jalali implements Comparable<Jalali> {
  /// Creates a date, throwing a [RangeError] if it does not exist.
  Jalali(this.year, this.month, this.day) {
    if (!isValid(year, month, day)) {
      throw RangeError('Invalid Jalali date: $year/$month/$day');
    }
  }

  /// Today, in the device's time zone.
  factory Jalali.now() => Jalali.fromDateTime(DateTime.now());

  /// Converts the calendar date of [date]. The time of day is ignored.
  factory Jalali.fromDateTime(DateTime date) {
    final days = _epochDay(date.year, date.month, date.day);
    final gy = date.year;
    var jy = gy - 621;
    final r = _jalCal(jy);
    var k = days - _epochDay(gy, 3, r.march);
    int jm, jd;
    if (k >= 0 && k <= 185) {
      jm = 1 + k ~/ 31;
      jd = k % 31 + 1;
    } else {
      if (k >= 0) {
        k -= 186;
      } else {
        jy -= 1;
        k += 179;
        if (r.leap == 1) k += 1;
      }
      jm = 7 + k ~/ 30;
      jd = k % 30 + 1;
    }
    if (!isValid(jy, jm, jd)) {
      throw RangeError('Date out of the supported Jalali range: $date');
    }
    return Jalali._(jy, jm, jd);
  }

  /// Parses `yyyy/mm/dd`, also with `-` or `.` separators and any digit system.
  /// Throws a [FormatException] on bad input.
  factory Jalali.parse(String input) =>
      tryParse(input) ?? (throw FormatException('Not a Jalali date', input));

  /// Like [parse], but returns `null` instead of throwing.
  static Jalali? tryParse(String input) {
    final m =
        RegExp(r'^\s*(\d{1,4})\s*[/\-.]\s*(\d{1,2})\s*[/\-.]\s*(\d{1,2})\s*$')
            .firstMatch(toLatinDigits(input));
    if (m == null) return null;
    final y = int.parse(m[1]!), mo = int.parse(m[2]!), d = int.parse(m[3]!);
    return isValid(y, mo, d) ? Jalali._(y, mo, d) : null;
  }

  const Jalali._(this.year, this.month, this.day);

  /// Year, 1 to 3177.
  final int year;

  /// Month, 1 (Farvardin) to 12 (Esfand).
  final int month;

  /// Day of month, 1 to [daysInMonth].
  final int day;

  /// The twelve month names.
  static const List<String> monthNames = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', //
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
  ];

  /// Weekday names, starting from Saturday, the first day of the Persian week.
  static const List<String> weekdayNames = [
    'شنبه', 'یکشنبه', 'دوشنبه', 'سه\u200Cشنبه', 'چهارشنبه', 'پنجشنبه',
    'جمعه', //
  ];

  /// One-letter weekday names, starting from Saturday.
  static const List<String> weekdayInitials = [
    'ش',
    'ی',
    'د',
    'س',
    'چ',
    'پ',
    'ج'
  ];

  /// Whether [year] has 366 days.
  static bool isLeap(int year) => _jalCal(year).leap == 0;

  /// Days in [month] of [year]: 31 for months 1-6, 30 for 7-11, and 29 or 30
  /// for Esfand.
  static int daysInMonthOf(int year, int month) =>
      month <= 6 ? 31 : (month <= 11 ? 30 : (isLeap(year) ? 30 : 29));

  /// Whether `year/month/day` is a real date in the supported range.
  static bool isValid(int year, int month, int day) =>
      year >= _minYear &&
      year <= _maxYear &&
      month >= 1 &&
      month <= 12 &&
      day >= 1 &&
      day <= daysInMonthOf(year, month);

  /// Whether this date's year has 366 days.
  bool get isLeapYear => isLeap(year);

  /// Days in this date's month.
  int get daysInMonth => daysInMonthOf(year, month);

  /// 1-based day within the year.
  int get dayOfYear =>
      month <= 6 ? (month - 1) * 31 + day : 186 + (month - 7) * 30 + day;

  /// Name of this month.
  String get monthName => monthNames[month - 1];

  /// ISO weekday: [DateTime.monday] (1) to [DateTime.sunday] (7).
  int get weekday => toDateTime().weekday;

  /// Weekday index with Saturday = 0 ... Friday = 6.
  int get weekdayIndex => (weekday + 1) % 7;

  /// Name of this weekday.
  String get weekdayName => weekdayNames[weekdayIndex];

  /// The Gregorian date at local midnight (or UTC midnight with [utc]).
  DateTime toDateTime({bool utc = false}) {
    final r = _jalCal(year);
    final days = _epochDay(r.gy, 3, r.march) +
        (month - 1) * 31 -
        (month ~/ 7) * (month - 7) +
        day -
        1;
    final u = DateTime.fromMillisecondsSinceEpoch(
        days * Duration.millisecondsPerDay,
        isUtc: true);
    return utc ? u : DateTime(u.year, u.month, u.day);
  }

  /// This date plus [n] days (negative goes back).
  Jalali addDays(int n) {
    final d = toDateTime(utc: true);
    return Jalali.fromDateTime(DateTime.utc(d.year, d.month, d.day + n));
  }

  /// This date plus [n] months. The day is clamped to the target month.
  Jalali addMonths(int n) {
    final total = year * 12 + (month - 1) + n;
    final y = total ~/ 12, m = total % 12 + 1;
    final d = day > daysInMonthOf(y, m) ? daysInMonthOf(y, m) : day;
    return Jalali(y, m, d);
  }

  /// This date plus [n] years. 30 Esfand clamps to 29 in a non-leap year.
  Jalali addYears(int n) => addMonths(n * 12);

  /// Whole days from [other] to this date (positive if this is later).
  int differenceInDays(Jalali other) {
    final a = toDateTime(utc: true), b = other.toDateTime(utc: true);
    return a.difference(b).inDays;
  }

  /// Formats with a pattern of these tokens; everything else is copied as is.
  ///
  /// | token | output |
  /// |---|---|
  /// | `yyyy` / `yy` | year / last two digits |
  /// | `MMMM` / `MMM` | month name |
  /// | `MM` / `M` | month number, padded or not |
  /// | `dd` / `d` | day, padded or not |
  /// | `EEEE` | weekday name |
  /// | `E` | weekday initial |
  /// | `'text'` | literal text (`''` is a quote) |
  ///
  /// Numbers are written in [digits] (default Latin). The default pattern is
  /// `yyyy/MM/dd`.
  String format(
      [String pattern = 'yyyy/MM/dd', DigitSystem digits = DigitSystem.latin]) {
    final out = StringBuffer();
    String n(int v, [int pad = 1]) =>
        convertDigits(v.toString().padLeft(pad, '0'), digits);
    var i = 0;
    while (i < pattern.length) {
      final c = pattern[i];
      if (c == "'") {
        if (i + 1 < pattern.length && pattern[i + 1] == "'") {
          out.write("'");
          i += 2;
          continue;
        }
        // Quoted literal; a doubled quote inside it is an escaped quote.
        var j = i + 1;
        while (j < pattern.length) {
          if (pattern[j] == "'") {
            if (j + 1 < pattern.length && pattern[j + 1] == "'") {
              out.write("'");
              j += 2;
              continue;
            }
            break;
          }
          out.write(pattern[j]);
          j++;
        }
        i = j + 1;
        continue;
      }
      if (!'yMdE'.contains(c)) {
        out.write(c);
        i++;
        continue;
      }
      var j = i;
      while (j < pattern.length && pattern[j] == c) {
        j++;
      }
      final len = j - i;
      out.write(switch (c) {
        'y' => len == 2 ? n(year % 100, 2) : n(year, len >= 4 ? 4 : len),
        'M' => len >= 3 ? monthName : n(month, len),
        'd' => n(day, len),
        _ => len >= 4 ? weekdayName : weekdayInitials[weekdayIndex],
      });
      i = j;
    }
    return out.toString();
  }

  /// `yyyy/MM/dd` in Latin digits.
  @override
  String toString() => format();

  @override
  int compareTo(Jalali other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  /// Whether this date is strictly after [other].
  bool operator >(Jalali other) => compareTo(other) > 0;

  /// Whether this date is strictly before [other].
  bool operator <(Jalali other) => compareTo(other) < 0;

  /// Whether this date is on or after [other].
  bool operator >=(Jalali other) => compareTo(other) >= 0;

  /// Whether this date is on or before [other].
  bool operator <=(Jalali other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) =>
      other is Jalali &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);
}
