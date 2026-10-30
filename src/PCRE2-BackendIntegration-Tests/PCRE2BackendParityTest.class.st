"
Behavior that must come out the same whichever backend compiled the pattern. Every test runs once per backend, so a disagreement names the backend that disagreed instead of hiding behind the other one.

Coexistence of the two backends in one image belongs in PCRE2BackendIntegrationTest, and agreement that depends on the code-unit width in PCRE2BackendWidthParityTest.
"
Class {
	#name : 'PCRE2BackendParityTest',
	#superclass : 'ParametrizedTestCase',
	#instVars : [
		'backend'
	],
	#category : 'PCRE2-BackendIntegration-Tests',
	#package : 'PCRE2-BackendIntegration-Tests'
}

{ #category : 'building suites' }
PCRE2BackendParityTest class >> testParameters [

	^ ParametrizedTestMatrix new
		  forSelector: #backend addOptions: {
				  PCRE2CompilerFFIBackend.
				  PCRE2CompilerPharoBackend };
		  yourself
]

{ #category : 'private' }
PCRE2BackendParityTest >> anchorsItsOwnStart: pattern [
	"Whether the compiled pattern reports that it can only match in one place."

	^ (((self compile: pattern) info: PCRE2 infoAllOptions) bitAnd: PCRE2 anchored) ~= 0
]

{ #category : 'accessing' }
PCRE2BackendParityTest >> backend: aBackendClass [

	backend := aBackendClass
]

{ #category : 'private' }
PCRE2BackendParityTest >> byteOrderMark [

	^ (Character value: 16rFEFF) asString
]

{ #category : 'private' }
PCRE2BackendParityTest >> compile: pattern [

	^ PCRE2Compiler new
		  backend: backend;
		  compile: pattern
]

{ #category : 'private' }
PCRE2BackendParityTest >> matchInvalidUTF: pattern in: bytes [
	"The offsets of the first match over possibly malformed subject bytes, or nil."

	| matcher data rc |
	matcher := PCRE2Compiler new
		           backend: backend;
		           options: PCRE2 matchInvalidUTF;
		           compile: pattern.
	data := matcher newMatchData.
	rc := matcher
		      matchBytes: bytes
		      from: 1
		      to: bytes size
		      into: data.
	^ rc > 0 ifTrue: [ (data offsets first: rc * 2) asArray ]
]

{ #category : 'private' }
PCRE2BackendParityTest >> partialMatch: pattern in: bytes options: matchOptions [
	"The result code and the first two offsets of one match attempt under partial matching."

	| matcher data rc |
	matcher := PCRE2Compiler new
		           backend: backend;
		           compile: pattern.
	data := matcher newMatchData.
	rc := matcher
		      matchBytes: bytes
		      from: 1
		      to: bytes size
		      options: matchOptions
		      into: data.
	^ {
		  rc.
		  (data offsets first: 2) asArray }
]

{ #category : 'tests' }
PCRE2BackendParityTest >> testAnchoringIsNotOneOfTheStartOptimizations [
	"Turning the start optimizations off stops PCRE2 looking for the characters a match can begin with, but a pattern that can only match in one place is still anchored."

	| matcher |
	matcher := PCRE2Compiler new
		           backend: backend;
		           options: PCRE2 noStartOptimize;
		           compile: '^abc'.
	self assert: ((matcher info: PCRE2 infoAllOptions) bitAnd: PCRE2 anchored) ~= 0
]

{ #category : 'tests' }
PCRE2BackendParityTest >> testByteOrderMarkInReplacementAndCalloutStrings [

	| text matcher events |
	text := self byteOrderMark.
	self assert: ((self compile: 'a') substitute: 'a' with: text) equals: text.
	matcher := self compile: '(?C"' , text , '")a'.
	self assert: matcher calloutSites first string equals: text.
	events := OrderedCollection new.
	self assert: (matcher matches: 'a' calloutsDo: [ :event |
				 events add: event.
				 0 ]).
	self assert: events first string equals: text
]

{ #category : 'tests' }
PCRE2BackendParityTest >> testByteOrderMarkMatchesAsRegexData [

	| text subject match |
	text := self byteOrderMark.
	subject := 'a' , text , 'b'.
	match := (self compile: text) findMatch: subject.
	self assert: match readMatch equals: text.
	self assert: ((self compile: text) matchingRangesIn: subject) asArray equals: { (2 to: 2) }
]

{ #category : 'tests' }
PCRE2BackendParityTest >> testCodeUnitCaptureDoesNotReadBeyondItsUTF8Slice [

	| match |
	match := (self compile: '\C') findMatch: 'é'.
	self assert: match offsets equals: #( 0 1 ).
	self should: [ match readMatch ] raise: ZnCharacterEncodingError
]

{ #category : 'tests' }
PCRE2BackendParityTest >> testDFAWorkspaceReuseInvalidatesOffsetsAndResumesRepetition [

	| matcher workspace data |
	matcher := PCRE2UTF8Compiler new
		           backend: backend;
		           compile: 'a+b+c'.
	workspace := ByteArray new: 400.
	data := matcher newMatchData.
	matcher options: PCRE2 partialHard.
	self
		assert: (matcher
				 dfaMatch: 'a'
				 from: 0
				 to: 1
				 matchData: data
				 workspace: workspace
				 size: 100)
		equals: PCRE2 errorPartial.
	self assert: (data offsets first: 2) equals: #( 0 1 ).
	matcher options: PCRE2 dfaRestart.
	self
		assert: (matcher
				 dfaMatch: 'bbc'
				 from: 0
				 to: 3
				 matchData: data
				 workspace: workspace
				 size: 100)
		equals: 1.
	self assert: (data offsets first: 2) equals: #( 0 3 )
]

{ #category : 'tests' }
PCRE2BackendParityTest >> testInvalidUTFIsRefusedByDFAMatching [
	"Only the ordinary matching function supports PCRE2_MATCH_INVALID_UTF."

	| matcher data |
	matcher := PCRE2UTF8Compiler new
		           backend: backend;
		           options: PCRE2 matchInvalidUTF;
		           compile: 'b'.
	data := matcher newMatchData.
	self
		assert: (matcher
				 dfaMatch: #[ 97 255 98 ]
				 from: 0
				 to: 3
				 matchData: data
				 workspace: (ByteArray new: 400)
				 size: 100)
		equals: PCRE2 errorDFAInvalidUTF
]

{ #category : 'tests' }
PCRE2BackendParityTest >> testInvalidUTFSubjectsAreMatchedFragmentByFragment [
	"With PCRE2_MATCH_INVALID_UTF the subject reads as fragments of valid UTF: an invalid sequence matches nothing, a match never crosses one, and a fragment edge is not a line edge."

	| word |
	self assert: (self matchInvalidUTF: 'b' in: #[ 97 255 98 ]) equals: #( 2 3 ).
	self assert: (self matchInvalidUTF: '[^x]+' in: #[ 97 255 98 ]) equals: #( 0 1 ).
	self assert: (self matchInvalidUTF: 'a.b' in: #[ 97 255 98 ]) isNil.
	self assert: (self matchInvalidUTF: '(?<=a)b' in: #[ 97 255 98 ]) isNil.
	word := #[ 87 79 82 68 255 87 79 82 68 ].
	self assert: (self matchInvalidUTF: '\bWORD\b' in: word) equals: #( 0 4 ).
	self assert: (self matchInvalidUTF: '^WORD' in: word) equals: #( 0 4 ).
	self assert: (self matchInvalidUTF: 'WORD\z' in: word) equals: #( 5 9 ).
	self assert: (self matchInvalidUTF: '^WORD$' in: word) isNil
]

{ #category : 'tests' }
PCRE2BackendParityTest >> testPartialMatchingReportsAssertionsThatWantedMoreSubject [
	"A word boundary, and an assertion that held only because the subject ends where it does, are reasons PCRE2 answers a partial match rather than a match."

	self assert: (self partialMatch: '\bWORD\b' in: #[  ] options: PCRE2 partialSoft) equals: {
			PCRE2 errorPartial.
			#( 0 0 ) }.
	self assert: (self partialMatch: '\bWORD\b' in: #[ 87 79 82 68 ] options: PCRE2 partialHard) equals: {
			PCRE2 errorPartial.
			#( 0 4 ) }.
	self assert: (self partialMatch: 'a\b' in: #[ 97 ] options: PCRE2 partialSoft) equals: {
			1.
			#( 0 1 ) }.
	self assert: (self partialMatch: 'b$' in: #[ 97 98 10 ] options: PCRE2 partialHard) equals: {
			PCRE2 errorPartial.
			#( 1 3 ) }.
	self assert: (self partialMatch: '(?m)b$' in: #[ 97 98 10 99 100 ] options: PCRE2 partialHard) equals: {
			1.
			#( 1 2 ) }
]

{ #category : 'tests' }
PCRE2BackendParityTest >> testPatternsThatCanOnlyMatchInOnePlaceAreAnchored [
	"PCRE2 anchors a pattern every branch of which starts at a fixed place and reports it among the pattern's options. A leading dot star counts only where a later attempt could not find anything the first one missed, so a backreference to what it matched, an atomic group around it, or (*PRUNE) anywhere in the pattern all rule it out."

	#( '^abc' '\Aabc' '\Gabc' '^a|^b' '(^ab)+' '(?(1)^a()|^a)+b' '(?i)^abc' '(?s).*x' '(?s).*+x' '(?(DEFINE)(a))^bc' ) do: [ :pattern |
		self assert: (self anchorsItsOwnStart: pattern) description: pattern ].
	#( 'abc' '(?m)^abc' '^a|b' '.*x' '(^ab)*' '(?s)(.*)x\1' '(?s).*(*PRUNE)x' '(?s)(?>.*)x' '(*ACCEPT:XX)^abc' ) do: [ :pattern |
		self deny: (self anchorsItsOwnStart: pattern) description: pattern ]
]
