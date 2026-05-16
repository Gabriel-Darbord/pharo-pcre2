[![Pharo version](https://img.shields.io/badge/Pharo-12-%23aac9ff.svg)](https://github.com/pharo-project/Pharo)
![Build Info](https://github.com/Gabriel-Darbord/pharo-pcre2/workflows/CI/badge.svg)
[![Coverage Status](https://coveralls.io/repos/github/Gabriel-Darbord/pharo-pcre2/badge.svg?branch=main)](https://coveralls.io/github/Gabriel-Darbord/pharo-pcre2?branch=main)

# Pharo-PCRE2

Perl-compatible regular expressions for Pharo, backed by the native [PCRE2](https://github.com/PCRE2Project/pcre2) library through FFI.

## Installation

Load the project into a Pharo image with Metacello:

```smalltalk
Metacello new
  githubUser: 'Gabriel-Darbord' project: 'pharo-pcre2' commitish: 'main' path: 'src';
  baseline: 'PCRE2';
  load
```

The native PCRE2 8-bit library must be available on the host. The UTF-16 and UTF-32 APIs also use `libpcre2-16` and `libpcre2-32` when present.

Linux:

```sh
sudo apt install libpcre2-dev
```

macOS:

```sh
brew install pcre2
```

## Quick Start

Compile a pattern by sending `asPerlCompatibleRegex` to a string.

```smalltalk
matcher := '\b\w+\b' asPerlCompatibleRegex.
matcher search: 'hello world'.
matcher matches: 'hello'.
matcher matchesPrefix: 'hello world'.
```

Use `findMatch:` when you want to keep the match object and query it later.

```smalltalk
matcher := '(?<key>\w+)=(?<value>\d+)' asPerlCompatibleRegex.
match := matcher findMatch: 'size=42'.
match groupAt: 0.       "size=42"
match groupNamed: 'key'.   "size"
match groupNamed: 'value'. "42"
match matchDataSize.       "native PCRE2 match-data bytes"
match heapframesSize.      "native heap-frame bytes retained by the match data"
```

Useful collection-style operations are available on the matcher:

```smalltalk
'\d+' asPerlCompatibleRegex findAll: 'a1 b22 c333'.
'\s*,\s*' asPerlCompatibleRegex substituteAll: 'a, b,c' with: '|'.
'a, b,c' splitOn: '\s*,\s*' asPerlCompatibleRegex.
```

PCRE2 can also convert glob and POSIX patterns into Perl-compatible regular expressions:

```smalltalk
matcher := (LibPCRE2UTF8 convertGlob: '*.st') asPerlCompatibleRegex.
matcher matches: 'Package.st'. "true"
```

## Features

- Full, prefix, search, and match-object APIs.
- Numbered and named capture groups.
- Match enumeration, match ranges, splitting, and substitution.
- Glob and POSIX pattern conversion to PCRE2 syntax for UTF-8, UTF-16, and UTF-32.
- Prepared UTF-8, UTF-16, and UTF-32 inputs for repeated matching against the same subject.
- UTF-16 and UTF-32 support through `PCRE2UTF16Compiler` and `PCRE2UTF32Compiler`, including byte-backed prepared subjects and patterns with explicit-endian or BOM-aware helpers.
- Compile and match contexts for PCRE2 options and limits.
- JIT compilation and optional explicit JIT stack control for advanced cases.
- Partial matching and DFA matching.
- Match, substitution, and substitution case callouts.
- Native match-data memory diagnostics.
- Trace/debugger support in the `PCRE2-Tools` package.

## Lifecycle

Compiled PCRE2 patterns are native objects, so the project includes `PCRE2SessionManager` to restore them across image restarts. Serialization is used by default when the native library signature is compatible; otherwise matchers are recompiled from their saved pattern and options. Serialized caches are grouped by PCRE2 code-unit width.

The binding targets PCRE2 10.x. The usual API uses `LibPCRE2UTF8` and the 8-bit library; `LibPCRE2` itself is abstract. `PCRE2UTF16Compiler` and `PCRE2UTF32Compiler` use PCRE2's wider code-unit libraries when available. Minor PCRE2 versions may differ in reported configuration details, so tests and applications should prefer capability checks over exact minor-version strings.

## Documentation

User documentation lives in the `docs` folder and is shown by Pharo's documentation browser when the repository is available:

- `docs/GettingStarted.md`
- `docs/API.md`
- `docs/Lifecycle.md`

For the complete regular expression syntax, see the [official PCRE2 documentation](https://www.pcre.org/current/doc/html/index.html).
