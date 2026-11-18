/// Persian relative-time formatting.
library;

import 'digits.dart';

/// Describes [then] relative to [now] in Persian: `همین الان`, `۵ دقیقه پیش`,
/// `دیروز`, `۳ هفته پیش`, `۲ ساعت دیگر`, `فردا`.
///
/// Thresholds: under 45 seconds is "now"; minutes up to 45; hours up to 22;
/// beyond that whole *calendar* days are compared (so 23:50 yesterday is
/// `دیروز`, not "10 minutes ago"); then weeks (under 30 days), months (under a
/// year) and years.
///
/// [now] defaults to `DateTime.now()` and exists for testing. Numbers are
/// written in [digits] (default Persian). A count of one is written as `یک`.
String formatRelativeTimeFa(
  DateTime then, {
  DateTime? now,
  DigitSystem digits = DigitSystem.persian,
}) {
  final ref = now ?? DateTime.now();
  final future = then.isAfter(ref);
  final diff = future ? then.difference(ref) : ref.difference(then);
  String suffix(String phrase) => future ? '$phrase دیگر' : '$phrase پیش';
  String count(int n, String unit) =>
      suffix('${n == 1 ? 'یک' : convertDigits('$n', digits)} $unit');

  if (diff.inSeconds < 45) return future ? 'چند لحظه دیگر' : 'همین الان';
  if (diff.inSeconds < 90) return count(1, 'دقیقه');
  if (diff.inMinutes < 45) return count(diff.inMinutes, 'دقیقه');
  if (diff.inMinutes < 90) return count(1, 'ساعت');
  if (diff.inHours < 22) return count(diff.inHours, 'ساعت');

  final a = DateTime.utc(then.year, then.month, then.day);
  final b = DateTime.utc(ref.year, ref.month, ref.day);
  final days = a.difference(b).inDays.abs();
  if (days == 0) return count(diff.inHours, 'ساعت');
  if (days == 1) return future ? 'فردا' : 'دیروز';
  if (days == 2) return future ? 'پس\u200Cفردا' : 'پریروز';
  if (days < 7) return count(days, 'روز');
  if (days < 30) return count(days ~/ 7, 'هفته');
  if (days < 365) return count(days ~/ 30, 'ماه');
  return count(days ~/ 365, 'سال');
}
