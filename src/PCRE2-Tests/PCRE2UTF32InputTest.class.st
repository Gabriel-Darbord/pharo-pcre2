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
PCRE2UTF32InputTest >> testUTF32InputDecodesByteSlices [

	| input |
	input := 'éclair' asPCRE2UTF32Input.

	self
		assert: (input decodeBytes: (input bytes copyFrom: 1 to: 8))
		equals: 'éc'
]
