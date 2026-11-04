# Getting Started

## Install

```smalltalk
Metacello new
  githubUser: 'Gabriel-Darbord' project: 'pharo-pcre2' commitish: 'main' path: 'src';
  baseline: 'PCRE2';
  load
```

That loads the `default` group: the shared API and the Pharo backend, which runs in the image and needs nothing installed on the host. Everything on this page works with it, except the debugger, which needs the `Tools` group.

Pass a group to `load:` to install something else, for instance `load: 'FFI'` or `load: #( 'FFI' 'Pharo' )`.

| group | loads |
| --- | --- |
| `default` | `Core` and `Pharo` |
| `Core` | `PCRE2`, the shared API alone, which has no engine and cannot compile a pattern |
| `PharoMinimal` | the Pharo backend alone, as described below |
| `Pharo` | `PharoMinimal` and the five groups that follow |
| `Substitution` | `substitute:with:` and its variants, with PCRE2's replacement syntax |
| `DFA` | `dfaMatch:` and `dfaMatches:` |
| `Wide` | UTF-16 and UTF-32 compilers, matchers, contexts and inputs |
| `Trace` | `traceMatch:` and the trace it answers |
| `UnicodeProperties` | scripts, script extensions, bidi classes, binary properties, `\X` and script runs |
| `FFI` | the FFI backend, with the shared API of `Substitution`, `DFA`, `Wide` and `Trace` |
| `Backends` | `FFI` and `Pharo` |
| `Tools` | the pattern debugger and its trace tools |
| `FFITests` | the tests of the shared API, run against the FFI backend |
| `PharoTests` | the tests of the Pharo backend |
| `ToolsTests` | the tests of the tools |
| `BackendTests` | the tests that need both backends |
| `Tests` | the four test groups |
| `All` | `Backends`, `Tools` and `Tests` |

### The smallest install

`PharoMinimal` compiles and matches UTF-8 patterns and subjects, with captures, named groups, callouts, partial matching and the Rx-style `String` protocol. Every other feature comes with its group, and the selectors of a feature whose group is not loaded are not understood.

It has no Unicode data of its own either. It reads general categories, case folding and decimal digits from the image, so `\p{L}`, `\w`, `\d`, POSIX classes and caseless matching work, and a pattern that needs the `UnicodeProperties` group fails to compile with `PCRE2UnsupportedFeature`. [Backends.md](Backends.md#unicode-data) says where the data comes from on each Pharo version.

### The FFI backend

The `FFI` group adds the faster backend and the facilities only the C library offers. [Backends.md](Backends.md) says which they are and how a backend is chosen. It needs the native PCRE2 8-bit library on the host:

```sh
sudo apt install libpcre2-dev   # Linux
brew install pcre2              # macOS
```

The UTF-16 and UTF-32 libraries are optional; [Lifecycle.md](Lifecycle.md#native-library) says how the backend binds them. Ask the library for its version from Pharo:

```smalltalk
LibPCRE2UTF8 config: PCRE2 configVersion
```

## Compile a Pattern

The usual entry point is `String>>asPerlCompatibleRegex`.

```smalltalk
matcher := '\b\w+\b' asPerlCompatibleRegex.
```

Use `asPerlCompatibleRegexIgnoringCase` for the common caseless case, or `asPerlCompatibleRegexWithOptions:` when you want to pass PCRE2 compile options. Use `PCRE2Compiler` directly when you need a compile context or want to bypass the default compiler behavior.

## Match a Subject

```smalltalk
matcher matches: 'hello'.        "true: the whole subject matches"
matcher matchesPrefix: 'hello!'. "true: the prefix matches"
matcher search: 'say hello'.     "true: a match exists somewhere"
```

`find:` answers the matched text or `nil`. `findMatch:` answers a `PCRE2Match`, which keeps the result code, offsets, subject bytes, and capture metadata.

```smalltalk
matcher := '(?<key>\w+)=(?<value>\d+)' asPerlCompatibleRegex.
match := matcher findMatch: 'size=42'.
match groupAt: 0.          "size=42"
match groupAt: 1.          "size"
match groupNamed: 'value'. "42"
```

## Enumerate Matches

```smalltalk
'\d+' asPerlCompatibleRegex findAll: 'a1 b22 c333'.

'\d+' asPerlCompatibleRegex
  matchesIn: 'a1 b22 c333'
  do: [ :each | Transcript show: each; cr ].
```

For character ranges, use `matchingRangesIn:`.

## Split and Substitute

```smalltalk
'a, b,c' splitOn: '\s*,\s*' asPerlCompatibleRegex.

'\d+' asPerlCompatibleRegex
  substituteAll: 'a1 b22 c333'
  with: '#'.
```

[API.md](API.md#splitting-and-substitution) covers the replacement syntax, literal replacements and substitution callouts.

## Reuse Prepared Input

Strings are prepared as UTF-8 bytes each time they are matched. If you match the same subject repeatedly, prepare it once:

```smalltalk
input := 'cafe deja' asPCRE2UTF8Input.
matcher := '\w+' asPerlCompatibleRegex.
matcher findAll: input.
matcher matchingRangesIn: input.
```

ASCII strings can be reused directly as byte storage. Non-ASCII strings are encoded once, and the input keeps what it needs to translate byte offsets back to Pharo character indexes.

## Use UTF-16 or UTF-32 Matching

The `Wide` group adds `PCRE2UTF16Compiler` and `PCRE2UTF32Compiler`, which compile and match at the wider code-unit widths:

```smalltalk
matcher := PCRE2UTF16Compiler new compile: '\p{L}+'.
matcher findAll: 'café déjà'.
```

A subject already stored as UTF-16 or UTF-32 bytes can be prepared directly:

```smalltalk
input := bytesFromFile asPCRE2UTF16InputDetectingBOM.
matcher findAll: input.
```

[API.md](API.md#utf-16-and-utf-32) lists the byte-order variants, prepared patterns, and what the wide matchers support.

## Debug a Pattern

With the `Tools` group loaded, the debugger records an instrumented match and walks it step by step. It records through callouts, so it shows what the backend in use does rather than simulating a matcher of its own, and it runs on either backend.

```smalltalk
PCRE2DebuggerPresenter open.                            "nothing in it yet"
'\d+' openPerlCompatibleRegexDebugger.                  "a pattern, no subject"
'\d+' openPerlCompatibleRegexDebuggerOn: 'a1 b22'.      "both"
'\d+' asPerlCompatibleRegex openDebuggerOn: 'a1 b22'.   "from a compiled matcher"
```

Pattern and subject stay editable in the window. *Trace all* records a whole match at once; *Step* and *Continue* run the same instrumented matcher under your control.
