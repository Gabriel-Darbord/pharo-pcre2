# Changelog

## Unreleased

### Changed

- **The Pharo backend reads general categories, case folding and decimal digits from Pharo's own `Unicode` class.** Pharo 15 carries them at Unicode 18.0, so a character added since Unicode 17.0 now has its category there. Pharo 14 and older carry them at Unicode 9.0, so on those versions the baseline also loads `PCRE2-UnicodeCompat`, which brings them at Unicode 17.0.0 as before.
- **Scripts, script extensions, bidi classes, binary properties, grapheme breaks and script runs moved to `PCRE2-UnicodeProperties`.** The `Pharo` and `default` groups load it, so they install what they did. `PCRE2UnicodeData` keeps the questions the backend asks and no longer carries the packed data: `PCRE2UnicodeProperties` and `PCRE2PackedUnicodeTables` do, and `data`, `rangesFor:`, `matches:code:` and `version` went with it.
- **Substitution, DFA matching, UTF-16 and UTF-32, and tracing moved out of `PCRE2` and `PCRE2-PharoBackend`**, each to a package of its own: `PCRE2-Substitution`, `PCRE2-DFA`, `PCRE2-Wide` and `PCRE2-Trace` hold the shared API, and `PCRE2-PharoBackend-Substitution` and `PCRE2-PharoBackend-DFA` the Pharo implementation of the first two. The `Pharo`, `default` and `FFI` groups load them, so they install what they did; `Core` is `PCRE2` alone and lost the API of all four. `PCRE2-Tools` now requires `PCRE2-Trace`.
- **The compile and match context classes of a code-unit width come from its compiler and matcher.** `PCRE2Compiler>>compileContextClass` is answered by `PCRE2UTF8Compiler` and its wide counterparts instead of being asked of the backend, and `PCRE2Matcher>>matchContextClass` is new.

### Added

- **A `PharoMinimal` group**: the shared API and the Pharo backend with no Unicode data of its own, and without substitution, DFA matching, UTF-16 and UTF-32, or tracing. A pattern that needs one of the properties of `PCRE2-UnicodeProperties`, `\X` or a script run fails to compile with `PCRE2UnsupportedFeature`. A `UnicodeProperties` group adds them back, and `Substitution`, `DFA`, `Wide` and `Trace` groups add the other features.
- `scripts/generate-unicode-data.py` writes the two literals with `--packed-properties` and `--packed-tables`, in place of `--packed`.

## 2.0.0 — 2026-11-01

Pharo-pcre2 gains a second implementation: a regular-expression engine written in Pharo. It needs no C library, it is what a plain install now uses, and it sits behind the same public API as the existing binding. The C binding is unchanged in behaviour and is still there for the facilities only it can offer.

### Breaking

- **A plain `load` installs less than it did.** The baseline used to declare a group named `Default`, which Metacello never looked for, so a load with no group installed every package, tests included. The group is now `default` and holds the shared API and the Pharo backend. An image that wants the C binding must ask for it: `load: 'FFI'`, or `load: 'All'` for everything.
- **The FFI classes moved to their own package.** `LibPCRE2`, `LibPCRE2UTF8/16/32`, `PCRE2Object`, `PCRE2Types`, `PCRE2JITStack`, `PCRE2CharacterTables`, `PCRE2ConvertContext`, `PCRE2SessionManager` and their width subclasses — 19 classes in all — left `PCRE2` for `PCRE2-FFIBackend`. Code that names the classes is unaffected; anything that depends on the package layout is not.
- **`load: 'Core'` no longer installs an engine.** The group is spelled as it was and holds the same package, but `PCRE2` is the shared API alone now that the implementations have moved out of it. An image that asks for `Core` and nothing else raises `PCRE2Error: No PCRE2 backend is loaded` the first time it compiles a pattern. A project that pinned `loads: #( 'Core' )` against 1.0.1 was asking for the C binding and getting it; it wants `#( 'Core' 'FFI' )` to go on getting it, or `#( 'Core' 'Pharo' )` to stop needing the host library. Anything that names `LibPCRE2` or its kin needs the `FFI` group whichever engine it matches with.
- **`asPerlCompatibleRegex` compiles with the Pharo engine by default.** Where the two implementations differ, the C library remains the reference. `PCRE2Compiler defaultBackend: PCRE2CompilerFFIBackend` pins the old behaviour for an image, and `PCRE2Compiler new backend: PCRE2CompilerFFIBackend` for one compiler.
- **`.smalltalk.ston` is the Pharo-only CI spec.** It is what smalltalkCI runs when no file is named, so it matches the default install. The full run moved to `.smalltalk-lib.ston`, and `.smalltalk-ffi.ston` covers an FFI-only image.

Nothing else in the public protocol was taken away: every selector 1.0.1 published on `PCRE2Matcher`, `PCRE2Match`, `PCRE2Compiler`, the two contexts, `PCRE2MatchTrace`, the callout objects and the `String` extensions is still understood. What moved out of the public classes is the FFI plumbing behind them — `free`, `ffiLibraryName`, `privateCopy`, the `setXxx:` library calls and the raw `match:from:to:options:matchData:` family — which now lives on the backend classes. Code that called those directly has to go through `backend`.

### Added

- **A Pharo matching engine** (`PCRE2-PharoBackend`), covering ordinary matching, captures and named captures, character classes, greedy, lazy and possessive repetition, backreferences, subroutine calls, conditional and branch-reset groups, lookaround, atomic groups, backtracking control verbs, Perl and UTS#18 extended classes, scan-substring assertions, inline options, partial matching, DFA matching with caller-managed restart workspaces, extended substitution and substitution callbacks, callouts, script runs and grapheme clusters. Unicode categories, scripts, properties, bidi classes and simple case folding are pinned to Unicode 17.0.0 from the PCRE2 10.49 release.
- **Written matchers.** For a pattern it can, the Pharo backend writes a Pharo method that matches that pattern and runs it instead of the engine, so the Smalltalk stack carries the backtracking. 1,567 of the 2,678 distinct patterns in PCRE2's own test corpora are matched this way.
- **The whole `RxMatcher` protocol**, so a matcher is a drop-in for Pharo's `Regex-Core`. The stream messages are compatibility shims: they read what is left of a positionable stream and match that, rather than matching as it arrives.
- **Code-unit widths on either backend.** UTF-8, UTF-16 and UTF-32 compilers, raw code units, `\C` inside UTF-8 and UTF-16 characters, raw 32-bit values outside Unicode, and subjects that are not valid UTF under `PCRE2_MATCH_INVALID_UTF`.
- **`backend` on the public objects.** A compiler, matcher, match or context answers the implementation it runs on, and `PCRE2Compiler new backend: aBackendClass` picks one for a single compiler. `PCRE2CompilerBackend` is the contract a backend answers, so a third implementation has something to subclass.
- `PCRE2Context`, the shared superclass of the compile and match contexts, so context behaviour common to both has one home.
- `PCRE2Compiler class>>withDefaultBackend:do:` scopes a backend change to a block, and `defaultBackend: nil` restores the automatic choice.
- `PCRE2Compiler class>>supportsCodeUnitWidth:` answers whether the backend in use can match at a given width, so callers no longer have to ask `LibPCRE2` and thereby assume the C binding.
- `PCRE2UnsupportedFeature`, raised for syntax and options an implementation does not provide, separately from `PCRE2CompileError`.
- Six option constants PCRE2 10.49 defines and 1.0.1 did not name: `altExtendedClass`, `errorDFAInvalidUTF`, `extraNeverCallout`, `extraNoBs0`, `extraPythonOctal` and `extraTurkishCasing`.
- The pattern debugger opens without being given anything: `PCRE2DebuggerPresenter open`, `openOnPattern:`, `openOnSubject:` and `openOnPattern:subject:`, which now answers the debugger rather than its window so a caller can go on driving it. `onPattern:subject:` builds one without opening a window. `String>>openPerlCompatibleRegexDebugger` and `PCRE2Matcher>>openDebugger` open it on a pattern alone, beside the existing `...On:` variants that take a subject.
- Baseline groups `Pharo`, `Backends`, `PharoTests`, `ToolsTests` and `BackendTests`, beside the existing `Core`, `FFI`, `Tools`, `FFITests`, `Tests` and `All`.
- CI runs three installs — default, FFI-only, and everything with the C library — across Pharo 12, 13, 14 and 15.

### Changed

- The debugger and trace tools (`PCRE2-Tools`) run on either backend, and their tests now run once per loaded implementation: `PCRE2DebugSessionPharoBackendTest` in a default install, and `PCRE2DebugSessionFFIBackendTest` beside it when the C binding is there. Neither the tools nor their tests need the FFI backend to load any more.
- The Pharo backend accepts every option PCRE2 defines for `pcre2_substitute`; `PCRE2_COPY_MATCHED_SUBJECT` and `PCRE2_DISABLE_RECURSELOOP_CHECK` used to be refused. An option bit PCRE2 does not define is still refused, and now says so rather than claiming the option is unimplemented.
- `PCRE2TraceRecorder` keeps one trace snapshot until an event changes it, instead of rebuilding the whole trace for every question a presenter asks.
- The debugger window is titled and carries an icon, rather than opening as "Unnamed Window". Its buttons are enabled only when they can do something: pausing and aborting need a run in flight, and the four trace-navigation buttons need a trace.
- The debugger's control rows no longer crop their buttons' labels, and the trace pane fills its window: "Trace all", "Step", "Continue", "Pause" and "Abort" were drawn blank, the traced pattern and its context were laid out partly outside the pane that holds them, and the top right of the window was left empty. The trace timeline's pattern column now takes the width the other four leave, instead of every column being pinned and the last one cut off. The trace pane's two rows split their columns at the same place, so the four panes read as a grid.
- **`PCRE2-Tests` runs against the C binding whatever the image default is.** The package tests `PCRE2-FFIBackend`, but nothing pinned the backend, so in a build that also loads the Pharo engine — `load: 'All'`, and the CI job that goes with it — those tests ran against that engine instead, and the binding was left to the FFI-only job alone. `PCRE2FFITestCase` pins them.
- The public `PCRE2Matcher` and `PCRE2Match` no longer declare the ten width-dispatch methods that only the FFI backend implements; they live on `PCRE2MatcherFFIBackend` and `PCRE2MatchFFIBackend`.
- `README.md` advertises the library; installation and usage moved to `docs/GettingStarted.md`, and `docs/Backends.md` is new: how a backend is chosen, what the Pharo one will not do because that is what the C binding is for, and what is left to validate.

### Licensing

The project stays MIT. It now ships two pieces of third-party data with licences of their own, both in `docs/`: the Unicode 17.0.0 tables the Pharo backend matches `\p{...}` against, under the [Unicode License V3](docs/Unicode-LICENSE.txt), and PCRE2's property-name and error-message catalogues, under the [PCRE2 licence](docs/PCRE2-LICENCE.md). `scripts/generate-unicode-data.py` is the generator that produces the tables, so what is in the image can be checked against the release it came from.

### Fixed

- The `Default` baseline group never matched, so `load` installed test packages into production images.
- `PCRE2PatternParser>>unsupported:` and the ten width-dispatch `subclassResponsibility` methods on `PCRE2Matcher` and `PCRE2Match` were unreachable. They advertised, on public classes, a protocol no subclass was ever going to implement.
- **`PCRE2Match>>mark` read freed memory on the C backend.** `pcre2_match` stores the MARK name as a pointer into the compiled pattern, and a match keeps no reference to its matcher, so once the pattern went the pointer dangled: reading the name walked freed memory until it met a zero, which is a wrong answer when the block has been reused and a crash when the page has gone. Shutdown made it near-certain, because it asks every match in the image for its mark. The name is now taken when the attempt is recorded, while the pattern is certainly there. This one dates back to 1.0.1.
- **`free` left the handle pointing at freed memory.** `PCRE2Matcher>>free`, `PCRE2Match>>free` and `PCRE2Context>>free` are public, and they handed the object back to the library without nulling the handle, so `isNull` went on answering false afterwards. Every guard that asks `isNull` before touching an external object was therefore waved past a dangling pointer, and a second `free` was a double free. `free` now nulls the handle and does nothing when it is already null; `basicFree` is the call to the library. This one dates back to 1.0.1 as well.
