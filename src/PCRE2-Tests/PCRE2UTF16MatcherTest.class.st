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
PCRE2UTF16MatcherTest >> testCompileErrorFromBytePatternDecodesPattern [

	| patternInput |
	self skipUnlessUTF16Supported ifTrue: [ ^ self ].

	patternInput := #[ 40 0 97 0 ] asPCRE2UTF16LittleEndianInput.
	self should: [ PCRE2UTF16Compiler new compile: patternInput ] raise: PCRE2CompileError withExceptionDo: [ :error |
			self assert: error pattern equals: '(a'.
			self assert: error offset isInteger.
			self assert: (error messageText includesSubstring: '(*ERROR)') ]
]

{ #category : 'tests' }
PCRE2UTF16MatcherTest >> testCompilePatternFromBytesDetectingBOM [

	| patternInput regex |
	self skipUnlessUTF16Supported ifTrue: [ ^ self ].

	patternInput := #[ 255 254 97 0 43 0 ] asPCRE2UTF16InputDetectingBOM.
	regex := PCRE2UTF16Compiler new compile: patternInput.

	self assert: regex pattern equals: 'a+'.
	self assert: (regex matches: 'aaa').
	self deny: (regex matches: 'bbb')
]

{ #category : 'tests' }
PCRE2UTF16MatcherTest >> testCompilePatternFromLittleEndianBytes [

	| regex |
	self skipUnlessUTF16Supported ifTrue: [ ^ self ].

	regex := PCRE2UTF16Compiler new compile: #[ 97 0 43 0 ] asPCRE2UTF16LittleEndianInput.

	self assert: regex pattern equals: 'a+'.
	self assert: (regex matches: 'aaa')
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
