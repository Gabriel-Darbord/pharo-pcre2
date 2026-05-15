# Lifecycle and Native Library

## Native Library

Pharo-PCRE2 binds to the PCRE2 8-bit API. The host must provide a compatible PCRE2 10.x library. The project checks the loaded library's major version at startup and uses PCRE2 configuration queries for feature checks such as JIT and Unicode support.

Minor PCRE2 versions may report different configuration strings or Unicode versions. Prefer checking capabilities over comparing exact minor-version text.

## Compiled Patterns and Image Restarts

A compiled PCRE2 pattern is a native object outside the Pharo object memory. `PCRE2SessionManager` keeps matchers usable across image restarts.

The default mode is serialization:

1. At shutdown, the manager serializes compiled matchers as a batch.
2. At startup, it compares the saved native-library signature with the current one.
3. If the signature matches, it deserializes the native code.
4. If deserialization is unsafe or unavailable, it recompiles from the saved pattern and options.

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
