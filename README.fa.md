# flutter_rtl_kit

ابزار راست‌به‌چپِ درجه‌یک برای اپ‌های فلاترِ **فارسی و عربی**، در یک پکیج بدون وابستگی (فقط Flutter SDK، بدون `intl`).

[English](README.md)

| | |
|---|---|
| **تقویم جلالی** | تبدیل دوطرفه، اعتبارسنجی، محاسبات، تجزیه، قالب‌بندی با الگو، نام ماه و روز هفته به فارسی؛ به‌علاوه‌ی یک **هجری** جدولی و تقریبی |
| **ارقام** | تبدیل لاتین، فارسی (`۰۱۲`) و عربی-هندی (`٠١٢`) و خواندن عددی که با هر کدام تایپ شده |
| **یکسان‌سازی متن** | `ي`←`ی`، `ك`←`ک`، مرتب‌کردن نیم‌فاصله، حذف اعراب و کشیده، کلید جست‌وجو که املاهای مختلف را یکی می‌کند |
| **ایمنی دوسویه (bidi)** | تشخیص جهت از اولین نویسه‌ی قوی، ایزوله‌کردن (FSI/PDI) متن کاربر، حذف کنترل‌های خطرناکِ شبیه حمله‌ی Trojan Source |
| **ویجت‌ها** | `AutoDirectionText`، `AutoDirection`، `DirectionalTextField` |
| **قالب‌بندی** | عدد با ارقام و جداکننده‌ی هر زبان، زمان نسبی فارسی (`۵ دقیقه پیش`، `دیروز`) |

```yaml
dependencies:
  flutter_rtl_kit: ^0.1.0
```

```dart
import 'package:flutter_rtl_kit/flutter_rtl_kit.dart';
```

## تقویم جلالی

```dart
final d = Jalali.fromDateTime(DateTime(2025, 3, 21));
d.format('EEEE d MMMM yyyy', DigitSystem.persian); // جمعه ۱ فروردین ۱۴۰۴
d.format("d MMMM 'سال' yyyy", DigitSystem.persian); // ۱ فروردین سال ۱۴۰۴

Jalali(1403, 12, 30).toDateTime();   // 2025-03-20
Jalali(1404, 12, 30);                // RangeError: ۱۴۰۴ کبیسه نیست
Jalali.tryParse('۱۴۰۴/۰۱/۰۱');       // هر نوع رقم و جداکننده‌ی / - .

d.addDays(30); d.addMonths(-1); d.addYears(1);
d.weekdayName; d.isLeapYear; d.daysInMonth;
DateTime.now().jalali;
```

نشانه‌های الگو: `yyyy yy`، `MMMM MMM` (نام ماه)، `MM M`، `dd d`، `EEEE` (نام روز)، `E` (حرف اول)، `'متن ثابت'`.

تبدیل برای تقویم رسمی ایران دقیق است. با آغاز رسمی هر سال از ۱۳۰۰ تا ۱۴۰۶، با رویدادهای تاریخی‌ِ تاریخ‌دار، و با پیمایشِ **تک‌تک روزهای ۱۲۰۰ تا ۱۶۰۰** در هر دو جهت آزمایش شده است. سال‌های پشتیبانی‌شده: ۱ تا ۳۱۷۷.

`Hijri` تقویم هجری **جدولی** است: محاسبه‌ی ساده، بدون رؤیت هلال. تا دو روز با ام‌القری یا تاریخ رؤیتی فرق دارد؛ برای امور شرعی استفاده نشود.

## ارقام و اعداد

```dart
toPersianDigits('Room 12');      // Room ۱۲
toLatinDigits('ساعت ۱۴:۳۰');     // ساعت 14:30
parseNumber('۱٬۲۳۴٫۵');          // 1234.5
parseNumber('١٢٣');              // 123
parseNumber('abc');              // null (هرگز استثنا نمی‌اندازد)
```

## یکسان‌سازی متن

```dart
normalizePersian('علي كتاب');    // علی کتاب
removeHarakat('مُحَمَّدٌ');       // محمد

// جست‌وجوی مستقل از املا، صفحه‌کلید و نیم‌فاصله:
searchKey(name).contains(searchKey(query));
// علي = علی ؛ میخواهم = می‌خواهم ؛ أحمد = احمد
```

## ایمنی دوسویه

```dart
firstStrongDirection('123 سلام');  // rtl (ارقام خنثی‌اند)
final line = 'پیام از ${isolate(user.name)}: ${isolate(body)}';
stripBidiOverrides(untrusted);     // حذف LRE RLE PDF LRO RLO و LRI RLI FSI PDI
```

`isolate` پیش از بستن، کنترل‌های جهت را از ورودی پاک می‌کند تا رشته‌ی مخرب نتواند ایزوله را زودتر ببندد. LRM، RLM، نیم‌فاصله و ZWJ مشروع‌اند و به‌طور پیش‌فرض می‌مانند.

## ویجت‌ها

```dart
const AutoDirectionText('سلام دنیا', expand: true);   // در اپ LTR هم راست‌چین
const AutoDirectionText('Hello', expand: true);       // در اپ RTL هم چپ‌چین

AutoDirection(
  text: message.body,
  builder: (context, dir) => Row(textDirection: dir, children: [/* ... */]),
);

DirectionalTextField(
  controller: controller,
  emptyDirection: TextDirection.rtl,   // پیش از اولین کلید
);
```

ورودیِ خنثی (رقم، علامت) آخرین جهتِ قوی را نگه می‌دارد و فیلد پرش نمی‌کند.

## قالب‌بندی

```dart
RtlNumberFormat('fa').format(1234567.891, maxDecimals: 2); // ۱٬۲۳۴٬۵۶۷٫۸۹
RtlNumberFormat('ar').format(1234.5, maxDecimals: 1);       // ١٬٢٣٤٫٥
RtlNumberFormat('fa').formatPercent(0.25);                  // ۲۵٪

formatRelativeTimeFa(then);   // همین الان · ۵ دقیقه پیش · دیروز · ۲ هفته پیش
formatRelativeTimeFa(future); // ۲ ساعت دیگر · فردا
```

زمان نسبی، پس از ۲۲ ساعت، *روزهای تقویمی* را مقایسه می‌کند؛ پس ۲۳:۵۰ دیروز در ۰۰:۱۰ می‌شود «۲۰ دقیقه پیش».

## نمونه

پوشه‌ی `example/` یک اپ کوچک با همه‌ی موارد بالا در یک اپ با زبان انگلیسی است. یک‌بار در همان پوشه `flutter create .` بزنید تا پوشه‌های پلتفرم ساخته شوند، سپس `flutter run`.

## مجوز

MIT
