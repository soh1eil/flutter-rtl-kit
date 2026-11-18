/// A small tabular Hijri (Islamic civil) calendar helper.
library;

import 'package:flutter/foundation.dart' show immutable;

// JDN of 1 Muharram 1 AH in the civil (Friday epoch) tabular calendar.
const int _epochJdn = 1948440;
const int _unixEpochJdn = 2440588;

int _hijriToJdn(int y, int m, int d) =>
    d +
    (59 * (m - 1) + 1) ~/ 2 +
    (y - 1) * 354 +
    (3 + 11 * y) ~/ 30 +
    _epochJdn -
    1;

/// A date in the *tabular* Islamic civil calendar.
///
/// This is pure arithmetic (a 30-year cycle with 11 leap years). It is
/// **not** the Umm al-Qura calendar and not a moon-sighting calendar: real
/// observed dates differ from it by up to two days. Use it for display and
/// for approximate conversion, never for religious observance.
@immutable
class Hijri {
  /// Creates a date. Throws a [RangeError] if it does not exist.
  Hijri(this.year, this.month, this.day) {
    if (year < 1 ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        day > daysInMonthOf(year, month)) {
      throw RangeError('Invalid Hijri date: $year/$month/$day');
    }
  }

  const Hijri._(this.year, this.month, this.day);

  /// Converts the calendar date of [date].
  factory Hijri.fromDateTime(DateTime date) {
    final jdn =
        DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
                Duration.millisecondsPerDay +
            _unixEpochJdn;
    final y = (30 * (jdn - _epochJdn) + 10646) ~/ 10631;
    var m = ((jdn - (29 + _hijriToJdn(y, 1, 1))) / 29.5).ceil() + 1;
    if (m > 12) m = 12;
    if (m < 1) m = 1;
    return Hijri._(y, m, jdn - _hijriToJdn(y, m, 1) + 1);
  }

  /// Year (AH).
  final int year;

  /// Month, 1 (Muharram) to 12 (Dhu al-Hijjah).
  final int month;

  /// Day of month.
  final int day;

  /// Month names in Arabic.
  static const List<String> monthNamesAr = [
    'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى',
    'جمادى الآخرة', //
    'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
  ];

  /// Month names as written in Persian.
  static const List<String> monthNamesFa = [
    'محرم', 'صفر', 'ربیع\u200Cالاول', 'ربیع\u200Cالثانی', 'جمادی\u200Cالاول',
    'جمادی\u200Cالثانی', //
    'رجب', 'شعبان', 'رمضان', 'شوال', 'ذی\u200Cالقعده', 'ذی\u200Cالحجه',
  ];

  /// Whether [year] has 355 days.
  static bool isLeap(int year) => (14 + 11 * year) % 30 < 11;

  /// Odd months have 30 days, even months 29, and the last month 30 in a leap year.
  static int daysInMonthOf(int year, int month) =>
      month.isOdd || (month == 12 && isLeap(year)) ? 30 : 29;

  /// Persian name of this month.
  String get monthNameFa => monthNamesFa[month - 1];

  /// Arabic name of this month.
  String get monthNameAr => monthNamesAr[month - 1];

  /// The Gregorian date at local midnight.
  DateTime toDateTime() {
    final days = _hijriToJdn(year, month, day) - _unixEpochJdn;
    final u = DateTime.fromMillisecondsSinceEpoch(
        days * Duration.millisecondsPerDay,
        isUtc: true);
    return DateTime(u.year, u.month, u.day);
  }

  /// `yyyy/MM/dd`.
  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is Hijri &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);
}
