[![Pharo version](https://img.shields.io/badge/Pharo-12-%23aac9ff.svg)](https://github.com/pharo-project/Pharo)
![Build Info](https://github.com/Gabriel-Darbord/pharo-pcre2/workflows/CI/badge.svg)
[![Coverage Status](https://coveralls.io/repos/github/Gabriel-Darbord/pharo-pcre2/badge.svg?branch=main)](https://coveralls.io/github/Gabriel-Darbord/pharo-pcre2?branch=main)

# Pharo-PCRE2

Perl-compatible regular expressions for Pharo, using the [PCRE2](https://github.com/PCRE2Project/pcre2) library via FFI.

## Installation

Load the project into a Pharo image:
```st
Metacello new
  githubUser: 'Gabriel-Darbord' project: 'pharo-pcre2' commitish: 'main' path: 'src';
  baseline: 'PCRE2';
  load
```
Make sure you have the PCRE2 library installed:
- Linux:
```sh
sudo apt install libpcre2-dev
```
- macOS:
```sh
brew install pcre2
```

## Usage

Similar to the Regex package, the main way to get a matcher is to send `asPCRegex` to a String.
PCRE2 offers a wide range of options, please refer to its [documentation](https://www.pcre.org/current/doc/html/index.html).
