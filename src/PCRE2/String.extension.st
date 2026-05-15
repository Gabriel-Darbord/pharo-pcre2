Extension { #name : 'String' }

{ #category : '*PCRE2' }
String >> allPerlCompatibleRegexMatches: regexString [
	"Answer all substrings of myself matching regexString as a Perl-compatible regular expression."

	^ regexString asPerlCompatibleRegex matchesIn: self
]

{ #category : '*PCRE2' }
String >> allRangesOfPerlCompatibleRegexMatches: regexString [
	"Answer 1-based Pharo character ranges for all matches of regexString."

	^ regexString asPerlCompatibleRegex matchingRangesIn: self
]

{ #category : '*PCRE2' }
String >> asPCRE2UTF32Input [
	"Prepare myself as reusable UTF-32 input for PCRE2 matching."

	^ PCRE2UTF32Input fromString: self
]

{ #category : '*PCRE2' }
String >> asPCRE2UTF8Input [
	"Prepare myself as reusable UTF-8 input for PCRE2 matching."

	^ PCRE2UTF8Input fromString: self
]

{ #category : '*PCRE2' }
String >> asPerlCompatibleRegex [
	"Compile myself as a Perl-compatible regular expression matcher with PCRE2's default compiler options. May raise PCRE2CompileError."

	^ PCRE2Compiler default compile: self
]

{ #category : '*PCRE2' }
String >> asPerlCompatibleRegexIgnoringCase [
	"Compile myself as a Perl-compatible regular expression matcher using PCRE2's caseless option. May raise PCRE2CompileError."

	^ PCRE2Compiler new
		  addOptions: PCRE2 caseless;
		  compile: self
]

{ #category : '*PCRE2' }
String >> asPerlCompatibleRegexWithOptions: compileOptions [
	"Compile myself as a Perl-compatible regular expression matcher using compileOptions in addition to PCRE2's default UTF option. Use PCRE2Compiler directly to bypass defaults."

	^ PCRE2Compiler new
		  addOptions: compileOptions;
		  compile: self
]

{ #category : '*PCRE2' }
String >> copyWithPerlCompatibleRegex: regexString matchesReplacedWith: replacementString [
	"Answer a copy of myself with each regexString match replaced by replacementString."

	^ regexString asPerlCompatibleRegex
		  copy: self
		  replacingMatchesWith: replacementString
]

{ #category : '*PCRE2' }
String >> copyWithPerlCompatibleRegex: regexString matchesTranslatedUsing: aBlock [
	"Answer a copy of myself with each regexString match replaced by aBlock's String answer."

	^ regexString asPerlCompatibleRegex
		  copy: self
		  translatingMatchesUsing: aBlock
]

{ #category : '*PCRE2' }
String >> matchesPerlCompatibleRegex: regexString [
	"Answer whether I entirely match regexString as a Perl-compatible regular expression."

	^ regexString asPerlCompatibleRegex matches: self
]

{ #category : '*PCRE2' }
String >> matchesPerlCompatibleRegexIgnoringCase: regexString [
	"Answer whether I entirely match regexString as a case-insensitive Perl-compatible regular expression."

	^ regexString asPerlCompatibleRegexIgnoringCase matches: self
]

{ #category : '*PCRE2' }
String >> perlCompatibleRegex: regexString matchesCollect: aBlock [
	"Evaluate aBlock for each regexString match and answer the collected results."

	^ regexString asPerlCompatibleRegex matchesIn: self collect: aBlock
]

{ #category : '*PCRE2' }
String >> perlCompatibleRegex: regexString matchesDo: aBlock [
	"Evaluate aBlock for each regexString match in myself."

	regexString asPerlCompatibleRegex matchesIn: self do: aBlock
]

{ #category : '*PCRE2' }
String >> prefixMatchesPerlCompatibleRegex: regexString [
	"Answer whether my prefix matches regexString as a Perl-compatible regular expression."

	^ regexString asPerlCompatibleRegex matchesPrefix: self
]

{ #category : '*PCRE2' }
String >> prefixMatchesPerlCompatibleRegexIgnoringCase: regexString [
	"Answer whether my prefix matches regexString as a case-insensitive Perl-compatible regular expression."

	^ regexString asPerlCompatibleRegexIgnoringCase matchesPrefix: self
]
