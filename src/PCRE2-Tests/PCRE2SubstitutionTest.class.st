"
Tests for PCRE2 substitution conveniences.

These tests focus on the Pharo-level API layered over pcre2_substitute_8: global substitution, literal replacements, replacement-only results, unset/unknown capture handling, precomputed match data, prepared UTF-8 inputs, output buffer growth, and substitution callouts.
"
Class {
	#name : 'PCRE2SubstitutionTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'private' }
PCRE2SubstitutionTest >> skipUnlessSubstitutionCalloutsSupported [

	LibPCRE2 supportsSubstitutionCallouts ifFalse: [ ^ true ].
	^ false
]

{ #category : 'private' }
PCRE2SubstitutionTest >> skipUnlessSubstitutionCaseCalloutsSupported [

	LibPCRE2 supportsSubstitutionCaseCallouts ifFalse: [ ^ true ].
	^ false
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testLiteralReplacementDoesNotExpandCaptures [

	| regex |
	regex := '(\d+)' asPerlCompatibleRegex.

	self assert: (regex substitute: 'a12' with: '[$1]') equals: 'a[12]'.
	self assert: (regex substitute: 'a12' withLiteral: '[$1]') equals: 'a[$1]'
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testReplacementOnly [

	| regex |
	regex := '\d+' asPerlCompatibleRegex.

	self assert: (regex substituteReplacementsOnly: 'a1 b22' with: '<$0>') equals: '<1>'.
	self assert: (regex substituteAllReplacementsOnly: 'a1 b22 c333' with: '<$0>') equals: '<1><22><333>'
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testSubstituteAllAcceptsReusableUTF8InputAndReplacement [

	| input regex replacement |
	regex := 'é' asPerlCompatibleRegex.
	input := 'café café' asPCRE2UTF8Input.
	replacement := 'e' asPCRE2UTF8Input.

	self assert: (regex substituteAll: input with: replacement) equals: 'cafe cafe'
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testSubstituteAllConvenienceVariants [

	| regex |
	regex := 'a' asPerlCompatibleRegex.
	self assert: (regex substituteAll: 'a a' withLiteral: '$0') equals: '$0 $0'.

	regex := 'b' asPerlCompatibleRegex.
	self assert: (regex substituteAll: 'b b' withUnknownCapturesEmpty: '<$1>') equals: '<> <>'.

	regex := '(a)?b' asPerlCompatibleRegex.
	self assert: (regex substituteAll: 'b ab' withUnsetCapturesEmpty: '<$1>') equals: '<> <a>'
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

	self assert: (regex substitute: 'a' with: replacement) size equals: replacement size
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testSubstituteCalloutCanRejectAndContinue [

	| events regex result |
	self skipUnlessSubstitutionCalloutsSupported ifTrue: [ ^ self ].
	regex := '(\w+)' asPerlCompatibleRegex.
	events := OrderedCollection new.

	result := regex substituteAll: 'one two' with: '[$0]' calloutsDo: [ :event |
			          events add: event.
			          event substitutionCount = 1
				          ifTrue: [ PCRE2 substituteCalloutRejectAndContinue ]
				          ifFalse: [ PCRE2 substituteCalloutAccept ] ].

	self assert: result equals: 'one [two]'.
	self assert: events size equals: 2.
	self assert: events first matchedText equals: 'one'.
	self assert: events second matchedText equals: 'two'
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testSubstituteCalloutCanRejectAndStop [

	| events regex result |
	self skipUnlessSubstitutionCalloutsSupported ifTrue: [ ^ self ].
	regex := '(\w+)' asPerlCompatibleRegex.
	events := OrderedCollection new.

	result := regex substituteAll: 'one two' with: '[$0]' calloutsDo: [ :event |
			          events add: event.
			          PCRE2 substituteCalloutRejectAndStop ].

	self assert: result equals: 'one two'.
	self assert: events size equals: 1.
	self assert: events first matchedText equals: 'one'.
	self assert: events first replacementText equals: '[one]'
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testSubstituteCalloutDecodesUTF8Text [

	| events regex result |
	self skipUnlessSubstitutionCalloutsSupported ifTrue: [ ^ self ].
	regex := 'é' asPerlCompatibleRegex.
	events := OrderedCollection new.

	result := regex substituteAll: 'café café' with: 'e$0' calloutsDo: [ :event |
			          events add: event.
			          PCRE2 substituteCalloutAccept ].

	self assert: result equals: 'cafeé cafeé'.
	self assert: events size equals: 2.
	self assert: events first matchedText equals: 'é'.
	self assert: events first replacementText equals: 'eé'.
	self assert: events first offsets equals: #( 3 5 ).
	self assert: events first outputOffsets equals: #( 3 6 ).
	self assert: events second matchedText equals: 'é'.
	self assert: events second replacementText equals: 'eé'
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testSubstituteCalloutDoesNotMutateReceiver [

	| calls regex |
	self skipUnlessSubstitutionCalloutsSupported ifTrue: [ ^ self ].
	regex := 'a' asPerlCompatibleRegex.
	calls := 0.

	self
		assert: (regex substitute: 'a' with: 'x' calloutsDo: [ :event |
					 calls := calls + 1.
					 PCRE2 substituteCalloutAccept ])
		equals: 'x'.
	self assert: calls equals: 1.
	self assert: (regex substitute: 'a' with: 'x') equals: 'x'.
	self assert: calls equals: 1
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testSubstituteCalloutHandlesLargeOutputRetry [

	| count regex replacement result |
	self skipUnlessSubstitutionCalloutsSupported ifTrue: [ ^ self ].
	regex := 'a' asPerlCompatibleRegex.
	replacement := String new: 5000 withAll: $x.
	count := 0.

	result := regex substitute: 'a' with: replacement calloutsDo: [ :event |
			          count := count + 1.
			          self assert: event replacementText size equals: replacement size.
			          PCRE2 substituteCalloutAccept ].

	self assert: result size equals: replacement size.
	self assert: count equals: 1
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testSubstituteCalloutReceivesProcessedReplacement [

	| events regex result |
	self skipUnlessSubstitutionCalloutsSupported ifTrue: [ ^ self ].
	regex := '(\w+)' asPerlCompatibleRegex.
	events := OrderedCollection new.

	result := regex substituteAll: 'one two' with: '[$0]' calloutsDo: [ :event |
			          events add: event.
			          PCRE2 substituteCalloutAccept ].

	self assert: result equals: '[one] [two]'.
	self assert: events size equals: 2.
	self assert: events first substitutionCount equals: 1.
	self assert: events first matchedText equals: 'one'.
	self assert: events first replacementText equals: '[one]'.
	self assert: events first offsets equals: #( 0 3 0 3 ).
	self assert: events first outputOffsets equals: #( 0 5 ).
	self assert: events second substitutionCount equals: 2.
	self assert: events second matchedText equals: 'two'.
	self assert: events second replacementText equals: '[two]'
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testSubstituteCaseCalloutCanGrowOutputAndRetry [

	| calls regex replacement result |
	self skipUnlessSubstitutionCaseCalloutsSupported ifTrue: [ ^ self ].
	regex := 'a' asPerlCompatibleRegex.
	replacement := String new: 5000 withAll: $x.
	calls := 0.

	result := regex
		          substitute: 'a'
		          with: '\U$0'
		          options: PCRE2 substituteExtended
		          caseCallout: [ :event |
				          calls := calls + 1.
				          replacement ].

	self assert: result equals: replacement.
	self assert: calls > 0
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testSubstituteCaseCalloutCanUseDefaultTransform [

	| events regex result |
	self skipUnlessSubstitutionCaseCalloutsSupported ifTrue: [ ^ self ].
	regex := '(\w+)' asPerlCompatibleRegex.
	events := OrderedCollection new.

	result := regex
		          substitute: 'one'
		          with: '\U$0'
		          options: PCRE2 substituteExtended
		          caseCallout: [ :event | events add: event ].

	self assert: result equals: 'ONE'.
	self assert: events size equals: 1.
	self assert: events first defaultTransformedText equals: 'ONE'
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testSubstituteCaseCalloutControlsExtendedCaseConversion [

	| events regex result |
	self skipUnlessSubstitutionCaseCalloutsSupported ifTrue: [ ^ self ].
	regex := '(\w+)' asPerlCompatibleRegex.
	events := OrderedCollection new.

	result := regex
		          substituteAll: 'one two'
		          with: '\U$0'
		          options: PCRE2 substituteExtended
		          caseCallout: [ :event |
				          events add: event.
				          event inputText reversed ].

	self assert: result equals: 'eno owt'.
	self assert: events size equals: 2.
	self assert: events first inputText equals: 'one'.
	self assert: events first caseName equals: #uppercase.
	self assert: events first codeUnitWidth equals: 8
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testSubstituteCaseCalloutNilSignalsReplaceCaseError [

	| regex |
	self skipUnlessSubstitutionCaseCalloutsSupported ifTrue: [ ^ self ].
	regex := 'a' asPerlCompatibleRegex.

	self
		should: [
				regex
					substitute: 'a'
					with: '\U$0'
					options: PCRE2 substituteExtended
					caseCallout: [ :event | nil ] ]
		raise: PCRE2MatchError
		withExceptionDo: [ :error | self assert: (error messageText includesSubstring: 'case transformation') ]
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testSubstituteUsingExistingMatch [

	| input match regex |
	regex := '(\w+)' asPerlCompatibleRegex.
	input := 'one two' asPCRE2UTF8Input.
	match := regex findMatch: input.

	self assert: (regex substituteUsingMatch: match with: '[$0]') equals: '[one] two'.
	self assert: (regex substituteUsingMatch: match with: '[$0]' options: PCRE2 substituteGlobal) equals: '[one] [two]'
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testSubstituteUsingMatchRejectsUnsuitableMatchData [

	| regex input match partialMatch |
	regex := 'a' asPerlCompatibleRegex.

	self
		should: [ regex substituteUsingMatch: nil with: 'x' ]
		raise: PCRE2Error
		withExceptionDo: [ :error | self assert: (error messageText includesSubstring: 'external PCRE2 match data') ].

	match := regex findMatch: 'a'.
	match bePersistent.
	self
		should: [ regex substituteUsingMatch: match with: 'x' ]
		raise: PCRE2Error
		withExceptionDo: [ :error | self assert: (error messageText includesSubstring: 'Persistent match data') ].

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
		withExceptionDo: [ :error | self assert: (error messageText includesSubstring: 'remember its subject bytes') ].

	partialMatch := 'abc' asPerlCompatibleRegex findPartialMatch: 'ab'.
	self
		should: [ 'abc' asPerlCompatibleRegex substituteUsingMatch: partialMatch with: 'x' ]
		raise: PCRE2Error
		withExceptionDo: [ :error | self assert: (error messageText includesSubstring: 'complete match') ]
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testSubstituteUsingMatchSupportsCallouts [

	| events input match regex result |
	self skipUnlessSubstitutionCalloutsSupported ifTrue: [ ^ self ].
	regex := '(\w+)' asPerlCompatibleRegex.
	input := 'one two' asPCRE2UTF8Input.
	match := regex findMatch: input.
	events := OrderedCollection new.

	result := regex substituteUsingMatch: match with: '[$0]' calloutsDo: [ :event |
			          events add: event.
			          PCRE2 substituteCalloutAccept ].

	self assert: result equals: '[one] two'.
	self assert: events size equals: 1.
	self assert: events first matchedText equals: 'one'.
	self assert: events first replacementText equals: '[one]'
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testSubstituteUsingMatchSupportsCaseCallout [

	| input match regex result |
	self skipUnlessSubstitutionCaseCalloutsSupported ifTrue: [ ^ self ].
	regex := '(\w+)' asPerlCompatibleRegex.
	input := 'one two' asPCRE2UTF8Input.
	match := regex findMatch: input.

	result := regex
		          substituteUsingMatch: match
		          with: '\U$0'
		          options: PCRE2 substituteExtended
		          caseCallout: [ :event | event inputText reversed ].

	self assert: result equals: 'eno two'
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testUnknownCapturesEmpty [

	| regex |
	regex := 'a' asPerlCompatibleRegex.

	self should: [ regex substitute: 'a' with: '<$1>' ] raise: PCRE2MatchError.
	self assert: (regex substitute: 'a' withUnknownCapturesEmpty: '<$1>') equals: '<>'
]

{ #category : 'tests' }
PCRE2SubstitutionTest >> testUnsetCapturesEmpty [

	| regex |
	regex := '(a)?b' asPerlCompatibleRegex.

	self should: [ regex substitute: 'b' with: '<$1>' ] raise: PCRE2MatchError.
	self assert: (regex substitute: 'b' withUnsetCapturesEmpty: '<$1>') equals: '<>'
]
