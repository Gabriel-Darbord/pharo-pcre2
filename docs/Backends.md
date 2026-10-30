# Backends

The public compiler, matcher, match, compile-context, and match-context objects contain backend instances. Backend selection and encoded input width are separate choices.

## Loading

Both implementation packages depend on the shared `PCRE2` package. The shared package depends on neither implementation.

| Baseline group | Contents |
| --- | --- |
| `Core` | Shared API and backend contracts |
| `FFI` | Shared API and `PCRE2-FFIBackend` |
| `Pharo` | Shared API and `PCRE2-PharoBackend` |
| `Backends` | Both implementations |
| `Tools` | Shared inspection tools; tracing requires backend callout support |
| `FFITests` | Existing binding and tool tests |
| `PharoTests` | Pharo implementation tests without the FFI backend |
| `BackendTests` | Coexistence and ownership tests requiring both implementations |
| `Default` | FFI and tools |
| `All` | Both implementations, tools, and all tests |

For example, use `load: 'Pharo'` or `load: #( 'FFI' 'Pharo' )` in the Metacello load expression. Only the FFI backend requires a host PCRE2 library.

## Selection

```smalltalk
compiler := PCRE2Compiler new
  backend: PCRE2CompilerPharoBackend.
matcher := compiler compile: '(?<word>\w+)'.
match := matcher findMatch: 'hello'.
match groupNamed: 'word'.
```

The setter accepts a compiler backend class and creates an instance for that compiler. Backend getters answer implementation objects. Width-specific implementation subclasses are internal details.

```smalltalk
PCRE2Compiler defaultBackend: PCRE2CompilerPharoBackend.
'\d+' asPerlCompatibleRegex.
PCRE2Compiler defaultBackend: PCRE2CompilerFFIBackend.
```

A compiler captures its default when created. Changing the default invalidates the cached default compiler but does not modify existing compilers, patterns, contexts, or results. Choose a different compiler backend before creating its context. Compile a new matcher to change an existing pattern's implementation.

FFI is preferred when both implementations are loaded. A Pharo-only installation uses Pharo. Failure to load or use the C library does not trigger a runtime fallback. Switching the project's default to Pharo is deferred until compatibility has been demonstrated; loading the implementation does not promote it automatically.

UTF-8, UTF-16, and UTF-32 compilers share this selection protocol. Raw offsets count the selected encoding's code units. `matchingRangesIn:` answers Pharo character ranges. Contexts and reusable match data must have the correct role, implementation, and width.

## Pharo implementation status

The Pharo backend is experimental and does not yet provide PCRE2 feature parity. It currently supports ordinary matching, captures, named captures, character classes, greedy/lazy/possessive and bounded repetition, backreferences, subroutine calls with optional retained captures, conditional groups, branch-reset groups, lookahead, bounded lookbehind, atomic groups, backtracking control verbs, Perl and UTS#18 extended character classes, scan-substring assertions, inline options, soft/hard partial matching, splitting, enumeration, extended replacements and substitution callbacks. It also supports raw code units, including \C inside UTF-8 and UTF-16 characters, and raw 32-bit values outside Unicode. It supports encoded Unicode strings at all three widths, and subjects that are not valid UTF when the pattern is compiled with `PCRE2_MATCH_INVALID_UTF`.

Unsupported syntax and options signal `PCRE2UnsupportedFeature`, separately from `PCRE2CompileError`. A rejected pattern reports the message and code-unit offset of the PCRE2 error code that names it, taken from the shared error-message catalog rather than from wording of its own, and a match-time error reports its own code's message from the same catalog. The one known gap is locale character tables. Pattern conversion stays on the FFI side on purpose: `LibPCRE2 class>>convertGlob:`, `convertPOSIXBasic:` and `convertPOSIXExtended:` wrap an experimental PCRE2 facility, and there is no backend-neutral entry point to reimplement behind. A public context message the implementation cannot honour reports that it is unsupported rather than failing as a doesNotUnderstand. DFA matching with caller-managed restart workspaces, extended substitutions, substitution callbacks, and non-atomic assertions are implemented. Explicit and automatic callouts are available, including the existing trace tooling. Callout metadata and event streams still need broader differential coverage beyond the existing API tests. Some bounded lookbehind constructs remain unsupported. Native allocation diagnostics and C bytecode/JIT facilities are implementation-specific.

Unicode categories, scripts, script extensions, binary properties, bidi classes, grapheme properties, and simple case folding are pinned to Unicode 17.0.0 using data from the PCRE2 10.49 release. The generator is `scripts/generate-unicode-data.py`, which writes the data as JSON and as the packed literal `PCRE2UnicodeData class>>encoded` carries: the sections as LEB128 varints over code-point gaps, gzipped, in base64. That literal is about 55 kB. `PCRE2PackedProperties` leaves the 489 property range lists packed until a pattern names one, so an image pays for the properties it uses rather than for all of them. The literal is installed through Pharo MCP. The data license is [Unicode License V3](Unicode-LICENSE.txt); the property-name and error-message catalogs use the [PCRE2 license](PCRE2-LICENCE.md). The engine supports script runs and extended grapheme clusters. Full Unicode compatibility still requires wider validation, across the full upstream corpus. ASCII restrictions, scoped ASCII and caseless-restriction options, whole-word and whole-line compilation, control escapes, braced octal escapes, and both alternative BSUX modes, Python octal disambiguation, callout restrictions, and Turkish casing are implemented.

The Pharo matcher uses an explicit alternative stack and capture snapshots. A greedy repetition of a single character is counted off in one step and then given back a character at a time, so a long run costs one choice rather than one per character. A character class, and the set of characters a match may start with, each carry a table of the codes under 256 they accept, built at compile time by asking the predicate itself so that the two cannot disagree; a character above 255 is referred back to the predicate. Match-work and pending-depth limits are enforced. Partial matching reports reaching the end of the subject where PCRE2 does, including from a word boundary and from an end-of-line assertion that held only because the subject ends where it does, and the anchored start optimization applies whether or not partial matching is on. Their counts describe Pharo execution and are not calibrated to C interpreter or JIT counters. Pattern-length, parentheses-depth, variable-lookbehind, and search-offset limits are supported. Heap limits bound explicit Pharo matching-state storage. Match-data and compiled-state diagnostics describe the Pharo representation; they do not reproduce C allocator sizes or pointer-valued diagnostics. Compiled-state size caps use the Pharo representation. DFA workspace capacity bounds queued Pharo states; its accounting differs from C state blocks. Restart requires the same workspace object, as specified by PCRE2, and retains continuation state without retaining prior subject chunks.

## Start optimizations

PCRE2 works out at compile time where a match can begin and then skips the positions that cannot start one. The Pharo backend follows the same decisions, and works them out at the same time, once per compiled pattern rather than once per match: the code unit a match must begin with, the set of units it may begin with, a unit it must contain somewhere, auto-possessification, `PCRE2_FIRSTLINE`, the offset limit, and the two structural ones below. `PCRE2_NO_START_OPTIMIZE` turns them off, and `(*NO_START_OPT)` does the same from inside the pattern.

A pattern every branch of which starts at a fixed place is anchored: `\A`, `\G`, `^` outside multiline mode, or `.*` where the dot matches every character, each of them possibly inside groups, positive lookaheads, conditionals with both branches, or a repetition that has to run at least once. A leading `.*` only counts outside atomic groups and assertions, in a group nothing refers back to, and in a pattern free of `(*PRUNE)` and `(*SKIP)`, any of which could let a later attempt find something the first one missed; `PCRE2_NO_DOTSTAR_ANCHOR` turns that case off on its own. An anchored pattern reports `PCRE2_ANCHORED` among its options, and anchoring survives `PCRE2_NO_START_OPTIMIZE`, which only stops the search for a starting character.

A pattern that is not anchored, has no single code unit to begin with, and every branch of which starts with `^` or with a dot star that stops at line ends is tried only at the start of the subject and just after a line terminator. The position the caller asked to match from is always tried as it stands.

Two differences from the C library are known. The code unit a match must contain is looked for once over the whole subject rather than again from each candidate start, so some start positions PCRE2 abandons are still attempted; the answer is the same, but a callout inside such a pattern fires more often. A conditional group is read for an anchor but not for a line start, which only costs attempts that fail. Note also that the C library's own JIT attempts fewer start positions than its interpreter for a pattern tried only at line starts, so callout counts from a JIT-compiled pattern are not the measure to compare against.

## Written matchers

For a large part of what it compiles the backend writes a Pharo method that matches that pattern and nothing else, and runs it instead of the engine. What follows an item is written inside it, so the Smalltalk stack carries the backtracking: a run of characters is a loop, giving one back is a loop turning once, and a choice is a statement that falls through to the next one, where the engine copies a match state and queues a choice. A repetition with no bound becomes a block that calls itself, which is what gives a turn of it somewhere to be given back from; past a hundred thousand turns it hands the match back to the engine, whose own stack has more room. The method is compiled on first use and is never installed in a class, which the Cog JIT does not mind: it compiles such a method like any other.

What it writes is single characters and classes, sequences, alternation, capture groups, backreferences by number, greedy, lazy and possessive repetition, atomic groups, lookahead, lookbehind of a fixed length, the position assertions `\A`, `\z`, `\Z`, `^`, `$`, `\b` and `\B`, and conditionals on whether a group took part or on a condition already settled when the pattern was read. An item accepting more than two runs of codes reads a lookup table the method carries as a literal rather than comparing them one by one. Everything else is matched by the engine: subroutine calls and recursion, backtracking control verbs, callouts, `\R`, a backreference by name or a caseless one, a lookaround condition, a lookbehind of variable length, a group inside a lookaround or an atomic group, and a repeated group that can match nothing. So are patterns that would grow past what is worth compiling, or want more locals than a method has room for.

The method reads the subject bytes directly, so it refuses any byte of 128 or more and hands the whole match back to the engine when it meets one; a subject that is not plain ASCII is therefore matched exactly as before, only after a wasted start. Every test it writes either refuses such a byte or can only hold where a character begins, which is what keeps it from attempting a start position inside a character that the engine would never attempt. It is not used for a pattern or a context that sets a match, depth or heap limit, because it keeps no count of its work and allocates nothing to bound, nor where a callout, partial matching or any match option it does not know applies. It follows the start optimizations the engine follows: a pattern that can only match in one place is attempted once, and one that can only begin a line passes over the positions inside one.

Of PCRE2's own test corpora, 1,567 of 2,678 distinct patterns are matched this way, and they answer what the engine answers on every case in them.

## Matching malformed UTF

`PCRE2_MATCH_INVALID_UTF` implies `PCRE2_UTF` and reads the subject as fragments of valid UTF separated by invalid sequences. An invalid sequence matches no pattern item, not even a negated class or `\p{Any}`, and no match crosses one; a lookbehind that would reach back over one fails. Each fragment is matched as if it were the whole subject, except that an internal edge is neither the start nor the end of a line, so `^` and `$` do not match there while `\b` and `\B` treat it as a subject edge. `\A`, `\z` and `\Z` keep their meaning over the whole subject. A start offset inside an invalid sequence moves on to the next character. `PCRE2_NO_UTF_CHECK` is ignored, and DFA matching answers `PCRE2_ERROR_DFA_UINVALID_UTF`, as PCRE2 specifies.

A fragment's first attempt is made where the caller asked to match, and every later one is subject to the start optimizations below, as in the C library. A pattern beginning with `.*` therefore answers an empty match at the end of the subject for a start offset that lands inside an invalid sequence, rather than the match the fragment alone would suggest.

## Development validation

Use a pinned upstream C release as an external oracle. Compare pattern, subject, compile and match options, width, capture participation, and raw offsets, and compare a rejected pattern's error message and error offset as well as its rejection. Keep the C corpus and temporary reports outside this project. Add small SUnit regressions for behavior discovered to be missing or incorrect.

Report the scope of each comparison, including unsupported driver syntax, unsupported engine features, execution limits, and actual disagreements. Agreement on a selected sample does not imply complete corpus or feature coverage.
