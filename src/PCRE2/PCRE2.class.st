"
I contain the constants and option helpers used by the PCRE2 binding.

The `documentation` protocol contains methods to get information about specific options. Options defined as bitwise flags have dedicated helpers to ease human interaction. For example, `PCRE2 readOptions: 40 for: #compile` shows that `PCRE2 class>>#caseless` and `PCRE2 class>>#dotAll` are set. Options for `LibPCRE2UTF8>>#config:` and `PCRE2Matcher>>#info:` do not rely on flags and are not supported by these helpers.

Many error codes are defined by the PCRE2 library. Only those that can be expected without having to throw an error are referenced here.
"
Class {
	#name : 'PCRE2',
	#superclass : 'Object',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'documentation' }
PCRE2 class >> allInfoOnRegex: regex [
	"All available information about a compiled regex"

	| infos |
	infos := Dictionary new: 27.
	self class methods do: [ :method |
			(method selector beginsWith: #info) ifTrue: [
					| option |
					option := self perform: method selector.
					infos at: method put: (regex info: option) ] ].
	^ infos
]

{ #category : 'documentation' }
PCRE2 class >> allOptions [
	"Answer all known bitwise options, by PCRE2 function and flag value."

	| options |
	options := Dictionary new: 7.
	self optionSelectors pairsDo: [ :function :selectors |
			options at: function put: (selectors inject: Dictionary new into: [ :methods :selector |
						 methods
							 at: (self perform: selector) put: self class >> selector;
							 yourself ]) ].
	^ options
]

{ #category : 'options' }
PCRE2 class >> allowEmptyClass [
	"Allow empty classes"

	^ 16r00000001
]

{ #category : 'options' }
PCRE2 class >> altBSUX [
	"Alternative handling of \u, \U, and \x"

	^ 16r00000002
]

{ #category : 'options' }
PCRE2 class >> altCircumflex [
	"Alternative handling of ^ in multiline mode
	Affects: jit_compile, match, dfa_match"

	^ 16r00200000
]

{ #category : 'options' }
PCRE2 class >> altExtendedClass [
	"Enable UTS#18 nested character classes and doubled set operators."

	^ 16r08000000
]

{ #category : 'options' }
PCRE2 class >> altVerbNames [
	"Process backslashes in verb names"

	^ 16r00400000
]

{ #category : 'options' }
PCRE2 class >> anchored [
	"Match only at the first position"

	^ 16r80000000
]

{ #category : 'options' }
PCRE2 class >> autoCallout [
	"Compile automatic callouts"

	^ 16r00000004
]

{ #category : 'options' }
PCRE2 class >> automaticCalloutNumber [
	"PCRE2 reports generated automatic callout sites and events with callout number 255."

	^ 255
]

{ #category : 'options' }
PCRE2 class >> bsrAnyCRLF [
	"Compile-context value: \R matches only CR, LF, or CRLF."

	^ 2
]

{ #category : 'options' }
PCRE2 class >> bsrUnicode [
	"Compile-context value: \R matches any Unicode line ending sequence."

	^ 1
]

{ #category : 'options' }
PCRE2 class >> calloutBacktrack [
	"Callout flag set when matching has backtracked since the previous callout."

	^ 2
]

{ #category : 'options' }
PCRE2 class >> calloutStartMatch [
	"Callout flag set for the first callout after a new match attempt starts."

	^ 1
]

{ #category : 'options' }
PCRE2 class >> caseless [
	"Do caseless matching"

	^ 16r00000008
]

{ #category : 'options' }
PCRE2 class >> configBSR [
	"Returns what \R matches by default"

	^ 0
]

{ #category : 'options' }
PCRE2 class >> configCompiledWidths [
	"Returns which of 8/16/32 support was compiled, 1=8-bit, 2=16-bit, 4=32-bit.
	For example a value of 7 (1+2+4) means all the widths are supported."

	^ 14
]

{ #category : 'options' }
PCRE2 class >> configDepthLimit [
	"Returns the default backtracking depth limit"

	^ 7
]

{ #category : 'options' }
PCRE2 class >> configHeapLimit [
	"Returns the default heap memory limit"

	^ 12
]

{ #category : 'options' }
PCRE2 class >> configJIT [
	"Returns the availability of just-in-time compiler support (1=yes 0=no)"

	^ 1
]

{ #category : 'options' }
PCRE2 class >> configJITTarget [
	"Returns information (a string) about the target architecture for the JIT compiler"

	^ 2
]

{ #category : 'options' }
PCRE2 class >> configLinkSize [
	"Returns the configured internal link size (2, 3, 4)"

	^ 3
]

{ #category : 'options' }
PCRE2 class >> configMatchLimit [
	"Returns the default internal resource limit"

	^ 4
]

{ #category : 'options' }
PCRE2 class >> configNeverBackslashC [
	"Returns whether or not \C is disabled"

	^ 13
]

{ #category : 'options' }
PCRE2 class >> configNewline [
	"Returns the code for the default newline sequence
	1=cr, 2=lf, 3=crlf, 4=any, 5=any crlf, 6=nul"

	^ 5
]

{ #category : 'options' }
PCRE2 class >> configParensLimit [
	"Returns the default parentheses nesting limit"

	^ 6
]

{ #category : 'options' }
PCRE2 class >> configTablesLength [
	"Returns the length of the internal tables used"

	^ 15
]

{ #category : 'options' }
PCRE2 class >> configUnicode [
	"Returns the availability of Unicode support (1=yes 0=no)"

	^ 9
]

{ #category : 'options' }
PCRE2 class >> configUnicodeVersion [
	"Returns the Unicode version (a string)"

	^ 10
]

{ #category : 'options' }
PCRE2 class >> configVersion [
	"Returns the PCRE2 version (a string)"

	^ 11
]

{ #category : 'options' }
PCRE2 class >> convertGlob [
	"Convert a glob pattern."

	^ 16r00000010
]

{ #category : 'options' }
PCRE2 class >> convertGlobNoStarStar [
	"Convert a glob pattern without recognizing a doubled star as a recursive wildcard."

	^ 16r00000050
]

{ #category : 'options' }
PCRE2 class >> convertGlobNoWildSeparator [
	"Convert a glob pattern without allowing wildcards to match path separators."

	^ 16r00000030
]

{ #category : 'options' }
PCRE2 class >> convertNoUTFCheck [
	"Do not check conversion input for UTF validity."

	^ 16r00000002
]

{ #category : 'options' }
PCRE2 class >> convertPOSIXBasic [
	"Convert a POSIX basic regular expression."

	^ 16r00000004
]

{ #category : 'options' }
PCRE2 class >> convertPOSIXExtended [
	"Convert a POSIX extended regular expression."

	^ 16r00000008
]

{ #category : 'options' }
PCRE2 class >> convertUTF [
	"Treat conversion input as UTF."

	^ 16r00000001
]

{ #category : 'options' }
PCRE2 class >> copyMatchedSubject [
	"On success, make a private subject copy"

	^ 16r00004000
]

{ #category : 'options' }
PCRE2 class >> dfaRestart [
	"Restart after a partial match"

	^ 16r00000040
]

{ #category : 'options' }
PCRE2 class >> dfaShortest [
	"Return only the shortest match"

	^ 16r00000080
]

{ #category : 'options' }
PCRE2 class >> disableRecurseloopCheck [
	"Only useful in rare cases; use with care"

	^ 16r00040000
]

{ #category : 'options' }
PCRE2 class >> dollarEndOnly [
	"$ not to match newline at end
	Affects: jit_compile, match, dfa_match"

	^ 16r00000010
]

{ #category : 'options' }
PCRE2 class >> dotAll [
	". matches anything including NL"

	^ 16r00000020
]

{ #category : 'options' }
PCRE2 class >> dupNames [
	"Allow duplicate names for subpatterns"

	^ 16r00000040
]

{ #category : 'options' }
PCRE2 class >> endAnchored [
	"Pattern can match only at end of subject"

	^ 16r20000000
]

{ #category : 'errors' }
PCRE2 class >> errorCallout [
	"Reserved for callout functions that intentionally abort matching. PCRE2 never generates this error itself."

	^ -37
]

{ #category : 'errors' }
PCRE2 class >> errorDFAInvalidUTF [
	"DFA matching was asked to run a pattern compiled with PCRE2_MATCH_INVALID_UTF, which only the ordinary matching function supports."

	^ -66
]

{ #category : 'errors' }
PCRE2 class >> errorNoMatch [
	"No match was found. This result is handled by the wrapper and does not signal."

	^ -1
]

{ #category : 'errors' }
PCRE2 class >> errorNoMemory [
	"Can be mainly returned from:
	- jit_compile: unable to allocate executable memory for the compiler, even if it was because of a system security restriction
	- match: the backtracking match limit was reached
	- substitute: output buffer is too small"

	^ -48
]

{ #category : 'errors' }
PCRE2 class >> errorPartial [
	"A partial match was found. This result is handled by the wrapper and does not signal."

	^ -2
]

{ #category : 'errors' }
PCRE2 class >> errorReplaceCase [
	"A substitution case callout reported that it could not transform replacement text."

	^ -69
]

{ #category : 'errors' }
PCRE2 class >> errorUnset [
	"The requested field is not set."

	^ -55
]

{ #category : 'options' }
PCRE2 class >> extended [
	"Ignore white space and # comments"

	^ 16r00000080
]

{ #category : 'options' }
PCRE2 class >> extendedMore [
	"Perl's /xx feature (https://perldoc.perl.org/perlre#%2Fx-and-%2Fxx)"

	^ 16r01000000
]

{ #category : 'options' }
PCRE2 class >> extraAllowLookaroundBsk [
	"Since release 10.38, PCRE2 has forbidden the use of \K within lookaround assertions, following Perl's lead.
	This option is provided to re-enable the previous behaviour (act in positive lookarounds, ignore in negative ones) in case anybody is relying on it."

	^ 16r00000040
]

{ #category : 'options' }
PCRE2 class >> extraAllowSurrogateEscapes [
	"This option applies when compiling a pattern in UTF-8 or UTF-32 mode.
	If the extra option PCRE2_EXTRA_ALLOW_SURROGATE_ESCAPES is set, surrogate code point values in UTF-8 and
	UTF-32 patterns no longer provoke errors and are incorporated in the compiled pattern.
	However, they can only match subject characters if the matching function is called with PCRE2_NO_UTF_CHECK set."

	^ 16r00000001
]

{ #category : 'options' }
PCRE2 class >> extraAltBsux [
	"Setting PCRE2_EXTRA_ALT_BSUX has the effect of PCRE2_ALT_BSUX, but in addition, it recognizes \u{hhh..}
	as a hexadecimal character code, where hhh.. is any number of hexadecimal digits."

	^ 16r00000020
]

{ #category : 'options' }
PCRE2 class >> extraAsciiBsd [
	"This option forces \d to match only ASCII digits, even when PCRE2_UCP is set.
	It can be changed within a pattern by means of the (?aD) option setting."

	^ 16r00000100
]

{ #category : 'options' }
PCRE2 class >> extraAsciiBss [
	"This option forces \s to match only ASCII space characters, even when PCRE2_UCP is set.
	It can be changed within a pattern by means of the (?aS) option setting."

	^ 16r00000200
]

{ #category : 'options' }
PCRE2 class >> extraAsciiBsw [
	"This option forces \w to match only ASCII word characters, even when PCRE2_UCP is set.
	It can be changed within a pattern by means of the (?aW) option setting."

	^ 16r00000400
]

{ #category : 'options' }
PCRE2 class >> extraAsciiDigit [
	"This option forces the POSIX character classes [:digit:] and [:xdigit:] to match only ASCII digits, even when PCRE2_UCP is set.
	It can be changed within a pattern by means of the (?aT) option setting."

	^ 16r00001000
]

{ #category : 'options' }
PCRE2 class >> extraAsciiPosix [
	"This option forces all the POSIX character classes, including [:digit:] and [:xdigit:], to match only ASCII characters, even when PCRE2_UCP is set.
	It can be changed within a pattern by means of the (?aP) option setting, but note that this also sets PCRE2_EXTRA_ASCII_DIGIT in order to ensure that (?-aP) unsets all ASCII restrictions for POSIX classes."

	^ 16r00000800
]

{ #category : 'options' }
PCRE2 class >> extraBadEscapeIsLiteral [
	"If the PCRE2_EXTRA_BAD_ESCAPE_IS_LITERAL extra option is passed to pcre2_compile(), all unrecognized or malformed escape sequences are treated as single-character escapes.
	For example, \j is a literal 'j' and \x{2z} is treated as the literal string 'x{2z}'.
	Setting this option means that typos in patterns may go undetected and have unexpected results.
	Use with great care."

	^ 16r00000002
]

{ #category : 'options' }
PCRE2 class >> extraCaselessRestrict [
	"This option disables recognition of case-equivalences that cross the ASCII/non-ASCII boundary.
	In a caseless match, both characters must either be ASCII or non-ASCII.
	The option can be changed with a pattern by the (?r) option setting."

	^ 16r00000080
]

{ #category : 'options' }
PCRE2 class >> extraEscapedCrIsLf [
	"There are some legacy applications where the escape sequence \r in a pattern is expected to match a newline.
	If this option is set, \r in a pattern is converted to \n so that it matches a LF (linefeed) instead of a CR (carriage return) character.
	The option does not affect a literal CR in the pattern, nor does it affect CR specified as an explicit code point such as \x{0D}."

	^ 16r00000010
]

{ #category : 'options' }
PCRE2 class >> extraMatchLine [
	"This option is provided for use by the -x option of pcre2grep.
	It causes the pattern only to match complete lines.
	This is achieved by automatically inserting the code for '^(?:' at the start of the compiled pattern and ')$' at the end.
	Thus, when PCRE2_MULTILINE is set, the matched line may be in the middle of the subject string.
	This option can be used with PCRE2_LITERAL."

	^ 16r00000008
]

{ #category : 'options' }
PCRE2 class >> extraMatchWord [
	"This option is provided for use by the -w option of pcre2grep.
	It causes the pattern only to match strings that have a word boundary at the start and the end.
	This is achieved by automatically inserting the code for '\b(?:' at the start of the compiled pattern and ')\b' at the end.
	The option may be used with PCRE2_LITERAL.
	However, it is ignored if PCRE2_EXTRA_MATCH_LINE is also set."

	^ 16r00000004
]

{ #category : 'options' }
PCRE2 class >> extraNeverCallout [
	"Reject callouts in the pattern."

	^ 16r00008000
]

{ #category : 'options' }
PCRE2 class >> extraNoBs0 [
	"Reject backslash zero escapes."

	^ 16r00004000
]

{ #category : 'options' }
PCRE2 class >> extraPythonOctal [
	"Use Python rules to distinguish octal escapes from numeric backreferences."

	^ 16r00002000
]

{ #category : 'options' }
PCRE2 class >> extraTurkishCasing [
	"Use Turkish Unicode case equivalences."

	^ 16r00010000
]

{ #category : 'options' }
PCRE2 class >> firstLine [
	"Force matching to be before newline
	Affects: jit_compile, match, dfa_match"

	^ 16r00000100
]

{ #category : 'options' }
PCRE2 class >> infoAllOptions [
	"Final options after compiling"

	^ 0
]

{ #category : 'options' }
PCRE2 class >> infoArgOptions [
	"Options passed to compile()"

	^ 1
]

{ #category : 'options' }
PCRE2 class >> infoBSR [
	"What \R matches: PCRE2_BSR_UNICODE for Unicode line endings, or PCRE2_BSR_ANYCRLF for CR, LF, or CRLF only"

	^ 3
]

{ #category : 'options' }
PCRE2 class >> infoBackrefMax [
	"Number of highest backreference"

	^ 2
]

{ #category : 'options' }
PCRE2 class >> infoCaptureCount [
	"Number of capturing subpatterns"

	^ 4
]

{ #category : 'options' }
PCRE2 class >> infoDepthLimit [
	"Backtracking depth limit if set, otherwise PCRE2_ERROR_UNSET"

	^ 21
]

{ #category : 'options' }
PCRE2 class >> infoExtraOptions [
	"Extra options that were passed in the compile context"

	^ 26
]

{ #category : 'options' }
PCRE2 class >> infoFirstBitmap [
	"Bitmap of first code units, or NULL"

	^ 7
]

{ #category : 'options' }
PCRE2 class >> infoFirstCodeType [
	"Type of start-of-match information: 0 nothing set, 1 first code unit is set, 2 start of string or after newline"

	^ 6
]

{ #category : 'options' }
PCRE2 class >> infoFirstCodeUnit [
	"First code unit when type is 1"

	^ 5
]

{ #category : 'options' }
PCRE2 class >> infoFrameSize [
	"Size of backtracking frame"

	^ 24
]

{ #category : 'options' }
PCRE2 class >> infoHasBackslashC [
	"Return 1 if pattern contains \C"

	^ 23
]

{ #category : 'options' }
PCRE2 class >> infoHasCrOrLf [
	"Return 1 if explicit CR or LF matches exist in the pattern"

	^ 8
]

{ #category : 'options' }
PCRE2 class >> infoHeapLimit [
	"Heap memory limit if set, otherwise PCRE2_ERROR_UNSET"

	^ 25
]

{ #category : 'options' }
PCRE2 class >> infoJChanged [
	"Return 1 if (?J) or (?-J) was used"

	^ 9
]

{ #category : 'options' }
PCRE2 class >> infoJITSize [
	"Size of JIT compiled code, or 0"

	^ 10
]

{ #category : 'options' }
PCRE2 class >> infoLastCodeType [
	"Type of must-be-present information: 0 nothing set, 1 code unit is set"

	^ 12
]

{ #category : 'options' }
PCRE2 class >> infoLastCodeUnit [
	"Last code unit when type is 1"

	^ 11
]

{ #category : 'options' }
PCRE2 class >> infoMatchEmpty [
	"Return 1 if the pattern can match an empty string, 0 otherwise"

	^ 13
]

{ #category : 'options' }
PCRE2 class >> infoMatchLimit [
	"Match limit if set, otherwise PCRE2_ERROR_UNSET"

	^ 14
]

{ #category : 'options' }
PCRE2 class >> infoMaxLookbehind [
	"Length (in characters) of the longest lookbehind assertion"

	^ 15
]

{ #category : 'options' }
PCRE2 class >> infoMinLength [
	"Lower bound length of matching strings"

	^ 16
]

{ #category : 'options' }
PCRE2 class >> infoNameCount [
	"Number of named subpatterns"

	^ 17
]

{ #category : 'options' }
PCRE2 class >> infoNameEntrySize [
	"Size of name table entries"

	^ 18
]

{ #category : 'options' }
PCRE2 class >> infoNameTable [
	"Pointer to name table"

	^ 19
]

{ #category : 'options' }
PCRE2 class >> infoNewline [
	"Code for the newline sequence: PCRE2_NEWLINE_CR, PCRE2_NEWLINE_LF, PCRE2_NEWLINE_CRLF, PCRE2_NEWLINE_ANY, PCRE2_NEWLINE_ANYCRLF, PCRE2_NEWLINE_NUL"

	^ 20
]

{ #category : 'options' }
PCRE2 class >> infoSize [
	"Size of compiled pattern"

	^ 22
]

{ #category : 'options' }
PCRE2 class >> jitComplete [
	"Compile code for full matching"

	^ 16r00000001
]

{ #category : 'options' }
PCRE2 class >> jitPartialHard [
	"Compile code for hard partial matching"

	^ 16r00000004
]

{ #category : 'options' }
PCRE2 class >> jitPartialSoft [
	"Compile code for soft partial matching"

	^ 16r00000002
]

{ #category : 'options' }
PCRE2 class >> literal [
	"Pattern characters are all literal"

	^ 16r02000000
]

{ #category : 'options' }
PCRE2 class >> matchInvalidUTF [
	"Enable support for matching invalid UTF
	Affects: jit_compile, match, dfa_match"

	^ 16r04000000
]

{ #category : 'options' }
PCRE2 class >> matchUnsetBackref [
	"Match unset backreferences
	Affects: compile, jit_compile, match"

	^ 16r00000200
]

{ #category : 'constants' }
PCRE2 class >> maximumSizeT [

	^ (1 bitShift: Smalltalk wordSize * 8) - 1
]

{ #category : 'options' }
PCRE2 class >> multiline [
	"^ and $ match newlines within data"

	^ 16r00000400
]

{ #category : 'options' }
PCRE2 class >> neverBackslashC [
	"Lock out the use of \C in patterns"

	^ 16r00100000
]

{ #category : 'options' }
PCRE2 class >> neverUCP [
	"Lock out PCRE2_UCP, e.g. via (*UCP)"

	^ 16r00000800
]

{ #category : 'options' }
PCRE2 class >> neverUTF [
	"Lock out PCRE2_UTF, e.g. via (*UTF)"

	^ 16r00001000
]

{ #category : 'options' }
PCRE2 class >> newlineAny [
	"Option for compile contexts"

	^ 4
]

{ #category : 'options' }
PCRE2 class >> newlineAnyCRLF [
	"Option for compile contexts"

	^ 5
]

{ #category : 'options' }
PCRE2 class >> newlineCR [
	"Option for compile contexts"

	^ 1
]

{ #category : 'options' }
PCRE2 class >> newlineCRLF [
	"Option for compile contexts"

	^ 3
]

{ #category : 'options' }
PCRE2 class >> newlineLF [
	"Option for compile contexts"

	^ 2
]

{ #category : 'options' }
PCRE2 class >> newlineNul [
	"Option for compile contexts"

	^ 6
]

{ #category : 'options' }
PCRE2 class >> noAutoCapture [
	"Disable numbered capturing parentheses (named ones available)"

	^ 16r00002000
]

{ #category : 'options' }
PCRE2 class >> noAutoPossess [
	"Disable auto-possessification"

	^ 16r00004000
]

{ #category : 'options' }
PCRE2 class >> noDotstarAnchor [
	"Disable automatic anchoring for .*"

	^ 16r00008000
]

{ #category : 'options' }
PCRE2 class >> noJIT [
	"Do not use JIT matching"

	^ 16r00002000
]

{ #category : 'options' }
PCRE2 class >> noStartOptimize [
	"Disable match-time start optimizations
	Affects: jit_compile, match, dfa_match"

	^ 16r00010000
]

{ #category : 'options' }
PCRE2 class >> noUTFCheck [
	"Do not check the subject for UTF validity."

	^ 16r40000000
]

{ #category : 'options' }
PCRE2 class >> notBOL [
	"Subject string is not the beginning of a line"

	^ 16r00000001
]

{ #category : 'options' }
PCRE2 class >> notEOL [
	"Subject string is not the end of a line"

	^ 16r00000002
]

{ #category : 'options' }
PCRE2 class >> notEmpty [
	"An empty string is not a valid match"

	^ 16r00000004
]

{ #category : 'options' }
PCRE2 class >> notEmptyAtStart [
	"An empty string at the start of the subject is not a valid match"

	^ 16r00000008
]

{ #category : 'options' }
PCRE2 class >> optimizationFull [
	"Directive for compile contexts: enable all optional performance optimizations."

	^ 1
]

{ #category : 'options' }
PCRE2 class >> optimizationNone [
	"Directive for compile contexts: disable all optional performance optimizations."

	^ 0
]

{ #category : 'options' }
PCRE2 class >> optimizeAutoPossess [
	"Directive for compile contexts: enable auto-possessification."

	^ 64
]

{ #category : 'options' }
PCRE2 class >> optimizeAutoPossessOff [
	"Directive for compile contexts: disable auto-possessification."

	^ 65
]

{ #category : 'options' }
PCRE2 class >> optimizeDotstarAnchor [
	"Directive for compile contexts: enable implicit dot-star anchoring."

	^ 66
]

{ #category : 'options' }
PCRE2 class >> optimizeDotstarAnchorOff [
	"Directive for compile contexts: disable implicit dot-star anchoring."

	^ 67
]

{ #category : 'options' }
PCRE2 class >> optimizeStart [
	"Directive for compile contexts: enable start-of-match optimizations."

	^ 68
]

{ #category : 'options' }
PCRE2 class >> optimizeStartOff [
	"Directive for compile contexts: disable start-of-match optimizations."

	^ 69
]

{ #category : 'documentation' }
PCRE2 class >> optionSelectors [
	"The selectors of the options of each PCRE2 function."

	^ #( #compile #( #allowEmptyClass #altBSUX #altCircumflex #altExtendedClass #altVerbNames #anchored #autoCallout #caseless
	        #dollarEndOnly #dotAll #dupNames #endAnchored #extended #extendedMore #firstLine #literal #matchInvalidUTF
	        #matchUnsetBackref #multiline #neverBackslashC #neverUCP #neverUTF #noAutoCapture #noAutoPossess #noDotstarAnchor
	        #noStartOptimize #noUTFCheck #ucp #ungreedy #useOffsetLimit #utf )
	     #jit_compile #( #jitComplete #jitPartialHard #jitPartialSoft ) #match #( #anchored #copyMatchedSubject #disableRecurseloopCheck
	        #endAnchored #noJIT #noUTFCheck #notBOL #notEOL #notEmpty #notEmptyAtStart #partialHard #partialSoft )
	     #jit_match #( #copyMatchedSubject #noJIT #notBOL #notEOL #notEmpty #notEmptyAtStart #partialHard #partialSoft )
	     #dfa_match #( #anchored #copyMatchedSubject #dfaRestart #dfaShortest #endAnchored #noUTFCheck #notBOL #notEOL #notEmpty
	        #notEmptyAtStart #partialHard #partialSoft )
	     #substitute #( #copyMatchedSubject #disableRecurseloopCheck #noJIT #substituteExtended #substituteGlobal #substituteLiteral
	        #substituteMatched #substituteOverflowLength #substituteReplacementOnly #substituteUnknownUnset #substituteUnsetEmpty )
	     #convert #( #convertGlob #convertGlobNoStarStar #convertGlobNoWildSeparator #convertNoUTFCheck #convertPOSIXBasic
	        #convertPOSIXExtended #convertUTF ) )
]

{ #category : 'documentation' }
PCRE2 class >> options: options includes: query [
	"Multiple options can be checked at once, returns true if all are set"

	^ (options bitAnd: query) == query
]

{ #category : 'documentation' }
PCRE2 class >> optionsFor: function [
	"Answer the methods defining an option of a PCRE2 function: #compile, #jit_compile, #match, #jit_match, #dfa_match, #substitute or #convert."

	self optionSelectors pairsDo: [ :each :selectors |
		each = function ifTrue: [ ^ selectors collect: [ :selector | self class >> selector ] ] ].
	^ #(  )
]

{ #category : 'options' }
PCRE2 class >> partialHard [
	"Return PCRE2_ERROR_PARTIAL for a partial match even if there is a full match"

	^ 16r00000020
]

{ #category : 'options' }
PCRE2 class >> partialSoft [
	"Return PCRE2_ERROR_PARTIAL for a partial match if no full matches are found"

	^ 16r00000010
]

{ #category : 'documentation' }
PCRE2 class >> readOptions: anInteger [
	"Convenience method for finding which options are declared by the integer"

	| result options bit |
	result := Dictionary new.
	options := self allOptions.
	bit := 1.
	1 to: 32 do: [ :i |
			(anInteger bitAnd: bit) = bit ifTrue: [
					options keysAndValuesDo: [ :fun :forFun |
							forFun
								at: bit
								ifPresent: [ :method |
								result at: fun ifPresent: [ :methods | methods add: method ] ifAbsentPut: [ OrderedCollection with: method ] ] ] ].
			bit := bit * 2 ].
	^ result
]

{ #category : 'documentation' }
PCRE2 class >> readOptions: anInteger for: function [
	"Answer the option methods declared by anInteger for the given PCRE2 function.
	Expected symbols are #compile, #jit_compile, #match, #jit_match, #dfa_match, #substitute, and #convert."

	^ (self readOptions: anInteger) at: function ifAbsent: [ #(  ) ]
]

{ #category : 'constants' }
PCRE2 class >> substituteCalloutAccept [
	"Return from a substitution callout to accept the processed replacement."

	^ 0
]

{ #category : 'constants' }
PCRE2 class >> substituteCalloutRejectAndContinue [
	"Return from a global substitution callout to reject the current replacement and keep looking."

	^ 1
]

{ #category : 'constants' }
PCRE2 class >> substituteCalloutRejectAndStop [
	"Return from a substitution callout to reject the current replacement and stop substituting."

	^ -1
]

{ #category : 'constants' }
PCRE2 class >> substituteCaseLower [
	"Substitution case callout request: lowercase the entire input."

	^ 1
]

{ #category : 'constants' }
PCRE2 class >> substituteCaseTitleFirst [
	"Substitution case callout request: titlecase the first character and lowercase the rest."

	^ 3
]

{ #category : 'constants' }
PCRE2 class >> substituteCaseUpper [
	"Substitution case callout request: uppercase the entire input."

	^ 2
]

{ #category : 'options' }
PCRE2 class >> substituteExtended [
	"Do extended replacement processing"

	^ 16r00000200
]

{ #category : 'options' }
PCRE2 class >> substituteGlobal [
	"Replace all occurrences in the subject"

	^ 16r00000100
]

{ #category : 'options' }
PCRE2 class >> substituteLiteral [
	"The replacement string is literal"

	^ 16r00008000
]

{ #category : 'options' }
PCRE2 class >> substituteMatched [
	"Use pre-existing match data for 1st match"

	^ 16r00010000
]

{ #category : 'options' }
PCRE2 class >> substituteOverflowLength [
	"If overflow, compute needed length"

	^ 16r00001000
]

{ #category : 'options' }
PCRE2 class >> substituteReplacementOnly [
	"Return only replacement string(s)"

	^ 16r00020000
]

{ #category : 'options' }
PCRE2 class >> substituteUnknownUnset [
	"Treat unknown group as unset"

	^ 16r00000800
]

{ #category : 'options' }
PCRE2 class >> substituteUnsetEmpty [
	"Simple unset insert = empty string"

	^ 16r00000400
]

{ #category : 'error handling' }
PCRE2 class >> translateErrorCode: errorCode [
	"One message a line, for codes 100 to 220 and then -3 to -76."

	| index |
	index := (errorCode between: 100 and: 220)
		         ifTrue: [ errorCode - 99 ]
		         ifFalse: [
				         errorCode < -2
					         ifTrue: [ 119 - errorCode ]
					         ifFalse: [ 0 ] ].
	^ (index between: 1 and: 195)
		  ifTrue: [
				  'no error
\ at end of pattern
\c at end of pattern
unrecognized character follows \
numbers out of order in {} quantifier
number too big in {} quantifier
missing terminating ] for character class
escape sequence is invalid in character class
range out of order in character class
quantifier does not follow a repeatable item
internal error: unexpected repeat
unrecognized character after (? or (?-
POSIX named classes are supported only within a class
POSIX collating elements are not supported
missing closing parenthesis
reference to non-existent subpattern
pattern passed as NULL with non-zero length
unrecognised compile-time option bit(s)
missing ) after (?# comment
parentheses are too deeply nested
regular expression is too large
failed to allocate heap memory
unmatched closing parenthesis
internal error: code overflow
missing closing parenthesis for condition
length of lookbehind assertion is not limited
a relative value of zero is not allowed
conditional subpattern contains more than two branches
atomic assertion expected after (?( or (?(?C)
digit expected after (?+
unknown POSIX class name
internal error in pcre2_study(): should not occur
this version of PCRE2 does not have Unicode support
parentheses are too deeply nested (stack check)
character code point value in \x{} or \o{} is too large
lookbehind is too complicated
\C is not allowed in a lookbehind assertion in UTF-8 mode
PCRE2 does not support \F, \L, \l, \N{name}, \U, or \u
number after (?C is greater than 255
closing parenthesis for (?C expected
invalid escape sequence in (*VERB) name
unrecognized character after (?P
syntax error in subpattern name (missing terminator?)
two named subpatterns have the same name (PCRE2_DUPNAMES not set)
subpattern name must start with a non-digit
this version of PCRE2 does not have support for \P, \p, or \X
malformed \P or \p sequence
unknown property after \P or \p
subpattern name is too long (maximum 128 code units)
too many named subpatterns (maximum 10000)
invalid range in character class
octal value is greater than \377 in 8-bit non-UTF-8 mode
internal error: overran compiling workspace
internal error: previously-checked referenced subpattern not found
DEFINE subpattern contains more than one branch
missing opening brace after \o
internal error: unknown newline setting
\g is not followed by a braced, angle-bracketed, or quoted name/number or by a plain number
(?R (recursive pattern call) must be followed by a closing parenthesis
obsolete error (should not occur)
(*VERB) not recognized or malformed
subpattern number is too big
subpattern name expected
internal error: parsed pattern overflow
non-octal character in \o{} (closing brace missing?)
different names for subpatterns of the same number are not allowed
(*MARK) must have an argument
non-hex character in \x{} (closing brace missing?)
\c must be followed by a printable ASCII character
\k is not followed by a braced, angle-bracketed, or quoted name
internal error: unknown meta code in check_lookbehinds()
\N is not supported in a class
callout string is too long
disallowed Unicode code point (>= 0xd800 && <= 0xdfff)
using UTF is disabled by the application
using UCP is disabled by the application
name is too long in (*MARK), (*PRUNE), (*SKIP), or (*THEN)
character code point value in \u.... sequence is too large
digits missing after \x or in \x{} or \o{} or \N{U+}
syntax error or number too big in (?(VERSION condition
internal error: unknown opcode in auto_possessify()
missing terminating delimiter for callout with string argument
unrecognized string delimiter follows (?C
using \C is disabled by the application
(?| and/or (?J: or (?x: parentheses are too deeply nested
using \C is disabled in this PCRE2 library
regular expression is too complicated
lookbehind assertion is too long
pattern string is longer than the limit set by the application
internal error: unknown code in parsed pattern
internal error: bad code value in parsed_skip()
PCRE2_EXTRA_ALLOW_SURROGATE_ESCAPES is not allowed in UTF-16 mode
invalid option bits with PCRE2_LITERAL
\N{U+dddd} is supported only in Unicode (UTF) mode
invalid hyphen in option setting
(*alpha_assertion) not recognized
script runs require Unicode support, which this version of PCRE2 does not have
too many capturing groups (maximum 65535)
octal digit missing after \0 (PCRE2_EXTRA_NO_BS0 is set)
\K is not allowed in lookarounds (but see PCRE2_EXTRA_ALLOW_LOOKAROUND_BSK)
branch too long in variable-length lookbehind assertion
compiled pattern would be longer than the limit set by the application
octal value given by \ddd is greater than \377 (forbidden by PCRE2_EXTRA_PYTHON_OCTAL)
using callouts is disabled by the application
PCRE2_EXTRA_TURKISH_CASING require Unicode (UTF or UCP) mode
PCRE2_EXTRA_TURKISH_CASING requires UTF in 8-bit mode
PCRE2_EXTRA_TURKISH_CASING and PCRE2_EXTRA_CASELESS_RESTRICT are not compatible
extended character class nesting is too deep
invalid operator in extended character class
unexpected operator in extended character class (no preceding operand)
expected operand after operator in extended character class
square brackets needed to clarify operator precedence in extended character class
missing terminating ] for extended character class (note ''['' must be escaped under PCRE2_ALT_EXTENDED_CLASS)
unexpected expression in extended character class (no preceding operator)
empty expression in extended character class
terminating ] with no following closing parenthesis in (?[...]
unexpected character in (?[...]) extended character class
expected capture group number or name
missing opening parenthesis
syntax error in subpattern number (missing terminator?)
erroroffset passed as NULL
UTF-8 error: 1 byte missing at end
UTF-8 error: 2 bytes missing at end
UTF-8 error: 3 bytes missing at end
UTF-8 error: 4 bytes missing at end
UTF-8 error: 5 bytes missing at end
UTF-8 error: byte 2 top bits not 0x80
UTF-8 error: byte 3 top bits not 0x80
UTF-8 error: byte 4 top bits not 0x80
UTF-8 error: byte 5 top bits not 0x80
UTF-8 error: byte 6 top bits not 0x80
UTF-8 error: 5-byte character is not allowed (RFC 3629)
UTF-8 error: 6-byte character is not allowed (RFC 3629)
UTF-8 error: code points greater than 0x10ffff are not defined
UTF-8 error: code points 0xd800-0xdfff are not defined
UTF-8 error: overlong 2-byte sequence
UTF-8 error: overlong 3-byte sequence
UTF-8 error: overlong 4-byte sequence
UTF-8 error: overlong 5-byte sequence
UTF-8 error: overlong 6-byte sequence
UTF-8 error: isolated byte with 0x80 bit set
UTF-8 error: illegal byte (0xfe or 0xff)
UTF-16 error: missing low surrogate at end
UTF-16 error: invalid low surrogate
UTF-16 error: isolated low surrogate
UTF-32 error: code points 0xd800-0xdfff are not defined
UTF-32 error: code points greater than 0x10ffff are not defined
bad data value
patterns do not all use the same character tables
magic number missing
pattern compiled in wrong mode: 8/16/32-bit error
bad offset value
bad option value
invalid replacement string
bad offset into UTF string
callout error code
invalid data in workspace for DFA restart
too much recursion for DFA matching
backreference condition or recursion test is not supported for DFA matching
function is not supported for DFA matching
pattern contains an item that is not supported for DFA matching
workspace size exceeded in DFA matching
internal error - pattern overwritten?
bad JIT option
JIT stack limit reached
match limit exceeded
no more memory
unknown substring
non-unique substring name
NULL argument passed with non-zero length
nested recursion at the same subject position
matching depth limit exceeded
requested value is not available
requested value is not set
offset limit set without PCRE2_USE_OFFSET_LIMIT
bad escape sequence in replacement string
expected closing curly bracket in replacement string
bad substitution in replacement string
match with end before start or start moved backwards is not supported
too many replacements (more than INT_MAX)
bad serialized data
heap limit exceeded
invalid syntax
internal error: duplicate substitution match
PCRE2_MATCH_INVALID_UTF is not supported for DFA matching
internal error: invalid substring offset
feature is not supported by the JIT compiler
case transformation failed in replacement string
replacement too large (longer than PCRE2_SIZE)
substitute pattern differs from prior match call
substitute subject differs from prior match call
substitute start offset differs from prior match call
substitute options differ from prior match call
disallowed use of \K in lookaround
replacement $'' or $_ not supported with partial match' lines at: index ]
		  ifFalse: [ 'unknown error code: ' , errorCode asString ]
]

{ #category : 'options' }
PCRE2 class >> ucp [
	"Use Unicode properties for \d, \w, etc
	Affects: compile, jit_compile, match, dfa_match"

	^ 16r00020000
]

{ #category : 'options' }
PCRE2 class >> ungreedy [
	"Invert greediness of quantifiers"

	^ 16r00040000
]

{ #category : 'constants' }
PCRE2 class >> unsetOffset [
	"PCRE2_UNSET is the maximum PCRE2_SIZE value for the active native word size."

	^ self maximumSizeT
]

{ #category : 'options' }
PCRE2 class >> useOffsetLimit [
	"Enable PCRE2's code-unit offset limit for unanchored matching."

	^ 16r00800000
]

{ #category : 'options' }
PCRE2 class >> utf [
	"Treat pattern and subjects as UTF strings
	Affects: compile, jit_compile, match, dfa_match"

	^ 16r00080000
]

{ #category : 'constants' }
PCRE2 class >> zeroTerminated [
	"Some methods can use this value as a string upper bound argument to use a terminating null character instead of an index.
	Supported by match() and substitute().
	Not supported by jit_match()."

	^ self maximumSizeT
]
