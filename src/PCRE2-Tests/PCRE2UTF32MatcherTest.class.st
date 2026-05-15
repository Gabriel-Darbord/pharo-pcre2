"
Tests PCRE2 matching through the 32-bit code-unit API.
"
Class {
	#name : 'PCRE2UTF32MatcherTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'private' }
PCRE2UTF32MatcherTest >> skipUnlessUTF32Supported [

	LibPCRE2UTF8 supports32BitCodeUnitWidth ifFalse: [ ^ true ].
	^ false
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testByteBackedInputMatchesAndReportsCharacterRanges [

	| input match ranges regex subject |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	subject := '1 café 2'.
	input := subject asPCRE2UTF32Input bytes asPCRE2UTF32Input.
	regex := PCRE2UTF32Compiler new compile: '\p{L}+'.
	match := regex findMatch: input.
	ranges := regex matchingRangesIn: input.

	self assert: match readMatch equals: 'café'.
	self assert: match offsets equals: #( 2 6 ).
	self assert: ranges asArray equals: { (3 to: 6) }
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testCalloutSitesDoEnumeratesInPatternOrder [

	| regex visited |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	regex := PCRE2UTF32Compiler new compile: '(?C2)a(?C3)b'.
	visited := OrderedCollection new.

	regex calloutSitesDo: [ :site | visited add: site number ].

	self assert: visited asArray equals: #( 2 3 )
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testCalloutSitesDoNotAffectMatching [

	| regex |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	regex := PCRE2UTF32Compiler new compile: '(?C1)a(?C"déjà")b'.

	self assert: regex calloutSites size equals: 2.
	self assert: (regex matches: 'ab').
	self deny: (regex matches: 'ac')
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testCalloutSitesExposeNumberedAndStringCallouts [

	| first regex second sites |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	regex := PCRE2UTF32Compiler new compile: '(?C1)a(?C"déjà")b'.
	sites := regex calloutSites.
	first := sites first.
	second := sites second.

	self assert: sites size equals: 2.
	self assert: first number equals: 1.
	self deny: first hasString.
	self assert: second number equals: 0.
	self assert: second hasString.
	self assert: second string equals: 'déjà'.
	self assert: second stringLength equals: 4.
	self assert: second patternPosition > first patternPosition
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testCapturesAndNamedGroupsReadFromUTF32Input [

	| match regex |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	regex := PCRE2UTF32Compiler new compile: '(?<word>\p{L}+)-(\d+)'.
	match := regex findMatch: 'café-42'.

	self assert: match readMatches equals: #( 'café-42' 'café' '42' ).
	self assert: (match groupNamed: 'word') equals: 'café'
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testCompileAndMatchContextsUseUTF32NativeAPI [

	| crCompiler crRegex lfCompiler lfRegex limitRegex subject |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	crCompiler := PCRE2UTF32Compiler new.
	self
		assert: crCompiler context class
		equals: PCRE2UTF32CompileContext.
	crCompiler options: (PCRE2 utf bitOr: PCRE2 multiline).
	crCompiler context useNewlineCR.
	crRegex := crCompiler compile: '^b$'.
	self assert: crRegex context class equals: PCRE2UTF32MatchContext.

	lfCompiler := PCRE2UTF32Compiler new.
	lfCompiler options: (PCRE2 utf bitOr: PCRE2 multiline).
	lfCompiler context useNewlineLF.
	lfRegex := lfCompiler compile: '^b$'.

	subject := 'a' , String cr , 'b'.
	self assert: (crRegex find: subject) equals: 'b'.
	self assert: (lfRegex find: subject) isNil.
	self
		assert: (crRegex info: PCRE2 infoNewline)
		equals: PCRE2 newlineCR.
	self
		assert: (lfRegex info: PCRE2 infoNewline)
		equals: PCRE2 newlineLF.

	limitRegex := PCRE2UTF32Compiler new compile: '(a+)+'.
	limitRegex addOptions: PCRE2 noJIT.
	limitRegex context matchLimit: 1.
	self should: [ limitRegex matches: 'aa' ] raise: PCRE2MatchError
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testCompileErrorFromBytePatternDecodesPattern [

	| patternInput |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	patternInput := #[ 40 0 0 0 97 0 0 0 ] asPCRE2UTF32LittleEndianInput.
	self
		should: [ PCRE2UTF32Compiler new compile: patternInput ]
		raise: PCRE2CompileError
		withExceptionDo: [ :error |
			self assert: error pattern equals: '(a'.
			self assert: error offset isInteger.
			self assert: (error messageText includesSubstring: '(*ERROR)') ]
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testCompilePatternFromBytesDetectingBOM [

	| patternInput regex |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	patternInput := #[ 255 254 0 0 97 0 0 0 43 0 0 0 ]
		                asPCRE2UTF32InputDetectingBOM.
	regex := PCRE2UTF32Compiler new compile: patternInput.

	self assert: regex pattern equals: 'a+'.
	self assert: (regex matches: 'aaa').
	self deny: (regex matches: 'bbb')
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testCompilePatternFromLittleEndianBytes [

	| regex |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	regex := PCRE2UTF32Compiler new compile:
		         #[ 97 0 0 0 43 0 0 0 ] asPCRE2UTF32LittleEndianInput.

	self assert: regex pattern equals: 'a+'.
	self assert: (regex matches: 'aaa')
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testCompilePatternFromNativeEndianBytes [

	| patternInput regex |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	patternInput := 'a+' asPCRE2UTF32Input bytes asPCRE2UTF32Input.
	regex := PCRE2UTF32Compiler new compile: patternInput.

	self assert: regex pattern equals: 'a+'.
	self assert: (regex matches: 'aaa').
	self deny: (regex matches: 'bbb')
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testCompileReturnsUTF32Matcher [

	| regex |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	regex := PCRE2UTF32Compiler new compile: '\p{L}+'.

	self assert: regex class equals: PCRE2UTF32Matcher.
	self assert: regex codeUnitWidth equals: 32
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testDFAMatchReturnsAllAlternatives [

	| match regex subject |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	subject := 'the caterpillar catchment'.
	regex := PCRE2UTF32Compiler new compile: 'cat(er(pillar)?)?'.
	match := regex dfaMatch: subject workspaceSize: 40 ovectorSize: 3.

	self assert: match class equals: PCRE2UTF32Match.
	self assert: match count equals: 3.
	self
		assert: match readMatches
		equals: #( 'caterpillar' 'cater' 'cat' ).
	self
		assert: (regex dfaMatches: subject workspaceSize: 40 ovectorSize: 3)
		equals: #( 'caterpillar' 'cater' 'cat' )
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testFindAllAndSplitReuseHighLevelFlow [

	| regex |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	regex := PCRE2UTF32Compiler new compile: '\p{L}+'.
	self
		assert: (regex findAll: 'aa 123 éé') asArray
		equals: #( 'aa' 'éé' ).
	self
		assert: ((PCRE2UTF32Compiler new compile: ',') split: 'a,b,c') asArray
		equals: #( 'a' 'b' 'c' )
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testFindMatchReadsUnicodeText [

	| match regex |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	regex := PCRE2UTF32Compiler new compile: '\p{L}+'.
	match := regex findMatch: 'café 123'.

	self assert: match class equals: PCRE2UTF32Match.
	self assert: match readMatch equals: 'café'.
	self assert: match offsets equals: #( 0 4 )
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testMark [

	| regex |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	regex := PCRE2UTF32Compiler new compile: ''.
	self assert: (regex findMatch: '') mark equals: nil.

	regex := PCRE2UTF32Compiler new compile:
		         '(*MARK:bye)((*MARK:café)A|D)C'.
	self assert: (regex findMatch: 'AC') mark equals: 'café'.
	self assert: (regex findMatch: 'DC') mark equals: 'bye'
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testMatchDataDiagnosticsUseUTF32NativeAPI [

	| match |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	match := (PCRE2UTF32Compiler new compile: '(a)(b)') findMatch: 'zab'.

	self assert: match class equals: PCRE2UTF32Match.
	self assert: match matchDataSize isInteger.
	self assert: match matchDataSize > 0.
	self assert: match heapframesSize isInteger.
	self assert: match heapframesSize >= 0
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testMatchingRangesUseCharacterOffsets [

	| ranges regex |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	regex := PCRE2UTF32Compiler new compile: '\p{L}+'.
	ranges := regex matchingRangesIn: '1 café 2'.

	self assert: ranges asArray equals: { (3 to: 6) }
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testRuntimeCalloutDecodesWidePayloadsAndMarks [

	| event events regex |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	regex := PCRE2UTF32Compiler new compile: '(*MARK:café)(?C"cœur")x'.
	regex addOptions: PCRE2 noJIT.
	events := OrderedCollection new.

	self assert: (regex matches: 'x' calloutsDo: [ :each |
			 events add: each.
			 0 ]).
	event := events first.
	self assert: event string equals: 'cœur'.
	self assert: event mark equals: 'café'
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testSubstituteCalloutDecodesWideText [

	| events regex result |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].
	LibPCRE2UTF8 supportsSubstitutionCallouts ifFalse: [ ^ self ].

	regex := PCRE2UTF32Compiler new compile: 'é'.
	events := OrderedCollection new.
	result := regex
		          substituteAll: 'café café'
		          with: 'e$0'
		          calloutsDo: [ :event |
			          events add: event.
			          PCRE2 substituteCalloutAccept ].

	self assert: result equals: 'cafeé cafeé'.
	self assert: events size equals: 2.
	self assert: events first matchedText equals: 'é'.
	self assert: events first replacementText equals: 'eé'.
	self assert: events second matchedText equals: 'é'.
	self assert: events second replacementText equals: 'eé'
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testSubstituteCaseCalloutDecodesWideText [

	| events regex result |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].
	LibPCRE2UTF8 supportsSubstitutionCaseCallouts ifFalse: [ ^ self ].

	regex := PCRE2UTF32Compiler new compile: '(\p{L}+)'.
	events := OrderedCollection new.
	result := regex
		          substituteAll: 'café thé'
		          with: '\U$0'
		          options: PCRE2 substituteExtended
		          caseCallout: [ :event |
			          events add: event.
			          event inputText , '!' ].

	self assert: result equals: 'café! thé!'.
	self assert: events size equals: 2.
	self assert: events first inputText equals: 'café'.
	self assert: events first caseName equals: #uppercase.
	self assert: events first codeUnitWidth equals: 32
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testSubstitutionAndCopyReuseHighLevelFlow [

	| input match regex replacement |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	regex := PCRE2UTF32Compiler new compile: 'é'.
	self
		assert: (regex substituteAll: 'café café' with: 'e')
		equals: 'cafe cafe'.

	input := 'café café' asPCRE2UTF32Input.
	replacement := 'e' asPCRE2UTF32Input.
	self
		assert: (regex substituteAll: input with: replacement)
		equals: 'cafe cafe'.

	regex := PCRE2UTF32Compiler new compile: '(\p{L}+)'.
	input := 'one two' asPCRE2UTF32Input.
	match := regex findMatch: input.
	self
		assert: (regex substituteUsingMatch: match with: '[$0]')
		equals: '[one] two'.

	regex := PCRE2UTF32Compiler new compile: '\d+'.
	self
		assert: (regex
				 copy: 'a12b3'
				 translatingMatchesUsing: [ :each | '[' , each , ']' ])
		equals: 'a[12]b[3]'
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testTraceMatchDecodesWideCalloutEvents [

	| event trace |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	trace := (PCRE2UTF32Compiler new compile: '(?C"cœur")é') traceMatch:
		         'é'.
	event := trace events detect: [ :each | each hasString ].

	self assert: trace isMatch.
	self assert: trace matchedString equals: 'é'.
	self assert: event string equals: 'cœur'.
	self assert: (trace subjectCharacterPositionAtEvent: event) equals: 1
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testTraceMatchTranslatesWidePatternRanges [

	| emoji event trace |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	emoji := String with: (Character value: 16r1F600).
	trace := (PCRE2UTF32Compiler new compile: emoji , '(?C2)a')
		         traceMatch: emoji , 'a'.
	event := trace events detect: [ :each | each number = 2 ].

	self
		assert: (trace patternCharacterRangeForEvent: event)
		equals: (7 to: 7).
	self assert: (trace subjectCharacterPositionAtEvent: event) equals: 2
]
