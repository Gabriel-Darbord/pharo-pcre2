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

	LibPCRE2 supports32BitCodeUnitWidth ifFalse: [ ^ true ].
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
PCRE2UTF32MatcherTest >> testCapturesAndNamedGroupsReadFromUTF32Input [

	| match regex |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	regex := PCRE2UTF32Compiler new compile: '(?<word>\p{L}+)-(\d+)'.
	match := regex findMatch: 'café-42'.

	self assert: match readMatches equals: #( 'café-42' 'café' '42' ).
	self assert: (match groupNamed: 'word') equals: 'café'
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
PCRE2UTF32MatcherTest >> testMatchingRangesUseCharacterOffsets [

	| ranges regex |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	regex := PCRE2UTF32Compiler new compile: '\p{L}+'.
	ranges := regex matchingRangesIn: '1 café 2'.

	self assert: ranges asArray equals: { (3 to: 6) }
]
