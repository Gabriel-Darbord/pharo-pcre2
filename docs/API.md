# API Overview

## Creating Matchers

```smalltalk
'pattern' asPerlCompatibleRegex.
'pattern' asPerlCompatibleRegexIgnoringCase.
'pattern' asPerlCompatibleRegexWithOptions: PCRE2 caseless | PCRE2 multiline.
```

Use `PCRE2Compiler` when you need JIT settings or compile-context knobs.

```smalltalk
compiler := PCRE2Compiler new.
compiler addOptions: PCRE2 multiline.
compiler context newline: PCRE2 newlineAnyCRLF.
matcher := compiler compile: '^value'.
```

Use `PCRE2UTF16Compiler` or `PCRE2UTF32Compiler` when you want to compile and match through PCRE2's wider code-unit APIs.

```smalltalk
matcher := PCRE2UTF16Compiler new compile: '\p{L}+'.
matcher find: 'café'.

matcher := PCRE2UTF32Compiler new compile: '\p{L}+'.
matcher find: 'café'.
```

The wide compilers also accept prepared pattern input:

```smalltalk
pattern := patternBytes asPCRE2UTF16LittleEndianInput.
matcher := PCRE2UTF16Compiler new compile: pattern.

pattern := patternBytesWithBOM asPCRE2UTF16InputDetectingBOM.
matcher := PCRE2UTF16Compiler new compile: pattern.
```

## Matching

- `matches:` checks that the whole subject matches.
- `matchesPrefix:` checks that a prefix matches.
- `search:` checks whether a match exists anywhere.
- `find:` answers the matched text or `nil`.
- `findMatch:` answers a `PCRE2Match` or `nil`.
- `findAll:` answers all matched texts.
- `matchesIn:do:` and `matchesIn:collect:` enumerate matched texts.
- `matchingRangesIn:` answers 1-based Pharo character ranges.

`PCRE2Match` keeps enough data to query captures after matching:

```smalltalk
match groupAt: 0.
match groupNamed: 'name'.
match groupsByName.
match offsetsAt: 1.
match mark.
match isComplete.
match isPartial.
```

UTF-16 and UTF-32 matchers support the same core matching, capture, mark, and static callout-site queries. Substitution, DFA matching, runtime callouts, tracing, and compile/match contexts are currently exposed by the UTF-8 API.

Wide matchers also accept prepared byte input:

```smalltalk
bytes asPCRE2UTF16Input.              "native-endian UTF-16"
bytes asPCRE2UTF16LittleEndianInput.
bytes asPCRE2UTF16BigEndianInput.
bytes asPCRE2UTF16InputDetectingBOM.  "strip a BOM when present"
bytes asPCRE2UTF16InputWithBOM.       "require a BOM"

bytes asPCRE2UTF32Input.              "native-endian UTF-32"
bytes asPCRE2UTF32LittleEndianInput.
bytes asPCRE2UTF32BigEndianInput.
bytes asPCRE2UTF32InputDetectingBOM.  "strip a BOM when present"
bytes asPCRE2UTF32InputWithBOM.       "require a BOM"
```

## Splitting and Substitution

A matcher can split by reporting the ranges that should be kept:

```smalltalk
subject := 'a,b;c'.
parts := OrderedCollection new.
'[,;]+' asPerlCompatibleRegex
  split: subject
  indicesDo: [ :start :end |
    parts add: (subject copyFrom: start to: end) ].
```

Pharo's `splitOn:` also works with a PCRE2 matcher:

```smalltalk
'a,b;c' splitOn: '[,;]+' asPerlCompatibleRegex.
```

Substitution follows PCRE2 replacement rules by default:

```smalltalk
'(\w+)=(\d+)' asPerlCompatibleRegex
  substituteAll: 'x=1 y=2'
  with: '$1: $2'.
```

Use `withLiteral:` when the replacement text should not be parsed as a substitution expression. `substituteUsingMatch:with:` can reuse an already computed `PCRE2Match` for the first replacement.

## Pattern Conversion

PCRE2 can convert glob, POSIX basic, and POSIX extended patterns into PCRE2 pattern strings:

```smalltalk
PCRE2 convertGlob: '*.st'.
PCRE2 convertPOSIXBasic: 'a\{2\}'.
PCRE2 convertPOSIXExtended: 'a(b|c)+'.
```

The result is a regular pattern string, so compile it with the usual API:

```smalltalk
matcher := (PCRE2 convertGlob: '*.st') asPerlCompatibleRegex.
matcher matches: 'Package.st'.
```

Use `LibPCRE2 newConvertContext` when glob conversion needs a different escape character or separator:

```smalltalk
context := LibPCRE2 newConvertContext.
context globEscape: $!.
matcher := (PCRE2 convertGlob: 'file!*.st' context: context) asPerlCompatibleRegex.
```

## Partial and DFA Matching

Partial matching is useful when a subject may be incomplete, such as while reading a buffer.

```smalltalk
matcher findSoftPartialMatch: subject.
matcher findHardPartialMatch: subject.
```

DFA matching exposes PCRE2's alternative-matching mode. It can return several alternatives for the same start position, for example `caterpillar`, `cater`, and `cat` when the pattern allows all three.

```smalltalk
matcher dfaMatch: subject.
matcher dfaMatches: subject workspaceSize: 100.
```

## Callouts

PCRE2 callouts let a block observe or influence matching. Explicit callouts come from the pattern; automatic callouts can be added temporarily for tracing and debugging.

```smalltalk
events := OrderedCollection new.
'(?C1)\w+' asPerlCompatibleRegex
  find: 'word'
  calloutsDo: [ :event |
    events add: event.
    0 ].
```

The block receives a `PCRE2CalloutEvent`. Answer an integer PCRE2 return code to control matching, or answer anything else to continue.

Substitution callouts are available on substitution variants ending in `calloutsDo:`. The block receives a `PCRE2SubstitutionCalloutEvent`.

## Tracing and Debugging

The core package can build a trace object:

```smalltalk
trace := matcher traceMatch: subject.
trace steps.
trace match.
```

Loading `PCRE2-Tools` adds a debugger presenter:

```smalltalk
'pattern' openPerlCompatibleRegexDebuggerOn: 'subject'.
matcher openDebuggerOn: 'subject'.
```

The debugger can trace a whole match or step through a live run. It uses PCRE2 callouts, so it shows what PCRE2 reports rather than simulating a separate regex engine.
