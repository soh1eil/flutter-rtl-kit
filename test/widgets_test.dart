import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_rtl_kit/flutter_rtl_kit.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {TextDirection dir = TextDirection.ltr}) =>
    MaterialApp(
      builder: (context, c) => Directionality(textDirection: dir, child: c!),
      home: Scaffold(body: child),
    );

Text textOf(WidgetTester t) => t.widget<Text>(find.byType(Text).first);

void main() {
  group('AutoDirectionText', () {
    testWidgets('Persian text in an LTR app is RTL', (t) async {
      await t.pumpWidget(host(const AutoDirectionText('سلام دنیا')));
      expect(textOf(t).textDirection, TextDirection.rtl);
    });
    testWidgets('English text in an RTL app is LTR', (t) async {
      await t.pumpWidget(
          host(const AutoDirectionText('Hello'), dir: TextDirection.rtl));
      expect(textOf(t).textDirection, TextDirection.ltr);
    });
    testWidgets('neutral text takes the ambient direction, or the fallback',
        (t) async {
      await t.pumpWidget(
          host(const AutoDirectionText('123 !!'), dir: TextDirection.rtl));
      expect(textOf(t).textDirection, TextDirection.rtl);
      await t.pumpWidget(host(
          const AutoDirectionText('123 !!', fallback: TextDirection.ltr),
          dir: TextDirection.rtl));
      expect(textOf(t).textDirection, TextDirection.ltr);
    });
    testWidgets('mixed text follows the first strong character', (t) async {
      await t.pumpWidget(host(const AutoDirectionText('Soheil سهیل')));
      expect(textOf(t).textDirection, TextDirection.ltr);
      await t.pumpWidget(host(const AutoDirectionText('سهیل Soheil')));
      expect(textOf(t).textDirection, TextDirection.rtl);
    });
    testWidgets('start alignment hugs the right edge for Persian in an LTR app',
        (t) async {
      await t.pumpWidget(host(const AutoDirectionText('سلام', expand: true)));
      final p = t.renderObject<RenderParagraph>(find.byType(RichText));
      final box = p
          .getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: 4))
          .first;
      expect(p.size.width, greaterThan(300));
      expect(box.right, closeTo(p.size.width, 1.0));
    });
    testWidgets('English hugs the left edge in an RTL app', (t) async {
      await t.pumpWidget(host(const AutoDirectionText('Hi', expand: true),
          dir: TextDirection.rtl));
      final p = t.renderObject<RenderParagraph>(find.byType(RichText));
      final box = p
          .getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: 2))
          .first;
      expect(box.left, closeTo(0, 1.0));
    });
    testWidgets('forwards text options', (t) async {
      await t.pumpWidget(host(const AutoDirectionText('abc',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center)));
      final w = textOf(t);
      expect(w.maxLines, 2);
      expect(w.overflow, TextOverflow.ellipsis);
      expect(w.textAlign, TextAlign.center);
    });
  });

  group('AutoDirection', () {
    testWidgets('passes the resolved direction and applies Directionality',
        (t) async {
      TextDirection? seen;
      late BuildContext inner;
      await t.pumpWidget(host(AutoDirection(
        text: 'مرحبا',
        builder: (context, dir) {
          seen = dir;
          return Builder(builder: (c) {
            inner = c;
            return const SizedBox();
          });
        },
      )));
      expect(seen, TextDirection.rtl);
      expect(Directionality.of(inner), TextDirection.rtl);
    });
    testWidgets('applyDirectionality: false leaves the ambient direction',
        (t) async {
      late BuildContext inner;
      await t.pumpWidget(host(AutoDirection(
        text: 'مرحبا',
        applyDirectionality: false,
        builder: (context, dir) => Builder(builder: (c) {
          inner = c;
          return const SizedBox();
        }),
      )));
      expect(Directionality.of(inner), TextDirection.ltr);
    });
    testWidgets('re-resolves when the text changes', (t) async {
      final seen = <TextDirection>[];
      Widget build(String s) => host(AutoDirection(
          text: s,
          builder: (c, d) {
            seen.add(d);
            return const SizedBox();
          }));
      await t.pumpWidget(build('abc'));
      await t.pumpWidget(build('سلام'));
      expect(seen.first, TextDirection.ltr);
      expect(seen.last, TextDirection.rtl);
    });
  });

  group('DirectionalTextField', () {
    TextDirection? fieldDirection(WidgetTester t) =>
        t.widget<EditableText>(find.byType(EditableText)).textDirection;

    testWidgets('flips as the user types', (t) async {
      await t.pumpWidget(host(const DirectionalTextField()));
      expect(fieldDirection(t), TextDirection.ltr); // empty: ambient

      await t.enterText(find.byType(TextField), 'سلام');
      await t.pump();
      expect(fieldDirection(t), TextDirection.rtl);

      await t.enterText(find.byType(TextField), 'hello');
      await t.pump();
      expect(fieldDirection(t), TextDirection.ltr);

      await t.enterText(find.byType(TextField), '');
      await t.pump();
      expect(fieldDirection(t), TextDirection.ltr);
    });

    testWidgets('an empty field uses emptyDirection', (t) async {
      await t.pumpWidget(
          host(const DirectionalTextField(emptyDirection: TextDirection.rtl)));
      expect(fieldDirection(t), TextDirection.rtl);
      await t.enterText(find.byType(TextField), 'abc');
      await t.pump();
      expect(fieldDirection(t), TextDirection.ltr);
      await t.enterText(find.byType(TextField), '');
      await t.pump();
      expect(fieldDirection(t), TextDirection.rtl);
    });

    testWidgets('neutral input keeps the last strong direction', (t) async {
      await t.pumpWidget(host(const DirectionalTextField()));
      await t.enterText(find.byType(TextField), 'سلام');
      await t.pump();
      await t.enterText(find.byType(TextField), '123');
      await t.pump();
      expect(fieldDirection(t), TextDirection.rtl);
    });

    testWidgets('starts in the right direction for an initial value',
        (t) async {
      final c = TextEditingController(text: 'مرحبا');
      addTearDown(c.dispose);
      await t.pumpWidget(host(DirectionalTextField(controller: c)));
      expect(fieldDirection(t), TextDirection.rtl);
    });

    testWidgets('follows an externally set controller value', (t) async {
      final c = TextEditingController();
      addTearDown(c.dispose);
      await t.pumpWidget(host(DirectionalTextField(controller: c)));
      c.text = 'سلام';
      await t.pump();
      expect(fieldDirection(t), TextDirection.rtl);
    });

    testWidgets('callbacks fire, and onDirectionChanged only on change',
        (t) async {
      final changed = <TextDirection>[];
      final typed = <String>[];
      await t.pumpWidget(host(DirectionalTextField(
        onChanged: typed.add,
        onDirectionChanged: changed.add,
      )));
      await t.enterText(find.byType(TextField), 'س');
      await t.enterText(find.byType(TextField), 'سل');
      await t.enterText(find.byType(TextField), 'سلا');
      await t.enterText(find.byType(TextField), 'a');
      await t.pump();
      expect(typed, ['س', 'سل', 'سلا', 'a']);
      expect(changed, [TextDirection.rtl, TextDirection.ltr]);
    });

    testWidgets(
        'swapping the controller rewires the listener and does not leak',
        (t) async {
      final a = TextEditingController(),
          b = TextEditingController(text: 'שלום');
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      await t.pumpWidget(host(DirectionalTextField(controller: a)));
      await t.pumpWidget(host(DirectionalTextField(controller: b)));
      expect(fieldDirection(t), TextDirection.rtl);
      a.text = 'english'; // old controller must not drive the field any more
      await t.pump();
      expect(fieldDirection(t), TextDirection.rtl);
      await t.pumpWidget(
          const SizedBox()); // disposal with an external controller is safe
    });

    testWidgets('passes decoration and text options through', (t) async {
      await t.pumpWidget(host(const DirectionalTextField(
        decoration: InputDecoration(hintText: 'نام'),
        maxLength: 5,
        obscureText: true,
        maxLines: 3,
      )));
      expect(find.text('نام'), findsOneWidget);
      final f = t.widget<TextField>(find.byType(TextField));
      expect(f.maxLength, 5);
      expect(f.obscureText, isTrue);
      expect(f.maxLines, 1); // obscured fields are single line
    });
  });
}
