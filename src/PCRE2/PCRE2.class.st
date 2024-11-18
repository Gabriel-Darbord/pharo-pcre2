"
I contain all of the options available to the PCRE2 library functions in my class methods.

The `documentation` protocol contains methods to get information about specific options.
Options defined as bitwise flags have dedicated helpers to ease human interaction.
For example, `PCRE2 readOptions: 40 for: #compile` shows that `PCRE2 class>>#caseless` and `PCRE2 class>>#dotAll` are set.
Options for `LibPCRE2>>#config:` and `PCRE2Code>>#info:` do not rely on flags and are not supported by these helpers.

Many error codes are defined by the PCRE2 library.
Only those that can be expected without having to throw an error are referenced here.
"
Class {
	#name : 'PCRE2',
	#superclass : 'Object',
	#classInstVars : [
		'errorCodeTable'
	],
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
	"All options organized by the function for which they are available and by flag value.
	Only relevant for compile, jit_compile, match, jit_match, dfa_match, substitute and convert."

	| options |
	options := Dictionary new: 7.
	self class methods do: [ :method |
		method pragmas
			detect: [ :pragma | pragma selector = #pcre2Option: ]
			ifFound: [ :pragma |
				| option |
				option := self perform: method selector.
				pragma arguments first do: [ :fun |
					options
						at: fun
						ifPresent: [ :methods | methods at: option put: method ]
						ifAbsentPut: [ Dictionary with: option -> method ] ] ] ].
	^ options
]

{ #category : 'options' }
PCRE2 class >> allowEmptyClass [
	"Allow empty classes"

	<pcre2Option: #( compile )>
	^ 16r00000001
]

{ #category : 'options' }
PCRE2 class >> altBSUX [
	"Alternative handling of \u, \U, and \x"

	<pcre2Option: #( compile )>
	^ 16r00000002
]

{ #category : 'options' }
PCRE2 class >> altCircumflex [
	"Alternative handling of ^ in multiline mode
	Affects: jit_compile, match, dfa_match"

	<pcre2Option: #( compile )>
	^ 16r00200000
]

{ #category : 'options' }
PCRE2 class >> altVerbNames [
	"Process backslashes in verb names"

	<pcre2Option: #( compile )>
	^ 16r00400000
]

{ #category : 'options' }
PCRE2 class >> anchored [
	"Match only at the first position"

	<pcre2Option: #( compile match dfa_match )>
	^ 16r80000000
]

{ #category : 'options' }
PCRE2 class >> autoCallout [
	"Compile automatic callouts"

	<pcre2Option: #( compile )>
	^ 16r00000004
]

{ #category : 'options' }
PCRE2 class >> caseless [
	"Do caseless matching"

	<pcre2Option: #( compile )>
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
	"Convert various types of glob"

	<pcre2Option: #( convert )>
	^ 16r00000010
]

{ #category : 'options' }
PCRE2 class >> convertGlobNoStarStar [
	"Convert various types of glob"

	<pcre2Option: #( convert )>
	^ 16r00000050
]

{ #category : 'options' }
PCRE2 class >> convertGlobNoWildSeparator [
	"Convert various types of glob"

	<pcre2Option: #( convert )>
	^ 16r00000030
]

{ #category : 'options' }
PCRE2 class >> convertNoUTFCheck [
	"Do not check UTF validity"

	<pcre2Option: #( convert )>
	^ 16r00000002
]

{ #category : 'options' }
PCRE2 class >> convertPOSIXBasic [
	"Convert POSIX basic pattern"

	<pcre2Option: #( convert )>
	^ 16r00000004
]

{ #category : 'options' }
PCRE2 class >> convertPOSIXExtended [
	"Convert POSIX extended pattern"

	<pcre2Option: #( convert )>
	^ 16r00000008
]

{ #category : 'options' }
PCRE2 class >> convertUTF [
	"Input is UTF"

	<pcre2Option: #( convert )>
	^ 16r00000001
]

{ #category : 'options' }
PCRE2 class >> copyMatchedSubject [
	"On success, make a private subject copy"

	<pcre2Option: #( match dfa_match jit_match substitute )>
	^ 16r00004000
]

{ #category : 'options' }
PCRE2 class >> dfaRestart [
	"Restart after a partial match"

	<pcre2Option: #( dfa_match )>
	^ 16r00000040
]

{ #category : 'options' }
PCRE2 class >> dfaShortest [
	"Return only the shortest match"

	<pcre2Option: #( dfa_match )>
	^ 16r00000080
]

{ #category : 'options' }
PCRE2 class >> disableRecurseloopCheck [
	"Only useful in rare cases; use with care"

	<pcre2Option: #( match substitute )>
	^ 16r00040000
]

{ #category : 'options' }
PCRE2 class >> dollarEndOnly [
	"$ not to match newline at end
	Affects: jit_compile, match, dfa_match"

	<pcre2Option: #( compile )>
	^ 16r00000010
]

{ #category : 'options' }
PCRE2 class >> dotAll [
	". matches anything including NL"

	<pcre2Option: #( compile )>
	^ 16r00000020
]

{ #category : 'options' }
PCRE2 class >> dupNames [
	"Allow duplicate names for subpatterns"

	<pcre2Option: #( compile )>
	^ 16r00000040
]

{ #category : 'options' }
PCRE2 class >> endAnchored [
	"Pattern can match only at end of subject"

	<pcre2Option: #( compile match dfa_match )>
	^ 16r20000000
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
PCRE2 class >> errorUnset [
	"The requested field is not set"

	^ -55
]

{ #category : 'options' }
PCRE2 class >> extended [
	"Ignore white space and # comments"

	<pcre2Option: #( compile )>
	^ 16r00000080
]

{ #category : 'options' }
PCRE2 class >> extendedMore [
	"Perl's /xx feature (https://perldoc.perl.org/perlre#%2Fx-and-%2Fxx)"

	<pcre2Option: #( compile )>
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
PCRE2 class >> firstLine [
	"Force matching to be before newline
	Affects: jit_compile, match, dfa_match"

	<pcre2Option: #( compile )>
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

{ #category : 'class initialization' }
PCRE2 class >> initialize [

	errorCodeTable := Dictionary newFrom: {
	"match errors; (-1 -> NOMATCH) and (-2 -> PARTIAL) are handled, so excluded here"
	(-67 -> 'INTERNAL ERROR: invalid substring offset').
	(-66 -> 'PCRE2_MATCH_INVALID_UTF is not supported for DFA matching').
	(-65 -> 'internal error - duplicate substitution match').
	(-64 -> 'invalid syntax').
	(-63 -> 'heap limit exceeded').
	(-62 -> 'bad serialized data').
	(-61 -> 'too many replacements (more than INT_MAX)').
	(-60 -> 'match with end before start or start moved backwards is not supported').
	(-59 -> 'bad substitution in replacement string').
	(-58 -> 'expected closing curly bracket in replacement string').
	(-57 -> 'bad escape sequence in replacement string').
	(-56 -> 'offset limit set without PCRE2_USE_OFFSET_LIMIT').
	(-55 -> 'requested value is not set').
	(-54 -> 'requested value is not available').
	(-53 -> 'matching depth limit exceeded').
	(-52 -> 'nested recursion at the same subject position').
	(-51 -> 'NULL argument passed with non-zero length').
	(-50 -> 'non-unique substring name').
	(-49 -> 'unknown substring').
	(-48 -> 'no more memory').
	(-47 -> 'match limit exceeded').
	(-46 -> 'JIT stack limit reached').
	(-45 -> 'bad JIT option').
	(-44 -> 'internal error - pattern overwritten?').
	(-43 -> 'workspace size exceeded in DFA matching').
	(-42 -> 'pattern contains an item that is not supported for DFA matching').
	(-41 -> 'function is not supported for DFA matching').
	(-40 -> 'backreference condition or recursion test is not supported for DFA matching').
	(-39 -> 'too much recursion for DFA matching').
	(-38 -> 'invalid data in workspace for DFA restart').
	(-37 -> 'callout error code').
	(-36 -> 'bad offset into UTF string').
	(-35 -> 'invalid replacement string').
	(-34 -> 'bad option value').
	(-33 -> 'bad offset value').
	(-32 -> 'pattern compiled in wrong mode: 8/16/32-bit error').
	(-31 -> 'magic number missing').
	(-30 -> 'patterns do not all use the same character tables').
	(-29 -> 'bad data value').
	(-28 -> 'UTF-32 error: code points greater than 0x10ffff are not defined').
	(-27 -> 'UTF-32 error: code points 0xd800-0xdfff are not defined').
	(-26 -> 'UTF-16 error: isolated low surrogate').
	(-25 -> 'UTF-16 error: invalid low surrogate').
	(-24 -> 'UTF-16 error: missing low surrogate at end').
	(-23 -> 'UTF-8 error: illegal byte (0xfe or 0xff)').
	(-22 -> 'UTF-8 error: isolated byte with 0x80 bit set').
	(-21 -> 'UTF-8 error: overlong 6-byte sequence').
	(-20 -> 'UTF-8 error: overlong 5-byte sequence').
	(-19 -> 'UTF-8 error: overlong 4-byte sequence').
	(-18 -> 'UTF-8 error: overlong 3-byte sequence').
	(-17 -> 'UTF-8 error: overlong 2-byte sequence').
	(-16 -> 'UTF-8 error: code points 0xd800-0xdfff are not defined').
	(-15 -> 'UTF-8 error: code points greater than 0x10ffff are not defined').
	(-14 -> 'UTF-8 error: 6-byte character is not allowed (RFC 3629)').
	(-13 -> 'UTF-8 error: 5-byte character is not allowed (RFC 3629)').
	(-12 -> 'UTF-8 error: byte 6 top bits not 0x80').
	(-11 -> 'UTF-8 error: byte 5 top bits not 0x80').
	(-10 -> 'UTF-8 error: byte 4 top bits not 0x80').
	(-9 -> 'UTF-8 error: byte 3 top bits not 0x80').
	(-8 -> 'UTF-8 error: byte 2 top bits not 0x80').
	(-7 -> 'UTF-8 error: 5 bytes missing at end').
	(-6 -> 'UTF-8 error: 4 bytes missing at end').
	(-5 -> 'UTF-8 error: 3 bytes missing at end').
	(-4 -> 'UTF-8 error: 2 bytes missing at end').
	(-3 -> 'UTF-8 error: 1 byte missing at end').
	"compile errors"
	(100 -> 'no error').
	(101 -> '\ at end of pattern').
	(102 -> '\c at end of pattern').
	(103 -> 'unrecognized character follows \').
	(104 -> 'numbers out of order in {} quantifier').
	(105 -> 'number too big in {} quantifier').
	(106 -> 'missing terminating ] for character class').
	(107 -> 'escape sequence is invalid in character class').
	(108 -> 'range out of order in character class').
	(109 -> 'quantifier does not follow a repeatable item').
	(110 -> 'internal error: unexpected repeat').
	(111 -> 'unrecognized character after (? or (?-').
	(112 -> 'POSIX named classes are supported only within a class').
	(113 -> 'POSIX collating elements are not supported').
	(114 -> 'missing closing parenthesis').
	(115 -> 'reference to non-existent subpattern').
	(116 -> 'pattern passed as NULL with non-zero length').
	(117 -> 'unrecognised compile-time option bit(s)').
	(118 -> 'missing ) after (?# comment').
	(119 -> 'parentheses are too deeply nested').
	(120 -> 'regular expression is too large').
	(121 -> 'failed to allocate heap memory').
	(122 -> 'unmatched closing parenthesis').
	(123 -> 'internal error: code overflow').
	(124 -> 'missing closing parenthesis for condition').
	(125 -> 'length of lookbehind assertion is not limited').
	(126 -> 'a relative value of zero is not allowed').
	(127 -> 'conditional subpattern contains more than two branches').
	(128 -> 'assertion expected after (?( or (?(?C)').
	(129 -> 'digit expected after (?+ or (?-').
	(130 -> 'unknown POSIX class name').
	(131 -> 'internal error in pcre2_study(): should not occur').
	(132 -> 'this version of PCRE2 does not have Unicode support').
	(133 -> 'parentheses are too deeply nested (stack check)').
	(134 -> 'character code point value in \x{} or \o{} is too large').
	(135 -> 'lookbehind is too complicated').
	(136 -> '\C is not allowed in a lookbehind assertion in UTF-8 mode').
	(137 -> 'PCRE2 does not support \F, \L, \l, \N{name}, \U, or \u').
	(138 -> 'number after (?C is greater than 255').
	(139 -> 'closing parenthesis for (?C expected').
	(140 -> 'invalid escape sequence in (*VERB) name').
	(141 -> 'unrecognized character after (?P').
	(142 -> 'syntax error in subpattern name (missing terminator?)').
	(143 -> 'two named subpatterns have the same name (PCRE2_DUPNAMES not set)').
	(144 -> 'subpattern name must start with a non-digit').
	(145 ->  'this version of PCRE2 does not have support for \P, \p, or \X').
	(146 -> 'malformed \P or \p sequence').
	(147 -> 'unknown property after \P or \p').
	(148 -> 'subpattern name is too long (maximum 128 code units)').
	(149 -> 'too many named subpatterns (maximum 10000)').
	(150 -> 'invalid range in character class').
	(151 -> 'octal value is greater than \377 in 8-bit non-UTF-8 mode').
	(152 -> 'internal error: overran compiling workspace').
	(153 -> 'internal error: previously-checked referenced subpattern not found').
	(154 -> 'DEFINE subpattern contains more than one branch').
	(155 -> 'missing opening brace after \o').
	(156 -> 'internal error: unknown newline setting').
	(157 -> '\g is not followed by a braced, angle-bracketed, or quoted name/number or by a plain number').
	(158 -> '(?R (recursive pattern call) must be followed by a closing parenthesis').
	(159 -> 'obsolete error (should not occur)').
	(160 -> '(*VERB) not recognized or malformed').
	(161 -> 'subpattern number is too big').
	(162 -> 'subpattern name expected').
	(163 -> 'internal error: parsed pattern overflow').
	(164 -> 'non-octal character in \o{} (closing brace missing?)').
	(165 -> 'different names for subpatterns of the same number are not allowed').
	(166 -> '(*MARK) must have an argument').
	(167 -> 'non-hex character in \x{} (closing brace missing?)').
	(168 -> '\c must be followed by a printable ASCII character').
	(169 -> '\k is not followed by a braced, angle-bracketed, or quoted name').
	(170 -> 'internal error: unknown meta code in check_lookbehinds()').
	(171 -> '\N is not supported in a class').
	(172 -> 'callout string is too long').
	(173 -> 'disallowed Unicode code point (>= 0xd800 && <= 0xdfff)').
	(174 -> 'using UTF is disabled by the application').
	(175 -> 'using UCP is disabled by the application').
	(176 ->  'name is too long in (*MARK), (*PRUNE), (*SKIP), or (*THEN)').
	(177 ->  'character code point value in \u.... sequence is too large').
	(178 -> 'digits missing in \x{} or \o{} or \N{U+}').
	(179 -> 'syntax error or number too big in (?(VERSION condition').
	(180 -> 'internal error: unknown opcode in auto_possessify()').
	(181 -> 'missing terminating delimiter for callout with string argument').
	(182 -> 'unrecognized string delimiter follows (?C').
	(183 -> 'using \C is disabled by the application').
	(184 -> '(?| and/or (?J: or (?x: parentheses are too deeply nested').
	(185 -> 'using \C is disabled in this PCRE2 library').
	(186 -> 'regular expression is too complicated').
	(187 -> 'lookbehind assertion is too long').
	(188 -> 'pattern string is longer than the limit set by the application').
	(189 -> 'internal error: unknown code in parsed pattern').
	(190 -> 'internal error: bad code value in parsed_skip()').
	(191 -> 'PCRE2_EXTRA_ALLOW_SURROGATE_ESCAPES is not allowed in UTF-16 mode').
	(192 -> 'invalid option bits with PCRE2_LITERAL').
	(193 -> '\N{U+dddd} is supported only in Unicode (UTF) mode').
	(194 -> 'invalid hyphen in option setting').
	(195 -> '(*alpha_assertion) not recognized').
	(196 -> 'script runs require Unicode support, which this version of PCRE2 does not have').
	(197 -> 'too many capturing groups (maximum 65535)').
	(198 -> 'atomic assertion expected after (?( or (?(?C)').
	(199 -> '\K is not allowed in lookarounds (but see PCRE2_EXTRA_ALLOW_LOOKAROUND_BSK)').
	(200 -> 'branch too long in variable-length lookbehind assertion').
	(201 -> 'compiled pattern would be longer than the limit set by the application') }

]

{ #category : 'options' }
PCRE2 class >> jitComplete [
	"Compile code for full matching"

	<pcre2Option: #( jit_compile )>
	^ 16r00000001
]

{ #category : 'options' }
PCRE2 class >> jitPartialHard [
	"Compile code for hard partial matching"

	<pcre2Option: #( jit_compile )>
	^ 16r00000004
]

{ #category : 'options' }
PCRE2 class >> jitPartialSoft [
	"Compile code for soft partial matching"

	<pcre2Option: #( jit_compile )>
	^ 16r00000002
]

{ #category : 'options' }
PCRE2 class >> literal [
	"Pattern characters are all literal"

	<pcre2Option: #( compile )>
	^ 16r02000000
]

{ #category : 'options' }
PCRE2 class >> matchInvalidUTF [
	"Enable support for matching invalid UTF
	Affects: jit_compile, match, dfa_match"

	<pcre2Option: #( compile )>
	^ 16r04000000
]

{ #category : 'options' }
PCRE2 class >> matchUnsetBackref [
	"Match unset backreferences
	Affects: compile, jit_compile, match"

	<pcre2Option: #( compile )>
	^ 16r00000200
]

{ #category : 'options' }
PCRE2 class >> multiline [
	"^ and $ match newlines within data"

	<pcre2Option: #( compile )>
	^ 16r00000400
]

{ #category : 'options' }
PCRE2 class >> neverBackslashC [
	"Lock out the use of \C in patterns"

	<pcre2Option: #( compile )>
	^ 16r00100000
]

{ #category : 'options' }
PCRE2 class >> neverUCP [
	"Lock out PCRE2_UCP, e.g. via (*UCP)"

	<pcre2Option: #( compile )>
	^ 16r00000800
]

{ #category : 'options' }
PCRE2 class >> neverUTF [
	"Lock out PCRE2_UTF, e.g. via (*UTF)"

	<pcre2Option: #( compile )>
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

	<pcre2Option: #( compile )>
	^ 16r00002000
]

{ #category : 'options' }
PCRE2 class >> noAutoPossess [
	"Disable auto-possessification"

	<pcre2Option: #( compile )>
	^ 16r00004000
]

{ #category : 'options' }
PCRE2 class >> noDotstarAnchor [
	"Disable automatic anchoring for .*"

	<pcre2Option: #( compile )>
	^ 16r00008000
]

{ #category : 'options' }
PCRE2 class >> noJIT [
	"Do not use JIT matching"

	<pcre2Option: #( match jit_match substitute )>
	^ 16r00002000
]

{ #category : 'options' }
PCRE2 class >> noStartOptimize [
	"Disable match-time start optimizations
	Affects: jit_compile, match, dfa_match"

	<pcre2Option: #( compile )>
	^ 16r00010000
]

{ #category : 'options' }
PCRE2 class >> noUTFCheck [
	"Do not check the subject for UTF validity"

	<pcre2Option: #( compile match dfa_match )>
	^ 16r40000000
]

{ #category : 'options' }
PCRE2 class >> notBOL [
	"Subject string is not the beginning of a line"

	<pcre2Option: #( match dfa_match jit_match )>
	^ 16r00000001
]

{ #category : 'options' }
PCRE2 class >> notEOL [
	"Subject string is not the end of a line"

	<pcre2Option: #( match dfa_match jit_match )>
	^ 16r00000002
]

{ #category : 'options' }
PCRE2 class >> notEmpty [
	"An empty string is not a valid match"

	<pcre2Option: #( match dfa_match jit_match )>
	^ 16r00000004
]

{ #category : 'options' }
PCRE2 class >> notEmptyAtStart [
	"An empty string at the start of the subject is not a valid match"

	<pcre2Option: #( match dfa_match jit_match )>
	^ 16r00000008
]

{ #category : 'documentation' }
PCRE2 class >> options: options includes: query [
	"Multiple options can be checked at once, returns true if all are set"

	^ (options bitAnd: query) == query
]

{ #category : 'documentation' }
PCRE2 class >> optionsFor: function [
	"Returns the methods that define a valid option for the given function.
	Expects a symbol among #( compile jit_compile match jit_match dfa_match substitute )."

	^ self class methods select: [ :option |
		  option pragmas anySatisfy: [ :pragma |
			  pragma selector = #pcre2Option: and: [
				  pragma arguments first includes: function ] ] ]
]

{ #category : 'options' }
PCRE2 class >> partialHard [
	"Return PCRE2_ERROR_PARTIAL for a partial match even if there is a full match"

	<pcre2Option: #( match dfa_match jit_match )>
	^ 16r00000020
]

{ #category : 'options' }
PCRE2 class >> partialSoft [
	"Return PCRE2_ERROR_PARTIAL for a partial match if no full matches are found"

	<pcre2Option: #( match dfa_match jit_match )>
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
				forFun at: bit ifPresent: [ :method |
					result
						at: fun
						ifPresent: [ :methods | methods add: method ]
						ifAbsentPut: [ OrderedCollection with: method ] ] ] ].
		bit := bit * 2 ].
	^ result
]

{ #category : 'documentation' }
PCRE2 class >> readOptions: anInteger for: function [
	"Convenience method for finding which options are declared by the integer for the given function.
	Expects a symbol among #( compile jit_compile match jit_match dfa_match substitute convert )."

	^ (self readOptions: anInteger) at: function ifAbsent: [ #(  ) ]
]

{ #category : 'options' }
PCRE2 class >> substituteExtended [
	"Do extended replacement processing"

	<pcre2Option: #( substitute )>
	^ 16r00000200
]

{ #category : 'options' }
PCRE2 class >> substituteGlobal [
	"Replace all occurrences in the subject"

	<pcre2Option: #( substitute )>
	^ 16r00000100
]

{ #category : 'options' }
PCRE2 class >> substituteLiteral [
	"The replacement string is literal"

	<pcre2Option: #( substitute )>
	^ 16r00008000
]

{ #category : 'options' }
PCRE2 class >> substituteMatched [
	"Use pre-existing match data for 1st match"

	<pcre2Option: #( substitute )>
	^ 16r00010000
]

{ #category : 'options' }
PCRE2 class >> substituteOverflowLength [
	"If overflow, compute needed length"

	<pcre2Option: #( substitute )>
	^ 16r00001000
]

{ #category : 'options' }
PCRE2 class >> substituteReplacementOnly [
	"Return only replacement string(s)"

	<pcre2Option: #( substitute )>
	^ 16r00020000
]

{ #category : 'options' }
PCRE2 class >> substituteUnknownUnset [
	"Treat unknown group as unset"

	<pcre2Option: #( substitute )>
	^ 16r00000800
]

{ #category : 'options' }
PCRE2 class >> substituteUnsetEmpty [
	"Simple unset insert = empty string"

	<pcre2Option: #( substitute )>
	^ 16r00000400
]

{ #category : 'error handling' }
PCRE2 class >> translateErrorCode: errorCode [

	^ errorCodeTable
		  at: errorCode
		  ifAbsent: [ 'unknown error code: ' , errorCode asString ]
]

{ #category : 'options' }
PCRE2 class >> ucp [
	"Use Unicode properties for \d, \w, etc
	Affects: compile, jit_compile, match, dfa_match"

	<pcre2Option: #( compile )>
	^ 16r00020000
]

{ #category : 'options' }
PCRE2 class >> ungreedy [
	"Invert greediness of quantifiers"

	<pcre2Option: #( compile )>
	^ 16r00040000
]

{ #category : 'options' }
PCRE2 class >> useOffsetLimit [
	"Enable offset limit for unanchored matching
	Affects: jit_compile, match, dfa_match"

	<pcre2Option: #( compile )>
	^ 16r00800000
]

{ #category : 'options' }
PCRE2 class >> utf [
	"Treat pattern and subjects as UTF strings
	Affects: compile, jit_compile, match, dfa_match"

	<pcre2Option: #( compile )>
	^ 16r00080000
]

{ #category : 'constants' }
PCRE2 class >> zeroTerminated [
	"Some methods can use this value as a string upper bound argument to use a terminating null character instead of an index.
	The value corresponds to the C code: `~(size_t)0`, which represents the largest fixed-size integer.
	Supported by match() and substitute().
	Not supported by jit_match()."

	^ (1 bitShift: ExternalAddress wordSize * 8) - 1
]
