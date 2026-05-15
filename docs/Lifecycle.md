# Lifecycle and Native Library

## Native Library

Pharo-PCRE2 uses `LibPCRE2UTF8` for the default PCRE2 8-bit API. The host must provide a compatible PCRE2 10.x library. The project checks the loaded library's major version at startup and uses PCRE2 configuration queries for feature checks such as JIT and Unicode support.

Minor PCRE2 versions may report different configuration strings or Unicode versions. Prefer checking capabilities over comparing exact minor-version text.

The optional UTF-16 and UTF-32 matchers bind through `LibPCRE2UTF16` and `LibPCRE2UTF32` to PCRE2's separate `libpcre2-16` and `libpcre2-32` libraries. `LibPCRE2` is an abstract compatibility facade; check `LibPCRE2 supports16BitCodeUnitWidth` or `LibPCRE2 supports32BitCodeUnitWidth` before depending on wider libraries in portable code.

## Compiled Patterns and Image Restarts

A compiled PCRE2 pattern is a native object outside the Pharo object memory. `PCRE2SessionManager` keeps matchers usable across image restarts.

The default mode is serialization:

1. At shutdown, the manager serializes compiled matchers as a batch.
2. Matchers are grouped by PCRE2 code-unit width, because the 8-bit, 16-bit, and 32-bit libraries deserialize their own compiled patterns.
3. At startup, it compares the saved native-library signature with the current one.
4. If the signature matches, it deserializes the native code.
5. If deserialization is unsafe or unavailable, it recompiles from the saved pattern and options.

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
