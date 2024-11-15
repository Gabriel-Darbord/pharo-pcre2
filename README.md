[![Pharo version](https://img.shields.io/badge/Pharo-12-%23aac9ff.svg)](https://github.com/pharo-project/Pharo)
![Build Info](https://github.com/Gabriel-Darbord/pharo-pcre2/workflows/CI/badge.svg)
[![Coverage Status](https://coveralls.io/repos/github/Gabriel-Darbord/pharo-pcre2/badge.svg?branch=main)](https://coveralls.io/github/Gabriel-Darbord/pharo-pcre2?branch=main)

# Pharo-PCRE2

**Perl-Compatible Regular Expressions (PCRE)** for Pharo, using the [PCRE2 library](https://github.com/PCRE2Project/pcre2) via Foreign Function Interface (FFI).

## Installation

To load the project into your Pharo image, use the following script:
```st
Metacello new
  githubUser: 'Gabriel-Darbord' project: 'pharo-pcre2' commitish: 'main' path: 'src';
  baseline: 'PCRE2';
  load
```
Ensure that the PCRE2 library is installed on your system.
Use the appropriate command for your platform:
- Linux:
```sh
sudo apt install libpcre2-dev
```
- macOS:
```sh
brew install pcre2
```

## Usage

The main way to create a matcher is to send the `asPCRegex` message to a pattern string.
This approach is similar to the standard `Regex` package.
For example:
```st
'hello\d+' asPCRegex
```

PCRE2 provides a wide range of options for pattern matching.
For detailed usage and available features, see the [official PCRE2 documentation](https://www.pcre.org/current/doc/html/index.html).

## Lifecycle

Compiled patterns in PCRE2 are external objects, meaning they exist outside the Pharo image memory.
Without additional handling, these patterns would be lost after the Pharo image is restarted.
To address this issue, Pharo-PCRE2 includes a session manager that ensures that all compiled patterns are retained throughout the lifecycle of the image.
The manager supports two recovery strategies:
- Recompilation: Patterns are recompiled from their source string.
- Serialization: Patterns are stored and restored using raw bytes.

By default, the session manager uses serialization for efficiency.
This behavior can be adjusted using the `PCRE2SessionManager` API.

Serialization works under the following conditions:
> The host must be running the same version of PCRE2, with the same code unit width, endianness, pointer width, and PCRE2_SIZE type.

Most modern architectures are compatible with this requirement.
However, for maximum portability across different systems, switch to recompilation.
