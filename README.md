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

The native PCRE2 8-bit library must be available on the host. The UTF-32 API also uses `libpcre2-32` when present.

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
```

Useful collection-style operations are available on the matcher:

```smalltalk
'\d+' asPerlCompatibleRegex findAll: 'a1 b22 c333'.
'\s*,\s*' asPerlCompatibleRegex substituteAll: 'a, b,c' with: '|'.
'a, b,c' splitOn: '\s*,\s*' asPerlCompatibleRegex.
```

PCRE2 can also convert glob and POSIX patterns into Perl-compatible regular expressions:

```smalltalk
matcher := (PCRE2 convertGlob: '*.st') asPerlCompatibleRegex.
matcher matches: 'Package.st'. "true"
```

## Features

- Full, prefix, search, and match-object APIs.
- Numbered and named capture groups.
- Match enumeration, match ranges, splitting, and substitution.
- Glob and POSIX pattern conversion to PCRE2 syntax.
- Prepared UTF-8 inputs for repeated matching against the same subject.
- UTF-32 compile and match support through `PCRE2Compiler32`.
- Compile and match contexts for PCRE2 options and limits.
- Partial matching and DFA matching.
- Match and substitution callouts.
- Trace/debugger support in the `PCRE2-Tools` package.

## Lifecycle

Compiled PCRE2 patterns are native objects, so the project includes `PCRE2SessionManager` to restore them across image restarts. Serialization is used by default when the native library signature is compatible; otherwise matchers are recompiled from their saved pattern and options.

The binding targets PCRE2 10.x. The usual API uses the 8-bit library; `PCRE2Compiler32` uses PCRE2's 32-bit code-unit library for UTF-32 matching. Minor PCRE2 versions may differ in reported configuration details, so tests and applications should prefer capability checks over exact minor-version strings.

## Documentation

User documentation lives in the `docs` folder and is shown by Pharo's documentation browser when the repository is available:

- `docs/GettingStarted.md`
- `docs/API.md`
- `docs/Lifecycle.md`

For the complete regular expression syntax, see the [official PCRE2 documentation](https://www.pcre.org/current/doc/html/index.html).
