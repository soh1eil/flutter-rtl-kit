# Changelog

## 0.1.0

First release.

- `Jalali` calendar: conversion both ways, validation, arithmetic, parsing, pattern formatting, Persian month and weekday names. Verified against published Nowruz dates and a day-by-day round trip from 1200 to 1600.
- `Hijri`: tabular civil calendar helper (documented as approximate).
- Digits: Latin, Persian and Arabic-Indic conversion, and `parseNumber` for text typed in any of them.
- Normalisation: `normalizePersian`, `cleanZwnj`, `removeHarakat`, `removeTatweel`, `searchKey`.
- Bidi safety: `firstStrongDirection` (UAX #9 rule P2), `isolate`, `stripBidiOverrides`.
- Widgets: `AutoDirectionText`, `AutoDirection`, `DirectionalTextField`.
- Formatting: `RtlNumberFormat` (locale-aware digits and separators, no `intl`), `formatRelativeTimeFa`.
- `String` and `DateTime` extensions.
