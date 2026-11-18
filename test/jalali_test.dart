import 'package:flutter_rtl_kit/flutter_rtl_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Jalali known tables', () {
    // 1 Farvardin (Nowruz) of each year, Gregorian.
    const nowruz = <int, (int, int, int)>{
      1300: (1921, 3, 21),
      1350: (1971, 3, 21),
      1357: (1978, 3, 21),
      1380: (2001, 3, 21),
      1390: (2011, 3, 21),
      1395: (2016, 3, 20),
      1396: (2017, 3, 21),
      1397: (2018, 3, 21),
      1398: (2019, 3, 21),
      1399: (2020, 3, 20),
      1400: (2021, 3, 21),
      1401: (2022, 3, 21),
      1402: (2023, 3, 21),
      1403: (2024, 3, 20),
      1404: (2025, 3, 21),
      1405: (2026, 3, 21),
      1406: (2027, 3, 21),
    };
    for (final e in nowruz.entries) {
      final (y, m, d) = e.value;
      test('1 Farvardin ${e.key} is $y-$m-$d', () {
        expect(Jalali(e.key, 1, 1).toDateTime(), DateTime(y, m, d));
        expect(Jalali.fromDateTime(DateTime(y, m, d)), Jalali(e.key, 1, 1));
      });
    }

    const dates = <(int, int, int), (int, int, int)>{
      (1357, 11, 22): (1979, 2, 11), // 22 Bahman 1357
      (1358, 1, 12): (1979, 4, 1), // 12 Farvardin 1358
      (1388, 3, 22): (2009, 6, 12), // 22 Khordad 1388
      (1403, 12, 30): (2025, 3, 20), // last day of a leap year
      (1399, 12, 30): (2021, 3, 20),
      (1404, 12, 29): (2026, 3, 20),
      (1404, 6, 31): (2025, 9, 22), // Shahrivar has 31 days
      (1404, 7, 1): (2025, 9, 23), // Mehr 1
    };
    for (final e in dates.entries) {
      final (jy, jm, jd) = e.key;
      final (gy, gm, gd) = e.value;
      test('$jy/$jm/$jd is $gy-$gm-$gd', () {
        expect(Jalali(jy, jm, jd).toDateTime(), DateTime(gy, gm, gd));
        expect(Jalali.fromDateTime(DateTime(gy, gm, gd)), Jalali(jy, jm, jd));
      });
    }

    test('leap years', () {
      for (final y in [1399, 1403]) {
        expect(Jalali.isLeap(y), isTrue, reason: '$y');
      }
      for (final y in [1398, 1400, 1401, 1402, 1404, 1405]) {
        expect(Jalali.isLeap(y), isFalse, reason: '$y');
      }
    });

    test('every year has 365 or 366 days and months add up', () {
      for (var y = 1200; y <= 1600; y++) {
        var total = 0;
        for (var m = 1; m <= 12; m++) {
          total += Jalali.daysInMonthOf(y, m);
        }
        expect(total, Jalali.isLeap(y) ? 366 : 365, reason: '$y');
      }
    });

    test('leap years follow a 33-year-ish rhythm: gaps of 4 or 5', () {
      final leaps = [
        for (var y = 1200; y <= 1600; y++)
          if (Jalali.isLeap(y)) y
      ];
      for (var i = 1; i < leaps.length; i++) {
        final gap = leaps[i] - leaps[i - 1];
        expect(gap == 4 || gap == 5, isTrue,
            reason: 'gap $gap before ${leaps[i]}');
      }
    });
  });

  group('Jalali round trip', () {
    test(
        'every day from 1200 to 1600 survives both ways and advances by one day',
        () {
      var g = Jalali(1200, 1, 1).toDateTime(utc: true);
      final end = Jalali(1600, 12, 29).toDateTime(utc: true);
      var j = Jalali(1200, 1, 1);
      while (!g.isAfter(end)) {
        final back = Jalali.fromDateTime(g);
        expect(back, j, reason: '$g');
        expect(j.toDateTime(utc: true), g);
        g = DateTime.utc(g.year, g.month, g.day + 1);
        // Walk forward through the Jalali calendar independently.
        j = j.day < j.daysInMonth
            ? Jalali(j.year, j.month, j.day + 1)
            : (j.month < 12
                ? Jalali(j.year, j.month + 1, 1)
                : Jalali(j.year + 1, 1, 1));
      }
    });

    test('time of day and time zone fields are ignored', () {
      expect(Jalali.fromDateTime(DateTime(2025, 3, 21, 23, 59, 59)),
          Jalali(1404, 1, 1));
      expect(Jalali.fromDateTime(DateTime.utc(2025, 3, 20, 0, 0, 1)),
          Jalali(1403, 12, 30));
    });
  });

  group('Jalali value semantics', () {
    test('validation', () {
      expect(() => Jalali(1404, 12, 30), throwsRangeError); // not a leap year
      expect(() => Jalali(1403, 12, 30), returnsNormally);
      expect(() => Jalali(1404, 13, 1), throwsRangeError);
      expect(() => Jalali(1404, 7, 31), throwsRangeError);
      expect(() => Jalali(0, 1, 1), throwsRangeError);
      expect(Jalali.isValid(1404, 6, 31), isTrue);
      expect(() => Jalali.fromDateTime(DateTime(100, 1, 1)), throwsRangeError);
    });

    test('weekday', () {
      final nowruz = Jalali(1404, 1, 1); // Friday 2025-03-21
      expect(nowruz.weekday, DateTime.friday);
      expect(nowruz.weekdayIndex, 6);
      expect(nowruz.weekdayName, 'جمعه');
      expect(Jalali(1404, 1, 2).weekdayName, 'شنبه');
      expect(Jalali(1404, 1, 3).weekdayName, 'یکشنبه');
    });

    test('dayOfYear', () {
      expect(Jalali(1404, 1, 1).dayOfYear, 1);
      expect(Jalali(1404, 6, 31).dayOfYear, 186);
      expect(Jalali(1404, 7, 1).dayOfYear, 187);
      expect(Jalali(1403, 12, 30).dayOfYear, 366);
      expect(Jalali(1404, 12, 29).dayOfYear, 365);
    });

    test('arithmetic', () {
      expect(Jalali(1404, 12, 29).addDays(1), Jalali(1405, 1, 1));
      expect(Jalali(1403, 12, 29).addDays(1), Jalali(1403, 12, 30));
      expect(Jalali(1404, 1, 1).addDays(-1), Jalali(1403, 12, 30));
      expect(Jalali(1404, 1, 1).addDays(366), Jalali(1405, 1, 2));
      expect(Jalali(1404, 1, 31).addMonths(6), Jalali(1404, 7, 30)); // clamp
      expect(Jalali(1404, 1, 31).addMonths(-1), Jalali(1403, 12, 30));
      expect(Jalali(1403, 12, 30).addYears(1), Jalali(1404, 12, 29)); // clamp
      expect(Jalali(1404, 5, 5).addMonths(12), Jalali(1405, 5, 5));
      expect(Jalali(1405, 1, 1).differenceInDays(Jalali(1404, 1, 1)), 365);
      expect(Jalali(1404, 1, 1).differenceInDays(Jalali(1405, 1, 1)), -365);
    });

    test('equality, hashing, ordering', () {
      expect(Jalali(1404, 1, 1), Jalali(1404, 1, 1));
      expect({Jalali(1404, 1, 1), Jalali(1404, 1, 1)}.length, 1);
      expect(Jalali(1404, 1, 2) > Jalali(1404, 1, 1), isTrue);
      expect(Jalali(1403, 12, 30) < Jalali(1404, 1, 1), isTrue);
      expect(Jalali(1404, 1, 1) >= Jalali(1404, 1, 1), isTrue);
      expect(Jalali(1404, 1, 1) <= Jalali(1403, 1, 1), isFalse);
      final sorted = [
        Jalali(1404, 5, 1),
        Jalali(1400, 1, 1),
        Jalali(1404, 1, 9)
      ]..sort();
      expect(sorted.first, Jalali(1400, 1, 1));
      expect(sorted.last, Jalali(1404, 5, 1));
    });

    test('parse accepts separators and any digit system', () {
      expect(Jalali.parse('1404/01/01'), Jalali(1404, 1, 1));
      expect(Jalali.parse('۱۴۰۴-۱۰-۲۵'), Jalali(1404, 10, 25));
      expect(Jalali.parse('١٤٠٤.٠٢.٠٣'), Jalali(1404, 2, 3));
      expect(Jalali.tryParse('1404/13/01'), isNull);
      expect(Jalali.tryParse('1404/12/30'), isNull);
      expect(Jalali.tryParse('hello'), isNull);
      expect(() => Jalali.parse('x'), throwsFormatException);
    });
  });

  group('Jalali.format', () {
    final d = Jalali(1404, 1, 1); // جمعه
    test('default and numeric tokens', () {
      expect(d.format(), '1404/01/01');
      expect(d.toString(), '1404/01/01');
      expect(d.format('yy-M-d'), '04-1-1');
      expect(d.format('yyyy/MM/dd', DigitSystem.persian), '۱۴۰۴/۰۱/۰۱');
      expect(d.format('yyyy/MM/dd', DigitSystem.arabicIndic), '١٤٠٤/٠١/٠١');
    });
    test('names', () {
      expect(d.format('EEEE d MMMM yyyy'), 'جمعه 1 فروردین 1404');
      expect(d.format('EEEE d MMMM yyyy', DigitSystem.persian),
          'جمعه ۱ فروردین ۱۴۰۴');
      expect(d.format('E'), 'ج');
      expect(Jalali(1404, 12, 29).format('MMMM'), 'اسفند');
      expect(Jalali(1404, 5, 9).format('MMM'), 'مرداد');
    });
    test('quoted literals', () {
      expect(d.format("d MMMM 'سال' yyyy", DigitSystem.persian),
          '۱ فروردین سال ۱۴۰۴');
      expect(d.format("'It''s' d"), "It's 1");
      expect(d.format("'open"), 'open'); // unterminated quote is tolerated
    });
    test('pad widths', () {
      expect(Jalali(1404, 5, 9).format('dd/MM'), '09/05');
      expect(Jalali(5, 5, 9).format('yyyy'), '0005');
    });
  });

  group('Hijri', () {
    test('epoch and round trip', () {
      expect(Hijri(1, 1, 1).toDateTime(), DateTime(622, 7, 19));
      var g = DateTime.utc(1900, 1, 1);
      for (var i = 0; i < 40000; i += 7) {
        final x = DateTime.utc(g.year, g.month, g.day + i);
        final h = Hijri.fromDateTime(x);
        expect(h.toDateTime(), DateTime(x.year, x.month, x.day),
            reason: '$x -> $h');
        expect(h.day >= 1 && h.day <= Hijri.daysInMonthOf(h.year, h.month),
            isTrue);
      }
    });
    test('known date within the tabular calendar', () {
      final h = Hijri.fromDateTime(DateTime(2000, 1, 1));
      expect((h.year, h.month), (1420, 9)); // Ramadan 1420
      expect((h.day - 24).abs() <= 1, isTrue, reason: '$h');
    });
    test('names, validation, leap years', () {
      expect(Hijri(1447, 9, 1).monthNameFa, 'رمضان');
      expect(Hijri(1447, 3, 1).monthNameAr, 'ربيع الأول');
      expect(() => Hijri(1447, 2, 30), throwsRangeError);
      expect(
          Hijri.isLeap(1445), isTrue); // 14+11*1445 = 15909 -> 15909 % 30 = 9
      expect(
          Hijri.isLeap(1446), isFalse); // 14+11*1446 = 15920 -> 15920 % 30 = 20
      expect(Hijri(1445, 12, 30).toString(), '1445/12/30');
    });
  });
}
