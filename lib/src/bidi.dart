/// Bidirectional text safety helpers.
library;

import 'dart:ui' show TextDirection;

/// U+2066 LEFT-TO-RIGHT ISOLATE.
const String lri = '\u2066';

/// U+2067 RIGHT-TO-LEFT ISOLATE.
const String rli = '\u2067';

/// U+2068 FIRST STRONG ISOLATE.
const String fsi = '\u2068';

/// U+2069 POP DIRECTIONAL ISOLATE.
const String pdi = '\u2069';

/// U+200E LEFT-TO-RIGHT MARK.
const String lrm = '\u200E';

/// U+200F RIGHT-TO-LEFT MARK.
const String rlm = '\u200F';

final RegExp _letter = RegExp(r'\p{L}', unicode: true);

// Blocks whose letters are strong right-to-left (bidi class R or AL).
bool _isRtlRange(int r) =>
    (r >= 0x0590 && r <= 0x08FF) ||
    (r >= 0xFB1D && r <= 0xFDFF) ||
    (r >= 0xFE70 && r <= 0xFEFF) ||
    (r >= 0x10800 && r <= 0x10FFF) ||
    (r >= 0x1E800 && r <= 0x1EFFF);

bool _isIsolateOpen(int r) => r >= 0x2066 && r <= 0x2068;

/// The direction of the first strong character in [text], or `null` if there is
/// none (empty text, digits, punctuation, emoji).
///
/// This follows rule P2 of the Unicode Bidirectional Algorithm, including its
/// provision that text inside an isolate (`FSI`, `LRI`, `RLI` ... `PDI`) is
/// skipped. Explicit marks `LRM` and `RLM` count as strong.
///
/// Digits are deliberately neutral: `"123 سلام"` is right-to-left and
/// `"123 hello"` is left-to-right.
TextDirection? firstStrongDirection(String text) {
  var depth = 0;
  for (final r in text.runes) {
    if (_isIsolateOpen(r)) {
      depth++;
      continue;
    }
    if (r == 0x2069) {
      if (depth > 0) depth--;
      continue;
    }
    if (depth > 0) continue;
    if (r == 0x200F || r == 0x061C) return TextDirection.rtl;
    if (r == 0x200E) return TextDirection.ltr;
    final isLetter = _letter.hasMatch(String.fromCharCode(r));
    if (!isLetter) continue;
    return _isRtlRange(r) ? TextDirection.rtl : TextDirection.ltr;
  }
  return null;
}

/// Convenience over [firstStrongDirection] with a [fallback] for neutral text.
TextDirection resolveDirection(String text, TextDirection fallback) =>
    firstStrongDirection(text) ?? fallback;

/// Whether [text] contains any explicit bidi *formatting* control: embeddings,
/// overrides, isolates or PDF. Marks (`LRM`, `RLM`, `ALM`) are not included.
bool containsBidiControls(String text) => _controls.hasMatch(text);

final RegExp _controls = RegExp('[\u202A-\u202E\u2066-\u2069]');

/// Removes the explicit directional formatting characters that can reorder
/// text invisibly: `LRE RLE PDF LRO RLO` (U+202A-U+202E) and
/// `LRI RLI FSI PDI` (U+2066-U+2069).
///
/// This is the defence against "Trojan Source" style spoofing
/// (CVE-2021-42574), where an invisible override makes a name or a file extension display as
/// something it is not. Run it on every piece of user-generated
/// text that you are about to display or log.
///
/// Marks (`LRM`, `RLM`, `ALM`) and ZWNJ/ZWJ are legitimate and are kept unless
/// [stripMarks] is `true`.
String stripBidiOverrides(String text, {bool stripMarks = false}) {
  var s = text.replaceAll(_controls, '');
  if (stripMarks) s = s.replaceAll(RegExp('[\u200E\u200F\u061C]'), '');
  return s;
}

/// Wraps [text] so its internal direction cannot leak into the surrounding
/// text, and the surrounding text cannot reorder it.
///
/// Use this for anything you do not control (display names, file names, chat
/// messages) when it is concatenated into a sentence:
///
/// ```dart
/// final label = 'Message from ${isolate(user.name)}: ${isolate(body)}';
/// ```
///
/// With no [direction] the first strong character decides (`FSI`). Existing
/// formatting controls inside [text] are stripped first, so a hostile string
/// cannot close the isolate early and escape it.
String isolate(String text, {TextDirection? direction}) {
  final safe = stripBidiOverrides(text);
  final open = switch (direction) {
    TextDirection.ltr => lri,
    TextDirection.rtl => rli,
    null => fsi,
  };
  return '$open$safe$pdi';
}

/// Removes isolates added by [isolate] (and any other bidi controls).
String unisolate(String text) => stripBidiOverrides(text);

/// Prefixes [text] with an LRM or RLM so that trailing neutral characters,
/// like the `.` in `"سلام."` placed in an LTR context, attach to the right side.
String withDirectionMark(String text, TextDirection direction) =>
    (direction == TextDirection.rtl ? rlm : lrm) + text;
