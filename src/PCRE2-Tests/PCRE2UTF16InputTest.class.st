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
PCRE2UTF16InputTest >> testStringCanCreateReusableUTF16Input [

	| input subject |
	subject := 'café'.
	input := subject asPCRE2UTF16Input.

	self assert: input class equals: PCRE2UTF16Input.
	self assert: input size equals: subject size.
	self assert: input bytes size equals: subject size * 2.
	self assert: (input bytes uint16AtOffset: 0) equals: $c asInteger.
	self assert: (input bytes uint16AtOffset: 6) equals: $é asInteger.
	self assert: (input readFrom: 2 to: 4) equals: 'afé'
]

{ #category : 'tests' }
PCRE2UTF16InputTest >> testUTF16InputDecodesByteSlices [

	| input |
	input := 'éclair' asPCRE2UTF16Input.

	self
		assert: (input decodeBytes: (input bytes copyFrom: 1 to: 4))
		equals: 'éc'
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
	self
		assert: (input characterRangeFromStartOffset: 1 endOffset: 3)
		equals: (2 to: 2).
	self assert: (input readFrom: 2 to: 3) equals: emoji.
	self assert: (input decodeBytes: input bytes) equals: subject
]
