/// First-class RTL toolkit for Persian and Arabic Flutter apps.
///
/// * [Jalali] and [Hijri] calendars
/// * digit conversion and number parsing ([convertDigits], [parseNumber])
/// * Persian/Arabic normalisation ([normalizePersian], [searchKey])
/// * bidi safety ([firstStrongDirection], [isolate], [stripBidiOverrides])
/// * widgets ([AutoDirectionText], [AutoDirection], [DirectionalTextField])
/// * number and relative-time formatting ([RtlNumberFormat], [formatRelativeTimeFa])
library;

export 'src/bidi.dart';
export 'src/digits.dart';
export 'src/extensions.dart';
export 'src/hijri.dart';
export 'src/jalali.dart';
export 'src/normalize.dart';
export 'src/number_format.dart';
export 'src/relative_time.dart';
export 'src/widgets.dart';
