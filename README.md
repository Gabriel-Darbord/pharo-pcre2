[![Pharo version](https://img.shields.io/badge/Pharo-12%20%7C%2013%20%7C%2014%20%7C%2015-%23aac9ff.svg)](https://github.com/pharo-project/Pharo)
![Build Info](https://github.com/Gabriel-Darbord/pharo-pcre2/workflows/CI/badge.svg)
[![Coverage Status](https://coveralls.io/repos/github/Gabriel-Darbord/pharo-pcre2/badge.svg?branch=main)](https://coveralls.io/github/Gabriel-Darbord/pharo-pcre2?branch=main)

# Pharo-PCRE2

Perl-compatible regular expressions for Pharo.

```smalltalk
'(?<key>\w+)=(?<value>\d+)' asPerlCompatibleRegex findMatch: 'size=42'.
```

Two interchangeable backends sit behind the same API. The default one executes entirely in the image and needs nothing installed on the host. The other binds the [PCRE2](https://github.com/PCRE2Project/pcre2) C library through FFI and is faster, at the cost of a native dependency.

## Why

- **The full PCRE2 syntax**, the one Perl, Python, JavaScript, Java and grep speak: lookaround, named groups, atomic and possessive quantifiers, conditionals, recursion, `\p{...}` over the whole Unicode catalogue, and inline options.
- **Nothing to install.** The default backend is ordinary Pharo code, so a load works on any image and any host.
- **Faster when it matters.** The Pharo backend writes a method for the patterns it can and runs it compiled; the FFI backend hands the work to the C library.
- **Bounded.** A match limit stops a pathological pattern instead of letting it run away with the image.
- **A drop-in for Rx.** A matcher answers the whole public protocol of Pharo's `RxMatcher`, streams included.
- **Beyond matching**: splitting, substitution with PCRE2 replacement syntax, partial and DFA matching, prepared subjects for repeated matching, UTF-8, UTF-16 and UTF-32, callouts, and a trace debugger.

## Documentation

- [Getting Started](docs/GettingStarted.md) — installing it and using it
- [API](docs/API.md) — the whole surface, Rx compatibility included
- [Backends](docs/Backends.md) — choosing one, and what the Pharo one does not do yet
- [Lifecycle](docs/Lifecycle.md) — native resources, serialization and image restarts

For the regular expression syntax itself, see the [official PCRE2 documentation](https://www.pcre.org/current/doc/html/index.html).

## Pharo Versions

Developed on Pharo 14 and targeting Pharo 15. Pharo 12, 13, 14 and 15 are verified in CI, with and without the C library.

## License

MIT. The bundled Unicode data is under the [Unicode License V3](docs/Unicode-LICENSE.txt), and the property-name and error-message catalogs under the [PCRE2 license](docs/PCRE2-LICENCE.md).
