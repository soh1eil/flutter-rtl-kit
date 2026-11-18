/// Persian / Arabic text normalisation.
library;

import 'digits.dart';

const int _zwnj = 0x200C;
const int _zwj = 0x200D;

/// Arabic Yeh `ي` and Alef Maksura `ى` become Farsi Yeh `ی` (U+06CC); Arabic
/// Kaf `ك` becomes Keheh `ک` (U+06A9).
const Map<int, int> _persianLetters = {
  0x064A: 0x06CC,
  0x0649: 0x06CC,
  0x0643: 0x06A9,
};

final RegExp _harakat = RegExp(
  '[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E4\u06E7\u06E8\u06EA-\u06ED]',
);
final RegExp _whitespace =
    RegExp(r'[ \t\r\n\u00A0\u2000-\u200A\u202F\u205F\u3000]+');

/// Normalises Arabic-keyboard letters to their Persian forms.
///
/// * `ي` `ى` -> `ی`
/// * `ك` -> `ک`
/// * with [digits], digits are rewritten into that system (default: left as is)
/// * with [zwnj] (default `true`), stray half-spaces are tidied, see [cleanZwnj]
///
/// Harakat are kept. Use [removeHarakat] to drop them.
String normalizePersian(String text, {DigitSystem? digits, bool zwnj = true}) {
  final out = StringBuffer();
  for (final r in text.runes) {
    out.writeCharCode(_persianLetters[r] ?? r);
  }
  var s = out.toString();
  if (zwnj) s = cleanZwnj(s);
  if (digits != null) s = convertDigits(s, digits);
  return s;
}

/// Tidies the zero-width non-joiner (half-space).
///
/// * runs of ZWNJ collapse to one;
/// * a ZWNJ next to whitespace, or at the start or end, is removed (it has no
///   visible effect there and breaks equality checks);
/// * a ZWNJ next to a ZWJ is removed.
///
/// A ZWNJ between two letters, the case it exists for (`می‌خواهم`), is kept.
String cleanZwnj(String text) {
  final runes = text.runes.toList();
  final out = <int>[];
  bool isSpace(int r) => _whitespace.hasMatch(String.fromCharCode(r));
  for (var i = 0; i < runes.length; i++) {
    final r = runes[i];
    if (r != _zwnj) {
      out.add(r);
      continue;
    }
    if (out.isEmpty ||
        isSpace(out.last) ||
        out.last == _zwnj ||
        out.last == _zwj) {
      continue;
    }
    // Look ahead past any further ZWNJs.
    var j = i + 1;
    while (j < runes.length && runes[j] == _zwnj) {
      j++;
    }
    if (j >= runes.length || isSpace(runes[j]) || runes[j] == _zwj) continue;
    out.add(_zwnj);
    i = j - 1;
  }
  return String.fromCharCodes(out);
}

/// Replaces every ZWNJ with a normal space (`می‌خواهم` -> `می خواهم`).
String zwnjToSpace(String text) => text.replaceAll('\u200C', ' ');

/// Removes every ZWNJ (`می‌خواهم` -> `میخواهم`).
String removeZwnj(String text) => text.replaceAll('\u200C', '');

/// Removes Arabic diacritics: fatha, damma, kasra, tanwin, shadda, sukun,
/// dagger alef and the Quranic annotation marks.
///
/// Tatweel is *not* a diacritic. See [removeTatweel].
String removeHarakat(String text) => text.replaceAll(_harakat, '');

/// Removes the kashida / tatweel elongation character `ـ`.
String removeTatweel(String text) => text.replaceAll('\u0640', '');

/// A key suitable for case-, spelling- and keyboard-insensitive matching.
///
/// Both the stored value and the query should go through this function, and
/// then be compared with `contains`:
///
/// 1. Persian normalisation (`ي`->`ی`, `ك`->`ک`);
/// 2. harakat and tatweel removed;
/// 3. ZWNJ removed, so `میخواهم` and `می‌خواهم` match;
/// 4. hamza carriers folded: `أ إ آ ٱ` -> `ا`, `ة` -> `ه`, `ؤ` -> `و`, `ئ` -> `ی`;
/// 5. all digits become `0-9`;
/// 6. Latin letters are lower-cased, whitespace is collapsed and trimmed.
String searchKey(String text) {
  var s = normalizePersian(text, zwnj: false);
  s = removeTatweel(removeHarakat(s));
  s = removeZwnj(s);
  final out = StringBuffer();
  for (final r in s.runes) {
    switch (r) {
      case 0x0623 || 0x0625 || 0x0622 || 0x0671:
        out.write('ا');
      case 0x0629:
        out.write('ه');
      case 0x0624:
        out.write('و');
      case 0x0626:
        out.write('ی');
      default:
        out.writeCharCode(r);
    }
  }
  return toLatinDigits(out.toString())
      .toLowerCase()
      .replaceAll(_whitespace, ' ')
      .trim();
}
