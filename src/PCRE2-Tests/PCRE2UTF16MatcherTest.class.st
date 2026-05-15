"
Tests the PCRE2 16-bit code-unit compiler and matcher integration.
"
Class {
	#name : 'PCRE2UTF16MatcherTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'private' }
PCRE2UTF16MatcherTest >> emojiString [

	^ String with: (Character value: 16r1F600)
]

{ #category : 'private' }
PCRE2UTF16MatcherTest >> skipUnlessUTF16Supported [

	LibPCRE2 supports16BitCodeUnitWidth ifFalse: [ ^ true ].
	^ false
]

{ #category : 'tests' }
PCRE2UTF16MatcherTest >> testByteBackedInputMatchesAndReportsCharacterRanges [

	| emoji input match ranges regex subject |
	self skipUnlessUTF16Supported ifTrue: [ ^ self ].

	emoji := self emojiString.
	subject := 'a' , emoji , 'b'.
	input := subject asPCRE2UTF16Input bytes asPCRE2UTF16Input.
	regex := PCRE2UTF16Compiler new compile: emoji.
	match := regex findMatch: input.
	ranges := regex matchingRangesIn: input.

	self assert: match readMatch equals: emoji.
	self assert: match offsets equals: #( 1 3 ).
	self assert: ranges asArray equals: { (2 to: 2) }
]

{ #category : 'tests' }
PCRE2UTF16MatcherTest >> testCapturesAndNamedGroupsReadFromUTF16Input [

	| match regex |
	self skipUnlessUTF16Supported ifTrue: [ ^ self ].

	regex := PCRE2UTF16Compiler new compile: '(?<word>\p{L}+)-(\d+)'.
	match := regex findMatch: 'café-42'.

	self assert: match readMatches equals: #( 'café-42' 'café' '42' ).
	self assert: (match groupNamed: 'word') equals: 'café'
]

{ #category : 'tests' }
PCRE2UTF16MatcherTest >> testCompileReturnsUTF16Matcher [

	| regex |
	self skipUnlessUTF16Supported ifTrue: [ ^ self ].

	regex := PCRE2UTF16Compiler new compile: '\p{L}+'.

	self assert: regex class equals: PCRE2UTF16Matcher.
	self assert: regex codeUnitWidth equals: 16
]

{ #category : 'tests' }
PCRE2UTF16MatcherTest >> testFindAllAndSplitReuseHighLevelFlow [

	| regex |
	self skipUnlessUTF16Supported ifTrue: [ ^ self ].

	regex := PCRE2UTF16Compiler new compile: '\p{L}+'.
	self
		assert: (regex findAll: 'aa 123 éé') asArray
		equals: #( 'aa' 'éé' ).
	self
		assert:
		((PCRE2UTF16Compiler new compile: ',') split: 'a,b,c') asArray
		equals: #( 'a' 'b' 'c' )
]

{ #category : 'tests' }
PCRE2UTF16MatcherTest >> testFindMatchReadsUnicodeText [

	| match regex |
	self skipUnlessUTF16Supported ifTrue: [ ^ self ].

	regex := PCRE2UTF16Compiler new compile: '\p{L}+'.
	match := regex findMatch: 'café 123'.

	self assert: match class equals: PCRE2UTF16Match.
	self assert: match readMatch equals: 'café'.
	self assert: match offsets equals: #( 0 4 )
]

{ #category : 'tests' }
PCRE2UTF16MatcherTest >> testMatchingRangesUseCharacterOffsets [

	| ranges regex |
	self skipUnlessUTF16Supported ifTrue: [ ^ self ].

	regex := PCRE2UTF16Compiler new compile: '\p{L}+'.
	ranges := regex matchingRangesIn: '1 café 2'.

	self assert: ranges asArray equals: { (3 to: 6) }
]

{ #category : 'tests' }
PCRE2UTF16MatcherTest >> testSupplementaryCharacterOffsetsUseUTF16CodeUnits [

	| emoji match ranges regex subject |
	self skipUnlessUTF16Supported ifTrue: [ ^ self ].

	emoji := self emojiString.
	subject := 'a' , emoji , 'b'.
	regex := PCRE2UTF16Compiler new compile: emoji.
	match := regex findMatch: subject.
	ranges := regex matchingRangesIn: subject.

	self assert: match readMatch equals: emoji.
	self assert: match offsets equals: #( 1 3 ).
	self assert: ranges asArray equals: { (2 to: 2) }
]
