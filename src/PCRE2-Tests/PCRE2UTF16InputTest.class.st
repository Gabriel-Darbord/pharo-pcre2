"
Tests reusable UTF-16 input preparation and code-unit-to-character offset translation.
"
Class {
	#name : 'PCRE2UTF16InputTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'private' }
PCRE2UTF16InputTest >> emojiString [

	^ String with: (Character value: 16r1F600)
]

{ #category : 'tests' }
PCRE2UTF16InputTest >> testBigEndianUTF16BytesAreNormalized [

	| input |
	input := #[ 0 99 0 97 0 102 0 233 ] asPCRE2UTF16BigEndianInput.

	self assert: input size equals: 4.
	self assert: (input readFrom: 1 to: 4) equals: 'café'
]

{ #category : 'tests' }
PCRE2UTF16InputTest >> testDetectingUTF16BOMFallsBackToNativeEndian [

	| input subject |
	subject := 'café'.
	input := subject asPCRE2UTF16Input bytes asPCRE2UTF16InputDetectingBOM.

	self assert: input size equals: 4.
	self assert: (input readFrom: 1 to: 4) equals: subject
]

{ #category : 'tests' }
PCRE2UTF16InputTest >> testDetectingUTF16BOMStripsBigEndianBOM [

	| input |
	input := #[ 254 255 0 99 0 97 0 102 0 233 ] asPCRE2UTF16InputDetectingBOM.

	self assert: input size equals: 4.
	self assert: (input readFrom: 1 to: 4) equals: 'café'
]

{ #category : 'tests' }
PCRE2UTF16InputTest >> testDetectingUTF16BOMStripsLittleEndianBOM [

	| input |
	input := #[ 255 254 99 0 97 0 102 0 233 0 ] asPCRE2UTF16InputDetectingBOM.

	self assert: input size equals: 4.
	self assert: (input readFrom: 1 to: 4) equals: 'café'
]

{ #category : 'tests' }
PCRE2UTF16InputTest >> testLittleEndianUTF16BytesAreNormalized [

	| input |
	input := #[ 99 0 97 0 102 0 233 0 ] asPCRE2UTF16LittleEndianInput.

	self assert: input size equals: 4.
	self assert: (input readFrom: 1 to: 4) equals: 'café'
]

{ #category : 'tests' }
PCRE2UTF16InputTest >> testUTF16ByteInputRejectsOddSize [

	self
		should: [ PCRE2UTF16Input fromBytes: #[ 97 ] ]
		raise: PCRE2Error
		withExceptionDo: [ :error | self assert: (error messageText includesSubstring: 'even byte size') ]
]

{ #category : 'tests' }
PCRE2UTF16InputTest >> testUTF16InputEncodesSupplementaryCharactersAsSurrogatePairs [

	| emoji input subject |
	emoji := self emojiString.
	subject := 'a' , emoji , 'b'.
	input := subject asPCRE2UTF16Input.

	self assert: input size equals: 4.
	self assert: input bytes size equals: 8.
	self assert: (input bytes uint16AtOffset: 0) equals: $a asInteger.
	self assert: (input bytes uint16AtOffset: 2) equals: 16rD83D.
	self assert: (input bytes uint16AtOffset: 4) equals: 16rDE00.
	self assert: (input bytes uint16AtOffset: 6) equals: $b asInteger.
	self assert: (input characterRangeFromStartOffset: 1 endOffset: 3) equals: (2 to: 2).
	self assert: (input readFrom: 2 to: 3) equals: emoji.
	self assert: (input decodeBytes: input bytes) equals: subject
]

{ #category : 'tests' }
PCRE2UTF16InputTest >> testUTF16InputWithBOMAcceptsOnlyBOM [

	| input |
	input := #[ 255 254 ] asPCRE2UTF16InputWithBOM.

	self assert: input size equals: 0
]

{ #category : 'tests' }
PCRE2UTF16InputTest >> testUTF16InputWithBOMRejectsMissingBOM [

	self
		should: [ #[ 99 0 ] asPCRE2UTF16InputWithBOM ]
		raise: PCRE2Error
		withExceptionDo: [ :error | self assert: (error messageText includesSubstring: 'BOM') ]
]
