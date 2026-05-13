"
Tests for PCRE2 substitution conveniences.

These tests focus on the Pharo-level API layered over pcre2_substitute_8: global substitution, literal replacements, replacement-only results, unset/unknown capture handling, precomputed match data, prepared UTF-8 inputs, and output buffer growth.
"
Class {
	#name : 'PCRE2SubstitutionTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
PCRE2SubstitutionTest >> testLiteralReplacementDoesNotExpandCaptures [

	| regex |
	regex := '(\d+)' asPerlCompatibleRegex.

	self assert: (regex substitute: 'a12' with: '[$1]') equals: 'a[12]'.
	self
		assert: (regex substitute: 'a12' withLiteral: '[$1]')
		equals: 'a[$1]'
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testReplacementOnly [

	| regex |
	regex := '\d+' asPerlCompatibleRegex.

	self
		assert: (regex substituteReplacementsOnly: 'a1 b22' with: '<$0>')
		equals: '<1>'.
	self
		assert:
		(regex substituteAllReplacementsOnly: 'a1 b22 c333' with: '<$0>')
		equals: '<1><22><333>'
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testSubstituteAllAcceptsReusableUTF8InputAndReplacement [

	| input regex replacement |
	regex := 'é' asPerlCompatibleRegex.
	input := 'café café' asPCRE2UTF8Input.
	replacement := 'e' asPCRE2UTF8Input.

	self
		assert: (regex substituteAll: input with: replacement)
		equals: 'cafe cafe'
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testSubstituteAllConvenienceVariants [

	| regex |
	regex := 'a' asPerlCompatibleRegex.
	self
		assert: (regex substituteAll: 'a a' withLiteral: '$0')
		equals: '$0 $0'.

	regex := 'b' asPerlCompatibleRegex.
	self
		assert:
		(regex substituteAll: 'b b' withUnknownCapturesEmpty: '<$1>')
		equals: '<> <>'.

	regex := '(a)?b' asPerlCompatibleRegex.
	self
		assert: (regex substituteAll: 'b ab' withUnsetCapturesEmpty: '<$1>')
		equals: '<> <a>'
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testSubstituteAllDoesNotMutateMatcherOptions [

	| regex |
	regex := 'a' asPerlCompatibleRegex.

	self assert: (regex substituteAll: 'aba' with: 'x') equals: 'xbx'.
	self assert: (regex substitute: 'aba' with: 'x') equals: 'xba'
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testSubstituteAutomaticallyHandlesLargeOutput [

	| regex replacement |
	regex := 'a' asPerlCompatibleRegex.
	replacement := String new: 5000 withAll: $x.

	self
		assert: (regex substitute: 'a' with: replacement) size
		equals: replacement size
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testSubstituteUsingExistingMatch [

	| input match regex |
	regex := '(\w+)' asPerlCompatibleRegex.
	input := 'one two' asPCRE2UTF8Input.
	match := regex findMatch: input.

	self
		assert: (regex substituteUsingMatch: match with: '[$0]')
		equals: '[one] two'.
	self
		assert: (regex
				 substituteUsingMatch: match
				 with: '[$0]'
				 options: PCRE2 substituteGlobal)
		equals: '[one] [two]'
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testSubstituteUsingMatchRejectsUnsuitableMatchData [

	| regex input match partialMatch |
	regex := 'a' asPerlCompatibleRegex.

	self
		should: [ regex substituteUsingMatch: nil with: 'x' ]
		raise: PCRE2Error
		withExceptionDo: [ :error |
			self assert:
				(error messageText includesSubstring: 'external PCRE2 match data') ].

	match := regex findMatch: 'a'.
	match bePersistent.
	self
		should: [ regex substituteUsingMatch: match with: 'x' ]
		raise: PCRE2Error
		withExceptionDo: [ :error |
			self assert:
				(error messageText includesSubstring: 'Persistent match data') ].

	input := 'a' asPCRE2UTF8Input.
	match := regex newMatchData.
	regex
		matchBytes: input bytes
		from: 1
		to: input size
		into: match.
	self
		should: [ regex substituteUsingMatch: match with: 'x' ]
		raise: PCRE2Error
		withExceptionDo: [ :error |
			self assert:
				(error messageText includesSubstring: 'remember its subject bytes') ].

	partialMatch := 'abc' asPerlCompatibleRegex findPartialMatch: 'ab'.
	self
		should: [
			'abc' asPerlCompatibleRegex
				substituteUsingMatch: partialMatch
				with: 'x' ]
		raise: PCRE2Error
		withExceptionDo: [ :error |
			self assert:
				(error messageText includesSubstring: 'complete match') ]
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testUnknownCapturesEmpty [

	| regex |
	regex := 'a' asPerlCompatibleRegex.

	self
		should: [ regex substitute: 'a' with: '<$1>' ]
		raise: PCRE2MatchError.
	self
		assert: (regex substitute: 'a' withUnknownCapturesEmpty: '<$1>')
		equals: '<>'
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testUnsetCapturesEmpty [

	| regex |
	regex := '(a)?b' asPerlCompatibleRegex.

	self
		should: [ regex substitute: 'b' with: '<$1>' ]
		raise: PCRE2MatchError.
	self
		assert: (regex substitute: 'b' withUnsetCapturesEmpty: '<$1>')
		equals: '<>'
]
