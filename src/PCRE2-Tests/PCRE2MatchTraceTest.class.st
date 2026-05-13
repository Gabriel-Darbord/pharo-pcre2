"
I cover opt-in PCRE2 match tracing.

Tracing compiles a temporary matcher with automatic callouts and no JIT so debugger tools can inspect runtime callout events without changing the normal matcher used by application code.
"
Class {
	#name : 'PCRE2MatchTraceTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
PCRE2MatchTraceTest >> testTraceMatchCollectsAutomaticCalloutEvents [

	| regex trace |
	regex := 'ab' asPerlCompatibleRegex.
	trace := regex traceMatch: 'ab'.

	self assert: trace isMatch.
	self assert: trace isFullMatch.
	self assert: trace matchedString equals: 'ab'.
	self assert: trace resultCode > 0.
	self assert: trace events notEmpty.
	self assert: trace calloutSites notEmpty.
	self assert:
		(trace calloutSites allSatisfy: [ :site | site number = 255 ]).
	self assert:
		(trace events anySatisfy: [ :event | event number = 255 ])
]

{ #category : 'tests' }
PCRE2MatchTraceTest >> testTraceMatchDoesNotMutateOriginalMatcher [

	| options regex trace |
	regex := 'a' asPerlCompatibleRegex.
	options := regex options.
	self assert: regex calloutSites isEmpty.

	trace := regex traceMatch: 'a'.

	self assert: trace isMatch.
	self assert: regex options equals: options.
	self assert: regex calloutSites isEmpty.
	self assert: (regex matches: 'a')
]

{ #category : 'tests' }
PCRE2MatchTraceTest >> testTraceMatchPreservesCompileContext [

	| compiler regex subject trace |
	compiler := PCRE2Compiler new.
	compiler context useBSRAnyCRLF.
	regex := compiler compile: '\R'.
	subject := String with: (Character value: 16r85).

	trace := regex traceMatch: subject.

	self deny: (regex matches: subject).
	self deny: trace isMatch
]

{ #category : 'tests' }
PCRE2MatchTraceTest >> testTraceMatchPreservesCompileOptions [

	| regex trace |
	regex := 'a' asPerlCompatibleRegexWithOptions: PCRE2 caseless.

	trace := regex traceMatch: 'A'.

	self assert: trace isMatch.
	self assert: trace matchedString equals: 'A'
]

{ #category : 'tests' }
PCRE2MatchTraceTest >> testTraceMatchReportsNoMatchWithEvents [

	| trace |
	trace := 'ab' asPerlCompatibleRegex traceMatch: 'a'.

	self deny: trace isMatch.
	self assert: trace match isNil.
	self assert: trace resultCode equals: PCRE2 errorNoMatch.
	self assert: trace events notEmpty
]

{ #category : 'tests' }
PCRE2MatchTraceTest >> testTraceTranslatesUTF8EventPositions [

	| event trace |
	trace := '(?C1)é(?C2)a' asPerlCompatibleRegex traceMatch: 'éa'.
	event := trace events detect: [ :each | each number = 2 ].

	self assert: event currentPosition equals: 2.
	self
		assert:
		(trace subjectCharacterPositionForByteOffset: event currentPosition)
		equals: 2.
	self assert: (trace subjectCharacterPositionAtEvent: event) equals: 2.
	self
		assert: (trace subjectCharacterRangeFromStartOffset: 0 endOffset: 2)
		equals: (1 to: 1)
]
