import 'package:flutter_rtl_kit/flutter_rtl_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const zwnj = '\u200C';

  group('normalizePersian', () {
    test('Arabic yeh and kaf become Persian', () {
      expect(normalizePersian('علي'), 'علی');
      expect(normalizePersian('كتاب'), 'کتاب');
      expect(normalizePersian('مصطفى'), 'مصطفی'); // alef maksura
      expect(normalizePersian('كيك'), 'کیک');
    });
    test('already-Persian text is unchanged (idempotent)', () {
      const s = 'می$zwnjخواهم کتاب بخوانم';
      expect(normalizePersian(s), s);
      expect(normalizePersian(normalizePersian('علي كتاب')),
          normalizePersian('علي كتاب'));
    });
    test('ۀ and other distinct letters are kept', () {
      expect(normalizePersian('خانۀ ما'), 'خانۀ ما');
      expect(normalizePersian('گچپژ'), 'گچپژ');
    });
    test('optional digit conversion', () {
      expect(normalizePersian('سال 1404', digits: DigitSystem.persian),
          'سال ۱۴۰۴');
      expect(
          normalizePersian('سال ١٤٠٤', digits: DigitSystem.latin), 'سال 1404');
      expect(normalizePersian('سال 1404'), 'سال 1404');
    });
    test('harakat survive normalisation', () {
      expect(normalizePersian('كَتَبَ'), 'کَتَبَ');
    });
  });

  group('ZWNJ', () {
    test('keeps a meaningful half-space between letters', () {
      expect(cleanZwnj('می$zwnjخواهم'), 'می$zwnjخواهم');
    });
    test('collapses runs', () {
      expect(cleanZwnj('می$zwnj$zwnj$zwnjخواهم'), 'می$zwnjخواهم');
    });
    test('drops at the edges and next to spaces', () {
      expect(cleanZwnj('$zwnjسلام$zwnj'), 'سلام');
      expect(cleanZwnj('سلام$zwnj دنیا'), 'سلام دنیا');
      expect(cleanZwnj('سلام $zwnjدنیا'), 'سلام دنیا');
      expect(cleanZwnj('a$zwnj\u200Db'),
          'a\u200Db'); // the ZWNJ goes, the ZWJ stays
      expect(cleanZwnj(''), '');
      expect(cleanZwnj(zwnj), '');
    });
    test('zwnjToSpace and removeZwnj', () {
      expect(zwnjToSpace('می$zwnjخواهم'), 'می خواهم');
      expect(removeZwnj('می$zwnjخواهم'), 'میخواهم');
    });
  });

  group('harakat and tatweel', () {
    test('removeHarakat strips marks but not letters', () {
      expect(removeHarakat('مُحَمَّدٌ'), 'محمد');
      expect(removeHarakat('كِتَابٌ'), 'كتاب');
      expect(removeHarakat('الرَّحْمَٰنِ'), 'الرحمن');
      expect(removeHarakat('سلام'), 'سلام');
    });
    test('removeTatweel', () {
      expect(removeTatweel('الســـلام'), 'السلام');
    });
  });

  group('searchKey', () {
    test('different spellings of the same word collide', () {
      final k = searchKey('علي');
      expect(searchKey('علی'), k);
      expect(searchKey('عَلِيّ'), k);
      expect(searchKey('عـلـي'), k);
    });
    test('ZWNJ-less typing matches', () {
      expect(searchKey('می$zwnjخواهم'), searchKey('میخواهم'));
    });
    test('hamza carriers and teh marbuta', () {
      expect(searchKey('أحمد'), searchKey('احمد'));
      expect(searchKey('إسلام'), searchKey('اسلام'));
      expect(searchKey('آب'), searchKey('اب'));
      expect(searchKey('مدرسة'), searchKey('مدرسه'));
      expect(searchKey('مؤمن'), searchKey('مومن'));
      expect(searchKey('رئيس'), searchKey('رییس'));
    });
    test('digits, case and whitespace', () {
      expect(searchKey('  Room   ۱۲۳ \n'), 'room 123');
      expect(searchKey('TEHRAN'), 'tehran');
      expect(searchKey('١٢٣'), '123');
    });
    test('works as a contains() search', () {
      final stored = searchKey('دانشگاه تهران، دانشکده\u200Cی مهندسی');
      expect(stored.contains(searchKey('دانشکدهی')), isTrue);
      expect(stored.contains(searchKey('تهران')), isTrue);
      expect(stored.contains(searchKey('شیراز')), isFalse);
    });
    test('empty', () => expect(searchKey(''), ''));
  });
}
