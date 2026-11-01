# Getting Started

## Install

```smalltalk
Metacello new
  githubUser: 'Gabriel-Darbord' project: 'pharo-pcre2' commitish: 'main' path: 'src';
  baseline: 'PCRE2';
  load
```

That loads the `default` group: the shared API and the Pharo backend, which runs in the image and needs nothing installed on the host. Everything on this page works with it.

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

Pass a group to `load:`, for instance `load: 'FFI'` or `load: #( 'FFI' 'Pharo' )`.

### The FFI backend

The `FFI` group adds the faster backend, the glob and POSIX pattern conversions, JIT, locale character tables and C serialization. It needs the native PCRE2 8-bit library on the host:

```sh
sudo apt install libpcre2-dev   # Linux
brew install pcre2              # macOS
```

Its UTF-16 and UTF-32 APIs also use `libpcre2-16` and `libpcre2-32` when present. Ask the library for its version from Pharo:

```smalltalk
LibPCRE2UTF8 config: PCRE2 configVersion
```

[Backends.md](Backends.md) explains how a backend is chosen and what the Pharo one does not do yet.

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
match matchDataSize.       "match-data bytes the backend holds"
match heapframesSize.      "heap-frame bytes the match data retains"
```

## Enumerate Matches

```smalltalk
'\d+' asPerlCompatibleRegex findAll: 'a1 b22 c333'.

'\d+' asPerlCompatibleRegex
  matchesIn: 'a1 b22 c333'
  do: [ :each | Transcript show: each; cr ].
```

For character ranges, use `matchingRangesIn:`. Ranges are translated back from PCRE2 UTF-8 offsets to Pharo character indexes.

## Split and Substitute

```smalltalk
'a, b,c' splitOn: '\s*,\s*' asPerlCompatibleRegex.

'\d+' asPerlCompatibleRegex
  substituteAll: 'a1 b22 c333'
  with: '#'.
```

Replacement strings use PCRE2 substitution syntax unless you call one of the `withLiteral:` variants.

## Debug a Pattern

With the `Tools` group loaded, the debugger records an instrumented match and walks it step by step. It runs on either backend.

```smalltalk
PCRE2DebuggerPresenter open.                            "nothing in it yet"
'\d+' openPerlCompatibleRegexDebugger.                  "a pattern, no subject"
'\d+' openPerlCompatibleRegexDebuggerOn: 'a1 b22'.      "both"
'\d+' asPerlCompatibleRegex openDebuggerOn: 'a1 b22'.   "from a compiled matcher"
```

Pattern and subject stay editable in the window. *Trace all* records a whole match at once; *Step* and *Continue* run the same instrumented matcher under your control.

## Convert Other Pattern Styles

With the `FFI` group loaded, use PCRE2's conversion helpers when the input pattern is a glob or POSIX regular expression:

```smalltalk
matcher := (LibPCRE2UTF8 convertGlob: '*.st') asPerlCompatibleRegex.
matcher matches: 'Package.st'. "true"

(LibPCRE2UTF8 convertPOSIXBasic: 'a\{2\}') asPerlCompatibleRegex.
(LibPCRE2UTF8 convertPOSIXExtended: 'a(b|c)+') asPerlCompatibleRegex.
```

## Reuse Prepared Input

The default API matches UTF-8 bytes. If you match the same subject repeatedly, prepare it once:

```smalltalk
input := 'cafe deja' asPCRE2UTF8Input.
matcher := '\w+' asPerlCompatibleRegex.
matcher findAll: input.
matcher matchingRangesIn: input.
```

ASCII strings can be reused directly as byte storage. Non-ASCII strings are encoded once and keep the decoder needed for character ranges.

## Use UTF-16 or UTF-32 Matching

The default API uses PCRE2's 8-bit library and prepares strings as UTF-8. If the host PCRE2 build includes wider code-unit support, the UTF-16 and UTF-32 compilers can compile and match through `libpcre2-16` and `libpcre2-32`:

```smalltalk
matcher := PCRE2UTF16Compiler new compile: '\p{L}+'.
matcher findAll: 'café déjà'.

matcher := PCRE2UTF32Compiler new compile: '\p{L}+'.
matcher findAll: 'café déjà'.
```

If the subject is already stored as UTF-16 or UTF-32 bytes, prepare the bytes directly. Native-endian bytes can use `asPCRE2UTF16Input` or `asPCRE2UTF32Input`; file bytes with known byte order can use the explicit endian variants. If the file starts with a BOM, use the detecting helpers.

```smalltalk
input := bytesFromFile asPCRE2UTF16InputDetectingBOM.
matcher := PCRE2UTF16Compiler new compile: '\p{L}+'.
matcher findAll: input.
```

The pattern can also come from prepared bytes as long as it uses the same code-unit width as the compiler:

```smalltalk
pattern := patternBytesFromFile asPCRE2UTF16InputDetectingBOM.
matcher := PCRE2UTF16Compiler new compile: pattern.
```

UTF-16 and UTF-32 matching support the same high-level surfaces as the default UTF-8 API, including substitution, DFA matching, runtime callouts, tracing, debugger support, and compile/match contexts. Prepared wide inputs translate native code-unit offsets back to Pharo character ranges.
