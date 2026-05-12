"
Tests for the `String` convenience API provided by PCRE2.

These methods mirror the shape of Pharo's Regex-Core `String` messages while spelling out Perl-compatible regular expressions explicitly.
"
Class {
	#name : 'PCRE2StringTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
PCRE2StringTest >> testCompileMethods [

	self assert: ('a' asPerlCompatibleRegex matches: 'a').
	self assert: ('a' asPerlCompatibleRegexIgnoringCase matches: 'A').
	self assert:
		(('.' asPerlCompatibleRegexWithOptions: PCRE2 dotAll) matches:
			 String cr)
]

{ #category : 'tests' }
PCRE2StringTest >> testCopyConveniences [

	self
		assert:
		('abc123'
			 copyWithPerlCompatibleRegex: '\d+'
			 matchesReplacedWith: '#')
		equals: 'abc#'.
	self
		assert: ('abc123'
				 copyWithPerlCompatibleRegex: '\d+'
				 matchesTranslatedUsing: [ :match | '[' , match , ']' ])
		equals: 'abc[123]'.
	self
		assert: ('1 café'
				 copyWithPerlCompatibleRegex: '\p{L}+'
				 matchesTranslatedUsing: [ :match | match repeat: 2 ])
		equals: '1 cafécafé'
]

{ #category : 'tests' }
PCRE2StringTest >> testEnumerationConveniences [

	| collected seen |
	self
		assert:
		('1 café 23 λx' allPerlCompatibleRegexMatches: '\p{L}+') asArray
		equals: #( 'café' 'λx' ).
	self
		assert:
			('1 café 23 λx' allRangesOfPerlCompatibleRegexMatches: '\p{L}+')
				asArray
		equals: {
				(3 to: 6).
				(11 to: 12) }.

	collected := 'a1 b2'
		             perlCompatibleRegex: '\d'
		             matchesCollect: [ :match | match asInteger + 1 ].
	self assert: collected asArray equals: #( 2 3 ).

	seen := OrderedCollection new.
	'a1 b2'
		perlCompatibleRegex: '\w+'
		matchesDo: [ :match | seen add: match ].
	self assert: seen asArray equals: #( 'a1' 'b2' )
]

{ #category : 'tests' }
PCRE2StringTest >> testMatchingConveniences [

	self assert: ('abc123' matchesPerlCompatibleRegex: '\w+\d+').
	self deny: ('abc123' matchesPerlCompatibleRegex: '\d+').
	self assert:
		('ABC123' matchesPerlCompatibleRegexIgnoringCase: 'abc\d+').
	self assert: ('abc123' prefixMatchesPerlCompatibleRegex: '\w+').
	self assert:
		('ABC123' prefixMatchesPerlCompatibleRegexIgnoringCase: 'abc')
]
