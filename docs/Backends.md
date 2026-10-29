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

The Pharo backend is experimental and does not yet provide PCRE2 feature parity. It currently supports ordinary matching, captures, named captures, character classes, greedy/lazy/possessive and bounded repetition, backreferences, subroutine calls, lookahead, bounded lookbehind, atomic groups, inline options, splitting, enumeration, and basic replacement expansion. It supports encoded Unicode strings at all three widths.

Unsupported syntax and options signal `PCRE2UnsupportedFeature`, separately from `PCRE2CompileError`. Known gaps include conditionals, branch-reset groups, extended character classes, backtracking control verbs, callouts and trace tooling, partial and DFA matching, pattern conversion, extended substitution, and non-LF newline modes. Some bounded lookbehind constructs remain unsupported. Native allocation diagnostics and C bytecode/JIT facilities are implementation-specific.

Unicode classification and casing currently use Pharo's character data. They are not yet pinned to PCRE2's complete Unicode property and case-equivalence tables. Passing the existing Unicode examples does not establish full Unicode compatibility.

The Pharo matcher uses an explicit alternative stack and capture snapshots. Match-work and pending-depth limits are enforced. Their counts describe Pharo execution and are not calibrated to C interpreter or JIT counters. Pattern-length, parentheses-depth, variable-lookbehind, and search-offset limits are supported. Explicit heap byte limits are not yet implemented and raise an unsupported-feature error.

## Development validation

Use a pinned upstream C release as an external oracle. Compare pattern, subject, compile and match options, width, capture participation, and raw offsets. Keep the C corpus and temporary reports outside this project. Add small SUnit regressions for behavior discovered to be missing or incorrect.

Report the scope of each comparison, including unsupported driver syntax, unsupported engine features, execution limits, and actual disagreements. Agreement on a selected sample does not imply complete corpus or feature coverage.
