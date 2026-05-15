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
PCRE2UTF32MatcherTest >> testCapturesAndNamedGroupsReadFromUTF32Input [

	| match regex |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	regex := PCRE2Compiler32 new compile: '(?<word>\p{L}+)-(\d+)'.
	match := regex findMatch: 'café-42'.

	self assert: match readMatches equals: #( 'café-42' 'café' '42' ).
	self assert: (match groupNamed: 'word') equals: 'café'
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testCompileReturnsUTF32Matcher [

	| regex |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	regex := PCRE2Compiler32 new compile: '\p{L}+'.

	self assert: regex class equals: PCRE2Matcher32.
	self assert: regex codeUnitWidth equals: 32
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testFindAllAndSplitReuseHighLevelFlow [

	| regex |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	regex := PCRE2Compiler32 new compile: '\p{L}+'.
	self
		assert: (regex findAll: 'aa 123 éé') asArray
		equals: #( 'aa' 'éé' ).
	self
		assert: ((PCRE2Compiler32 new compile: ',') split: 'a,b,c') asArray
		equals: #( 'a' 'b' 'c' )
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testFindMatchReadsUnicodeText [

	| match regex |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	regex := PCRE2Compiler32 new compile: '\p{L}+'.
	match := regex findMatch: 'café 123'.

	self assert: match class equals: PCRE2Match32.
	self assert: match readMatch equals: 'café'.
	self assert: match offsets equals: #( 0 4 )
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testMatchingRangesUseCharacterOffsets [

	| ranges regex |
	self skipUnlessUTF32Supported ifTrue: [ ^ self ].

	regex := PCRE2Compiler32 new compile: '\p{L}+'.
	ranges := regex matchingRangesIn: '1 café 2'.

	self assert: ranges asArray equals: { (3 to: 6) }
]
