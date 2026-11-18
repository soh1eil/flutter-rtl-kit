import 'package:flutter/material.dart';
import 'package:flutter_rtl_kit/flutter_rtl_kit.dart';

void main() => runApp(const ExampleApp());

/// An English-locale app that still renders Persian and Arabic correctly.
class ExampleApp extends StatelessWidget {
  /// Creates the app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'flutter_rtl_kit',
        theme: ThemeData(
            colorSchemeSeed: const Color(0xFF4A6B63), useMaterial3: true),
        home: const ExampleHome(),
      );
}

/// The demo page.
class ExampleHome extends StatefulWidget {
  /// Creates the page.
  const ExampleHome({super.key});

  @override
  State<ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<ExampleHome> {
  final _typed = TextEditingController(text: 'علي كتاب ۱۲۳');
  DateTime _day = DateTime(2025, 3, 21);

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jalali = Jalali.fromDateTime(_day);
    final fa = RtlNumberFormat('fa');
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_rtl_kit')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Section('Jalali calendar'),
          Row(children: [
            IconButton(
              tooltip: 'Previous day',
              icon: const Icon(Icons.chevron_left),
              onPressed: () =>
                  setState(() => _day = _day.subtract(const Duration(days: 1))),
            ),
            Expanded(
              child: AutoDirectionText(
                jalali.format('EEEE d MMMM yyyy', DigitSystem.persian),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              tooltip: 'Next day',
              icon: const Icon(Icons.chevron_right),
              onPressed: () =>
                  setState(() => _day = _day.add(const Duration(days: 1))),
            ),
          ]),
          Center(
              child:
                  Text('${_day.year}-${_day.month}-${_day.day}  ->  $jalali')),
          const _Section('Auto-direction text (the app itself is LTR)'),
          const AutoDirectionText('سلام، این یک جمله‌ی فارسی است.',
              expand: true),
          const AutoDirectionText('This is an English sentence.', expand: true),
          const AutoDirectionText(
              'Soheil سهیل starts with Latin, so it is LTR.',
              expand: true),
          const _Section('DirectionalTextField: type Persian, then English'),
          DirectionalTextField(
            controller: _typed,
            decoration: const InputDecoration(
                border: OutlineInputBorder(), labelText: 'Type here'),
            onChanged: (_) => setState(() {}),
          ),
          const _Section('Normalisation and search key'),
          _Row('normalizePersian',
              _typed.text.normalizePersian(digits: DigitSystem.persian)),
          _Row('searchKey', _typed.text.searchKey),
          _Row('toLatinDigits', _typed.text.toLatinDigits()),
          const _Section('Numbers'),
          _Row('fa', fa.format(1234567.891, maxDecimals: 2)),
          _Row('ar', RtlNumberFormat('ar').format(1234567.891, maxDecimals: 2)),
          _Row('en', RtlNumberFormat('en').format(1234567.891, maxDecimals: 2)),
          _Row('parse "۱٬۲۳۴٫۵"', '${parseNumber('۱٬۲۳۴٫۵')}'),
          const _Section('Relative time'),
          _Row('5 min ago',
              formatRelativeTimeFa(now.subtract(const Duration(minutes: 5)))),
          _Row('yesterday',
              formatRelativeTimeFa(now.subtract(const Duration(days: 1)))),
          _Row('in 3 weeks',
              formatRelativeTimeFa(now.add(const Duration(days: 22)))),
          const _Section('Bidi safety'),
          _Row('hostile name', '${_hostile.runes.length} code points, raw'),
          _Row('stripped', stripBidiOverrides(_hostile)),
          _Row('isolated in a sentence',
              'Message from ${isolate(_hostile)}: hi'),
        ],
      ),
    );
  }
}

// An "invoice" whose file extension is visually reversed by an override.
final _hostile = 'invoice${String.fromCharCode(0x202E)}txt.exe';

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.labelLarge),
      );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(
              width: 150,
              child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: AutoDirectionText(value)),
        ]),
      );
}
