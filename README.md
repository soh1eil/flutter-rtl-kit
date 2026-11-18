# flutter_rtl_kit

First-class right-to-left support for **Persian and Arabic** Flutter apps, in one dependency-free package (Flutter SDK only, no `intl`).

[فارسی](README.fa.md)

| | |
|---|---|
| **Jalali calendar** | conversion both ways, validation, arithmetic, parsing, pattern formatting, Persian month/weekday names; plus an approximate tabular **Hijri** helper |
| **Digits** | Latin, Persian (`۰۱۲`) and Arabic-Indic (`٠١٢`) conversion, and parsing numbers typed with any of them |
| **Normalisation** | `ي`→`ی`, `ك`→`ک`, ZWNJ cleanup, harakat and tatweel removal, a search key that makes spelling variants collide |
| **Bidi safety** | first-strong direction (UAX #9 rule P2), FSI/PDI isolation for user-generated text, stripping Trojan-Source style overrides |
| **Widgets** | `AutoDirectionText`, `AutoDirection`, `DirectionalTextField` |
| **Formatting** | locale-aware digits and separators, Persian relative time (`۵ دقیقه پیش`, `دیروز`) |

```yaml
dependencies:
  flutter_rtl_kit: ^0.1.0
```

```dart
import 'package:flutter_rtl_kit/flutter_rtl_kit.dart';
```

## Jalali calendar

```dart
final d = Jalali.fromDateTime(DateTime(2025, 3, 21));
d;                                              // 1404/01/01
d.format('EEEE d MMMM yyyy');                   // جمعه 1 فروردین 1404
d.format('EEEE d MMMM yyyy', DigitSystem.persian); // جمعه ۱ فروردین ۱۴۰۴
d.format("d MMMM 'سال' yyyy", DigitSystem.persian); // ۱ فروردین سال ۱۴۰۴

Jalali(1403, 12, 30).toDateTime();              // 2025-03-20
Jalali(1404, 12, 30);                           // throws RangeError: 1404 is not a leap year
Jalali.tryParse('۱۴۰۴/۰۱/۰۱');                  // accepts any digits, and / - . separators

d.addDays(30); d.addMonths(-1); d.addYears(1);  // month and year steps clamp: 31 Farvardin + 6 months = 30 Mehr
d.weekdayName; d.isLeapYear; d.daysInMonth; d.dayOfYear;
DateTime.now().jalali;                          // extension
```

Format tokens: `yyyy yy`, `MMMM MMM` (name), `MM M`, `dd d`, `EEEE` (weekday name), `E` (initial), `'quoted text'`.

The conversion is exact for the Iranian civil calendar. It is tested against the published start of each Persian year 1300 to 1406, against dated historical events, and by walking **every day from 1200 to 1600** in both directions. Supported years are 1 to 3177.

`Hijri` is the *tabular* civil calendar: plain arithmetic, no moon sighting. It can differ from Umm al-Qura or an observed date by up to two days; do not use it for religious observance.

## Digits and numbers

```dart
toPersianDigits('Room 12');        // Room ۱۲
toLatinDigits('ساعت ۱۴:۳۰');       // ساعت 14:30
toArabicIndicDigits('2025');       // ٢٠٢٥
convertDigits(text, DigitSystem.persian);

parseNumber('۱٬۲۳۴٫۵');            // 1234.5
parseNumber('١٢٣');                // 123
parseNumber('1,234,567');          // 1234567  (a lone comma is grouping)
parseNumber('3,14', decimalSeparator: ','); // 3.14
parseNumber('abc');                // null, never throws
```

## Normalisation

```dart
normalizePersian('علي كتاب');                       // علی کتاب
normalizePersian('سال 1404', digits: DigitSystem.persian); // سال ۱۴۰۴
cleanZwnj('می‌‌خواهم ');                            // می‌خواهم  (runs collapsed, edge ZWNJ dropped)
removeHarakat('مُحَمَّدٌ');                          // محمد

// Spelling-, keyboard- and ZWNJ-insensitive search:
final hay = searchKey(contact.name);
hay.contains(searchKey(query));      // علي = علی, عَلِيّ, عـلـي ; میخواهم = می‌خواهم ; أحمد = احمد
```

## Bidi safety

```dart
firstStrongDirection('123 سلام');    // TextDirection.rtl  (digits are neutral)
firstStrongDirection('Soheil سهیل'); // TextDirection.ltr
firstStrongDirection('123');         // null

// User-generated text dropped into a sentence must not reorder what is around it:
final line = 'Message from ${isolate(user.name)}: ${isolate(body)}';

// Trojan Source: invisible overrides that make a name like "invoice" + U+202E + "txt.exe" display as if it ended in a different extension.
stripBidiOverrides(untrusted);       // removes LRE RLE PDF LRO RLO and LRI RLI FSI PDI
containsBidiControls(untrusted);
```

`isolate` strips formatting controls from its argument first, so a hostile string cannot close the isolate early and escape it. LRM, RLM, ZWNJ and ZWJ are legitimate and are preserved by default.

## Widgets

```dart
// Text that follows its own content, not the app locale.
const AutoDirectionText('سلام دنیا', expand: true);     // right-aligned in an LTR app
const AutoDirectionText('Hello', expand: true);         // left-aligned in an RTL app

// Direction for a whole subtree (icons, rows, padding):
AutoDirection(
  text: message.body,
  builder: (context, dir) => Row(
    textDirection: dir,
    children: [const Icon(Icons.person), Expanded(child: Text(message.body))],
  ),
);

// A field that flips as you type.
DirectionalTextField(
  controller: controller,
  decoration: const InputDecoration(labelText: 'Message'),
  emptyDirection: TextDirection.rtl,                     // before the first key
  onDirectionChanged: (d) {},
);
```

Neutral input (digits, punctuation) keeps the last strong direction instead of flickering, and an empty field returns to `emptyDirection` or the ambient direction.

## Formatting

```dart
RtlNumberFormat('fa').format(1234567.891, maxDecimals: 2); // ۱٬۲۳۴٬۵۶۷٫۸۹
RtlNumberFormat('ar').format(1234.5, maxDecimals: 1);       // ١٬٢٣٤٫٥
RtlNumberFormat('de').format(1234.5, maxDecimals: 1);       // 1.234,5
RtlNumberFormat('fa', digits: DigitSystem.latin).format(9000); // 9٬000
RtlNumberFormat('fa').formatPercent(0.25);                  // ۲۵٪
RtlNumberFormat('fa').parse('۱٬۲۳۴٫۵');                    // 1234.5

formatRelativeTimeFa(then);          // همین الان · ۵ دقیقه پیش · ۳ ساعت پیش · دیروز · ۲ هفته پیش · ۴ ماه پیش
formatRelativeTimeFa(future);        // ۲ ساعت دیگر · فردا · ۳ هفته دیگر
then.relativeFa();                   // extension
```

Built-in symbols: `en fa ur ps ar he fr de es tr ru`; Maghreb Arabic locales (`ar-MA`, `ar-DZ`...) get Latin digits. Unknown locales fall back to English. Everything is overridable (`digits`, `decimalSeparator`, `groupSeparator`, `useGrouping`).

Relative time compares *calendar days* beyond 22 hours, so 23:50 yesterday seen at 00:10 is "۲۰ دقیقه پیش", and 30 hours ago can still be "دیروز".

## Extensions

`String`: `toPersianDigits() toLatinDigits() toArabicIndicDigits() parseLocalizedNumber() normalizePersian() removeHarakat() searchKey firstStrongDirection isolated() stripBidiOverrides()`.
`DateTime`: `jalali`, `relativeFa()`.

## Example

`example/` is a small app showing everything above in an English-locale app. Run `flutter create .` inside `example/` once to generate the platform folders, then `flutter run`.

## Notes

- Zero dependencies beyond the Flutter SDK. No `intl`: number and relative-time formatting are self-contained, so they cannot drift from your `intl` version.
- Pure functions (`digits`, `normalize`, `bidi`, `Jalali`) have no state and are safe to call from any isolate.
- Month and weekday names are Persian. Pass the numbers through `DigitSystem` to choose the numerals.

## License

MIT
