# Changelog

## 2.0.0 — unreleased

Pharo-pcre2 gains a second implementation: a regular-expression engine written in Pharo. It needs no C library, it is what a plain install now uses, and it sits behind the same public API as the existing binding. The C binding is unchanged in behaviour and is still there for the facilities only it can offer.

### Breaking

- **A plain `load` installs less than it did.** The baseline used to declare a group named `Default`, which Metacello never looked for, so a load with no group installed every package, tests included. The group is now `default` and holds the shared API and the Pharo backend. An image that wants the C binding must ask for it: `load: 'FFI'`, or `load: 'All'` for everything.
- **The FFI classes moved to their own package.** `LibPCRE2`, `LibPCRE2UTF8/16/32`, `PCRE2Object`, `PCRE2Types`, `PCRE2JITStack`, `PCRE2CharacterTables`, `PCRE2ConvertContext`, `PCRE2SessionManager` and their width subclasses — 19 classes in all — left `PCRE2` for `PCRE2-FFIBackend`. Code that names the classes is unaffected; anything that depends on the package layout is not.
- **`asPerlCompatibleRegex` compiles with the Pharo engine by default.** Where the two implementations differ, the C library remains the reference. `PCRE2Compiler defaultBackend: PCRE2CompilerFFIBackend` pins the old behaviour for an image, and `PCRE2Compiler new backend: PCRE2CompilerFFIBackend` for one compiler.
- **`.smalltalk.ston` is the Pharo-only CI spec.** It is what smalltalkCI runs when no file is named, so it matches the default install. The full run moved to `.smalltalk-lib.ston`, and `.smalltalk-ffi.ston` covers an FFI-only image.

### Added

- **A Pharo matching engine** (`PCRE2-PharoBackend`), covering ordinary matching, captures and named captures, character classes, greedy, lazy and possessive repetition, backreferences, subroutine calls, conditional and branch-reset groups, lookaround, atomic groups, backtracking control verbs, Perl and UTS#18 extended classes, scan-substring assertions, inline options, partial matching, DFA matching with caller-managed restart workspaces, extended substitution and substitution callbacks, callouts, script runs and grapheme clusters. Unicode categories, scripts, properties, bidi classes and simple case folding are pinned to Unicode 17.0.0 from the PCRE2 10.49 release.
- **Written matchers.** For a pattern it can, the Pharo backend writes a Pharo method that matches that pattern and runs it instead of the engine, so the Smalltalk stack carries the backtracking. 1,567 of the 2,678 distinct patterns in PCRE2's own test corpora are matched this way.
- **The whole `RxMatcher` protocol**, streams included, so a matcher is a drop-in for Pharo's `Regex-Core`.
- **Code-unit widths on either backend.** UTF-8, UTF-16 and UTF-32 compilers, raw code units, `\C` inside UTF-8 and UTF-16 characters, raw 32-bit values outside Unicode, and subjects that are not valid UTF under `PCRE2_MATCH_INVALID_UTF`.
- `PCRE2Compiler class>>withDefaultBackend:do:` scopes a backend change to a block, and `defaultBackend: nil` restores the automatic choice.
- `PCRE2Compiler class>>supportsCodeUnitWidth:` answers whether the backend in use can match at a given width, so callers no longer have to ask `LibPCRE2` and thereby assume the C binding.
- `PCRE2UnsupportedFeature`, raised for syntax and options an implementation does not provide, separately from `PCRE2CompileError`.
- The pattern debugger opens without being given anything: `PCRE2DebuggerPresenter open`, `openOnPattern:`, `openOnSubject:` and `openOnPattern:subject:`, which now answers the debugger rather than its window so a caller can go on driving it. `onPattern:subject:` builds one without opening a window.
- Baseline groups `Pharo`, `Backends`, `PharoTests`, `ToolsTests` and `BackendTests`, beside the existing `Core`, `FFI`, `Tools`, `FFITests`, `Tests` and `All`.
- CI runs three installs — default, FFI-only, and everything with the C library — across Pharo 12, 13, 14 and 15.

### Changed

- The debugger and trace tools (`PCRE2-Tools`) run on either backend, and their tests now run once per loaded implementation: `PCRE2DebugSessionPharoBackendTest` in a default install, and `PCRE2DebugSessionFFIBackendTest` beside it when the C binding is there. Neither the tools nor their tests need the FFI backend to load any more.
- The Pharo backend accepts every option PCRE2 defines for `pcre2_substitute`; `PCRE2_COPY_MATCHED_SUBJECT` and `PCRE2_DISABLE_RECURSELOOP_CHECK` used to be refused. An option bit PCRE2 does not define is still refused, and now says so rather than claiming the option is unimplemented.
- `PCRE2TraceRecorder` keeps one trace snapshot until an event changes it, instead of rebuilding the whole trace for every question a presenter asks.
- The debugger window is titled and carries an icon, rather than opening as "Unnamed Window". Its buttons are enabled only when they can do something: pausing and aborting need a run in flight, and the four trace-navigation buttons need a trace.
- The debugger's control rows no longer crop their buttons' labels, and the trace pane no longer overflows the window: "Trace all", "Step", "Continue", "Pause" and "Abort" were drawn blank, and the traced pattern and its context were laid out partly outside the pane that holds them.
- The public `PCRE2Matcher` and `PCRE2Match` no longer declare the ten width-dispatch methods that only the FFI backend implements; they live on `PCRE2MatcherFFIBackend` and `PCRE2MatchFFIBackend`.
- `README.md` advertises the library; installation and usage moved to `docs/GettingStarted.md`.

### Fixed

- The `Default` baseline group never matched, so `load` installed test packages into production images.
- `PCRE2PatternParser>>unsupported:` and the ten width-dispatch `subclassResponsibility` methods on `PCRE2Matcher` and `PCRE2Match` were unreachable. They advertised, on public classes, a protocol no subclass was ever going to implement.
