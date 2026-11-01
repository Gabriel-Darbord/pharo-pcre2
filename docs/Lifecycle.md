# Lifecycle and Native Library

## Native Library

The FFI backend uses `LibPCRE2UTF8` for the default PCRE2 8-bit API. It requires a compatible PCRE2 10.x library, checks its major version before compilation, and uses configuration queries for features such as JIT and Unicode support. The Pharo backend requires no C library.

Minor PCRE2 versions may report different configuration strings or Unicode versions. Prefer checking capabilities over comparing exact minor-version text.

The optional UTF-16 and UTF-32 matchers bind through `LibPCRE2UTF16` and `LibPCRE2UTF32` to PCRE2's separate `libpcre2-16` and `libpcre2-32` libraries. Runtime calls go through `LibPCRE2UTF8`, `LibPCRE2UTF16`, or `LibPCRE2UTF32`. Check `LibPCRE2UTF8 supports16BitCodeUnitWidth` or `LibPCRE2UTF8 supports32BitCodeUnitWidth` before depending on wider libraries in portable code.

## Compiled Patterns and Image Restarts

An FFI backend compiled pattern is a native object outside Pharo object memory. `PCRE2SessionManager` keeps those matchers usable across image restarts. Pharo backend compiled state consists of ordinary image objects and is excluded from C resource restoration.

The default mode is serialization:

1. Before an image save or shutdown, the manager serializes compiled matchers as a batch.
2. Matchers are grouped by PCRE2 code-unit width, because the 8-bit, 16-bit, and 32-bit libraries deserialize their own compiled patterns.
3. At startup, it compares the saved native-library signature with the current one.
4. If the signature matches, it deserializes the native code.
5. If deserialization is unsafe or unavailable, it recompiles from the saved pattern and options.

Saving without quitting caches match results without releasing their live match data. Reopening that snapshot keeps cached captures and metadata readable; reusable C match-data buffers must be allocated again in the new session. Quitting releases C match data after caching results.

Serialized PCRE2 bytecode is a cache, not a portable interchange format. It depends on the PCRE2 version, compiled code-unit widths, endianness, word size, `size_t` size, and Unicode support. JIT machine code is not serialized; requested JIT compilation is rebuilt after restore when available.

Use recompilation mode when portability matters more than startup speed:

```smalltalk
PCRE2SessionManager useRecompilation.
```

Use serialization mode when the image is expected to restart on a compatible host:

```smalltalk
PCRE2SessionManager useSerialization.
```

The manager can also be disabled for experiments or short-lived images:

```smalltalk
PCRE2SessionManager disable.
PCRE2SessionManager enable.
```

## Prepared Inputs

PCRE2 operates on UTF-8 bytes. Normal Pharo strings are accepted by the public APIs and prepared automatically. For repeated matching against the same subject, pass a `PCRE2UTF8Input` to avoid preparing the subject each time.

```smalltalk
input := subject asPCRE2UTF8Input.
matcher findAll: input.
matcher substituteAll: input with: replacement.
```

Prepared input also centralizes translation from PCRE2 byte offsets back to Pharo character indexes.
