/// Widgets that follow the direction of the text instead of the app locale.
library;

import 'package:flutter/material.dart';

import 'bidi.dart';

/// Resolves the direction of [text] and hands it to [builder].
///
/// The direction is the first strong character's; text with none (empty,
/// digits, punctuation) uses [fallback], or the ambient [Directionality] when
/// that is null. With [applyDirectionality] (the default) the built subtree is
/// also wrapped in a [Directionality], so `start`/`end` and
/// [EdgeInsetsDirectional] inside it follow the text.
///
/// ```dart
/// AutoDirection(
///   text: message.body,
///   builder: (context, dir) => Row(
///     textDirection: dir,
///     children: [const Icon(Icons.person), Expanded(child: Text(message.body))],
///   ),
/// )
/// ```
class AutoDirection extends StatelessWidget {
  /// Creates an auto-direction scope.
  const AutoDirection({
    super.key,
    required this.text,
    required this.builder,
    this.fallback,
    this.applyDirectionality = true,
  });

  /// The text whose first strong character decides the direction.
  final String text;

  /// Builds the child with the resolved direction.
  final Widget Function(BuildContext context, TextDirection direction) builder;

  /// Direction for text with no strong character. Defaults to the ambient one.
  final TextDirection? fallback;

  /// Whether to wrap the result in a [Directionality].
  final bool applyDirectionality;

  @override
  Widget build(BuildContext context) {
    final dir = resolveDirection(text, fallback ?? Directionality.of(context));
    final child = builder(context, dir);
    return applyDirectionality
        ? Directionality(textDirection: dir, child: child)
        : child;
  }
}

/// A [Text] whose direction and alignment follow its own content.
///
/// A Persian sentence inside an English UI is laid out right-to-left and, with
/// the default [TextAlign.start], hugs the right edge of its box; an English
/// sentence inside a Persian UI hugs the left. Mixed text follows the first
/// strong character, like the Unicode Bidirectional Algorithm.
///
/// Give it width (put it in a `Column` with `crossAxisAlignment.stretch`, an
/// `Expanded`, or set [expand]) for the alignment to be visible.
class AutoDirectionText extends StatelessWidget {
  /// Creates the text.
  const AutoDirectionText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.fallback,
    this.expand = false,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textScaler,
    this.semanticsLabel,
  });

  /// The text.
  final String data;

  /// Text style.
  final TextStyle? style;

  /// Alignment. Defaults to [TextAlign.start], resolved against the text's own direction.
  final TextAlign? textAlign;

  /// Direction for text with no strong character. Defaults to the ambient one.
  final TextDirection? fallback;

  /// Take the full available width, so that alignment is visible.
  final bool expand;

  /// See [Text.maxLines].
  final int? maxLines;

  /// See [Text.overflow].
  final TextOverflow? overflow;

  /// See [Text.softWrap].
  final bool? softWrap;

  /// See [Text.textScaler].
  final TextScaler? textScaler;

  /// See [Text.semanticsLabel].
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final dir = resolveDirection(data, fallback ?? Directionality.of(context));
    final text = Text(
      data,
      style: style,
      textAlign: textAlign ?? TextAlign.start,
      textDirection: dir,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      textScaler: textScaler,
      semanticsLabel: semanticsLabel,
    );
    return expand ? SizedBox(width: double.infinity, child: text) : text;
  }
}

/// A [TextField] whose direction flips as the user types.
///
/// Typing Persian makes it right-to-left with the caret and text at the right,
/// typing English flips it back. An empty field uses [emptyDirection], or the
/// ambient direction when that is null, so the hint and caret sit where the
/// app expects them before the first key.
class DirectionalTextField extends StatefulWidget {
  /// Creates the field.
  const DirectionalTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration = const InputDecoration(),
    this.style,
    this.emptyDirection,
    this.onChanged,
    this.onSubmitted,
    this.onDirectionChanged,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled,
    this.autofocus = false,
    this.readOnly = false,
    this.obscureText = false,
  });

  /// Controls the text. If null the field owns one.
  final TextEditingController? controller;

  /// Controls focus.
  final FocusNode? focusNode;

  /// Decoration. Labels and hints follow the resolved direction.
  final InputDecoration decoration;

  /// Text style.
  final TextStyle? style;

  /// Direction while the field has no strong character. Defaults to ambient.
  final TextDirection? emptyDirection;

  /// See [TextField.onChanged].
  final ValueChanged<String>? onChanged;

  /// See [TextField.onSubmitted].
  final ValueChanged<String>? onSubmitted;

  /// Called when the resolved direction changes.
  final ValueChanged<TextDirection>? onDirectionChanged;

  /// See [TextField.keyboardType].
  final TextInputType? keyboardType;

  /// See [TextField.textInputAction].
  final TextInputAction? textInputAction;

  /// See [TextField.maxLines].
  final int? maxLines;

  /// See [TextField.minLines].
  final int? minLines;

  /// See [TextField.maxLength].
  final int? maxLength;

  /// See [TextField.enabled].
  final bool? enabled;

  /// See [TextField.autofocus].
  final bool autofocus;

  /// See [TextField.readOnly].
  final bool readOnly;

  /// See [TextField.obscureText].
  final bool obscureText;

  @override
  State<DirectionalTextField> createState() => _DirectionalTextFieldState();
}

class _DirectionalTextFieldState extends State<DirectionalTextField> {
  TextEditingController? _own;
  TextDirection? _strong;

  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _strong = firstStrongDirection(_controller.text);
    _controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(DirectionalTextField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      (old.controller ?? _own)?.removeListener(_onText);
      _controller.addListener(_onText);
      _strong = firstStrongDirection(_controller.text);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onText);
    _own?.dispose();
    super.dispose();
  }

  void _onText() {
    final s = firstStrongDirection(_controller.text);
    // Keep the last strong direction while the text is momentarily neutral
    // (the user typed "1" or deleted down to punctuation), but reset on empty.
    final next = _controller.text.isEmpty ? null : (s ?? _strong);
    if (next != _strong) {
      setState(() => _strong = next);
      final d = _resolved;
      if (d != null) widget.onDirectionChanged?.call(d);
    }
  }

  TextDirection? get _resolved => _strong ?? widget.emptyDirection;

  @override
  Widget build(BuildContext context) {
    final dir = _resolved ?? Directionality.of(context);
    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      decoration: widget.decoration,
      style: widget.style,
      textDirection: dir,
      textAlign: TextAlign.start,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText,
    );
  }
}
