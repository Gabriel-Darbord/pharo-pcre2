"
Tests UTF-32 prepared inputs used by PCRE2's 32-bit code-unit API.
"
Class {
	#name : 'PCRE2UTF32InputTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
PCRE2UTF32InputTest >> testBigEndianUTF32BytesAreNormalized [

	| input |
	input := #[ 0 0 0 99 0 0 0 97 0 0 0 102 0 0 0 233 ]
		         asPCRE2UTF32BigEndianInput.

	self assert: input size equals: 4.
	self assert: (input readFrom: 1 to: 4) equals: 'café'
]

{ #category : 'tests' }
PCRE2UTF32InputTest >> testLittleEndianUTF32BytesAreNormalized [

	| input |
	input := #[ 99 0 0 0 97 0 0 0 102 0 0 0 233 0 0 0 ]
		         asPCRE2UTF32LittleEndianInput.

	self assert: input size equals: 4.
	self assert: (input readFrom: 1 to: 4) equals: 'café'
]

{ #category : 'tests' }
PCRE2UTF32InputTest >> testNativeEndianBytesCanCreateReusableUTF32Input [

	| input subject |
	subject := 'café'.
	input := PCRE2UTF32Input fromBytes: subject asPCRE2UTF32Input bytes.

	self assert: input class equals: PCRE2UTF32Input.
	self assert: input size equals: subject size.
	self assert: input bytes size equals: subject size * 4.
	self assert: (input readFrom: 1 to: 4) equals: subject
]

{ #category : 'tests' }
PCRE2UTF32InputTest >> testStringCanCreateReusableUTF32Input [

	| input subject |
	subject := 'café'.
	input := subject asPCRE2UTF32Input.

	self assert: input class equals: PCRE2UTF32Input.
	self assert: input size equals: subject size.
	self assert: input bytes size equals: subject size * 4.
	self assert: (input bytes uint32AtOffset: 0) equals: $c asInteger.
	self assert: (input bytes uint32AtOffset: 12) equals: $é asInteger.
	self assert: (input readFrom: 2 to: 4) equals: 'afé'
]

{ #category : 'tests' }
PCRE2UTF32InputTest >> testUTF32ByteInputRejectsInvalidSize [

	self
		should: [ PCRE2UTF32Input fromBytes: #[ 97 0 ] ]
		raise: PCRE2Error
		withExceptionDo: [ :error |
			self assert:
				(error messageText includesSubstring: 'divisible by four') ]
]

{ #category : 'tests' }
PCRE2UTF32InputTest >> testUTF32InputDecodesByteSlices [

	| input |
	input := 'éclair' asPCRE2UTF32Input.

	self
		assert: (input decodeBytes: (input bytes copyFrom: 1 to: 8))
		equals: 'éc'
]
