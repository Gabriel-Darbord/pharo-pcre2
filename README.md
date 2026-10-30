[![Pharo version](https://img.shields.io/badge/Pharo-12%20%7C%2013%20%7C%2014%20%7C%2015-%23aac9ff.svg)](https://github.com/pharo-project/Pharo)
![Build Info](https://github.com/Gabriel-Darbord/pharo-pcre2/workflows/CI/badge.svg)
[![Coverage Status](https://coveralls.io/repos/github/Gabriel-Darbord/pharo-pcre2/badge.svg?branch=main)](https://coveralls.io/github/Gabriel-Darbord/pharo-pcre2?branch=main)

# Pharo-PCRE2

Perl-compatible regular expressions for Pharo with independently loadable Pharo and FFI backends. The default backend executes entirely in the image and needs nothing installed on the host. The FFI backend binds the [PCRE2](https://github.com/PCRE2Project/pcre2) C library and is faster, at the cost of a native dependency.

## Pharo Version Policy

This project is developed on Pharo 14 and targets Pharo 15.

Supported versions:

- Pharo 14 is the primary development and reference runtime.
- Pharo 15 is supported and verified in CI.
- Pharo 12 and Pharo 13 are supported directly.

## Installation

Load the project into a Pharo image with Metacello:

```smalltalk
Metacello new
  githubUser: 'Gabriel-Darbord' project: 'pharo-pcre2' commitish: 'main' path: 'src';
  baseline: 'PCRE2';
  load
```

That loads the `default` group: the core and the Pharo backend, nothing else. It needs no C library and no FFI.

| group | loads |
| --- | --- |
| `default` | `PCRE2` and `PCRE2-PharoBackend` |
| `Core` | `PCRE2` alone |
| `Pharo` | the Pharo backend |
| `FFI` | the FFI backend |
| `Backends` | both backends |
| `Tools` | the trace and debugger tools |
| `Tests` | every test package |
| `All` | both backends, tools and tests |

The FFI backend requires the native PCRE2 8-bit library on the host. Its UTF-16 and UTF-32 APIs also use `libpcre2-16` and `libpcre2-32` when present.

Linux:

```sh
sudo apt install libpcre2-dev
```

macOS:

```sh
brew install pcre2
```

See [backend selection and current limitations](docs/Backends.md).

## Quick Start

Select an implementation explicitly when compiling:

```smalltalk
matcher := PCRE2Compiler new
  backend: PCRE2CompilerPharoBackend;
  compile: '(?<word>\w+)'.
```

Use `PCRE2CompilerFFIBackend` to select FFI. Changing `PCRE2Compiler defaultBackend:` affects new compilers and the String convenience methods; existing objects retain their selected backend, and `nil` restores the automatic choice. `PCRE2Compiler withDefaultBackend:do:` makes the change for one block and puts back whatever was there.

The Pharo backend is the default: it is the one that always works, since it needs no native library. The automatic choice falls back to FFI when only that backend is loaded. Where the two differ, the FFI backend is the reference — see [backend selection and current limitations](docs/Backends.md).

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
match groupAt: 0.          "size=42"
match groupNamed: 'key'.   "size"
match groupNamed: 'value'. "42"
match matchDataSize.       "match-data bytes the backend holds"
match heapframesSize.      "heap-frame bytes the match data retains"
```

Useful collection-style operations are available on the matcher:

```smalltalk
'\d+' asPerlCompatibleRegex findAll: 'a1 b22 c333'.
'\s*,\s*' asPerlCompatibleRegex substituteAll: 'a, b,c' with: '|'.
'a, b,c' splitOn: '\s*,\s*' asPerlCompatibleRegex.
```

With the `FFI` group loaded, PCRE2 can also convert glob and POSIX patterns into Perl-compatible regular expressions:

```smalltalk
matcher := (LibPCRE2UTF8 convertGlob: '*.st') asPerlCompatibleRegex.
matcher matches: 'Package.st'. "true"
```

## Features

- Full, prefix, search, and match-object APIs.
- Numbered and named capture groups.
- Match enumeration, match ranges, splitting, and substitution.
- Glob and POSIX pattern conversion to PCRE2 syntax for UTF-8, UTF-16, and UTF-32 (FFI backend).
- Prepared UTF-8, UTF-16, and UTF-32 inputs for repeated matching against the same subject.
- UTF-16 and UTF-32 support through `PCRE2UTF16Compiler` and `PCRE2UTF32Compiler`, including byte-backed prepared subjects and patterns with explicit-endian or BOM-aware helpers.
- Compile and match contexts for PCRE2 options and limits.
- Locale-derived low-character tables for compile contexts (FFI backend).
- JIT compilation and optional explicit JIT stack control for advanced cases (FFI backend).
- Partial matching and DFA matching.
- Match, substitution, and substitution case callouts.
- Native match-data memory diagnostics.
- Trace/debugger support in the `PCRE2-Tools` package.

## Lifecycle

FFI compiled patterns are external objects, so `PCRE2SessionManager` restores their backend resources across image restarts. Serialization is used by default when the native library signature is compatible; otherwise matchers are recompiled from their saved pattern and options. Pharo backend patterns and results are ordinary image objects and do not enter C serialization or restoration.

The binding targets PCRE2 10.x. The usual API uses `LibPCRE2UTF8` and the 8-bit library; `LibPCRE2` itself is abstract. `PCRE2UTF16Compiler` and `PCRE2UTF32Compiler` use PCRE2's wider code-unit libraries when available. Minor PCRE2 versions may differ in reported configuration details, so tests and applications should prefer capability checks over exact minor-version strings.

## Documentation

User documentation lives in the `docs` folder and is shown by Pharo's documentation browser when the repository is available:

- `docs/GettingStarted.md`
- `docs/API.md`
- `docs/Lifecycle.md`
- `docs/Backends.md`

For the complete regular expression syntax, see the [official PCRE2 documentation](https://www.pcre.org/current/doc/html/index.html).
