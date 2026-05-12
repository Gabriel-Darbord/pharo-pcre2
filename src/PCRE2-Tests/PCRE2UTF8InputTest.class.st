"
Tests for reusable prepared UTF-8 input.

The suite covers ASCII direct storage, non-ASCII encoding, WideString encoding, and the public `asPCRE2UTF8Input` conversion protocol.
"
Class {
	#name : 'PCRE2UTF8InputTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
PCRE2UTF8InputTest >> testASCIIByteStringUsesOriginalStorage [

	| input subject |
	subject := 'abc123'.
	input := PCRE2UTF8Input fromString: subject.

	self assert: (PCRE2UTF8Input canUseDirectly: subject).
	self assert: input bytes identicalTo: subject.
	self assert: input decoder identicalTo: nil.
	self assert: input size equals: subject size
]

{ #category : 'tests' }
PCRE2UTF8InputTest >> testAsPCRE2UTF8InputReturnsSelf [

	| input |
	input := PCRE2UTF8Input fromString: 'abc'.

	self assert: input asPCRE2UTF8Input identicalTo: input
]

{ #category : 'tests' }
PCRE2UTF8InputTest >> testNonASCIIByteStringIsEncoded [

	| input subject |
	subject := 'café'.
	input := PCRE2UTF8Input fromString: subject.

	self deny: (PCRE2UTF8Input canUseDirectly: subject).
	self deny: input bytes identicalTo: subject.
	self
		assert: input bytes
		equals: (ZnUTF8Encoder default encodeString: subject).
	self assert: input decoder class equals: ZnUTF8Encoder
]

{ #category : 'tests' }
PCRE2UTF8InputTest >> testStringCanCreateReusableUTF8Input [

	| input subject |
	subject := 'café'.
	input := subject asPCRE2UTF8Input.

	self assert: input class equals: PCRE2UTF8Input.
	self
		assert: input bytes
		equals: (ZnUTF8Encoder default encodeString: subject).
	self assert: input decoder class equals: ZnUTF8Encoder
]

{ #category : 'tests' }
PCRE2UTF8InputTest >> testWideStringIsEncoded [

	| input subject |
	subject := 'λabc'.
	input := PCRE2UTF8Input fromString: subject.

	self deny: (PCRE2UTF8Input canUseDirectly: subject).
	self
		assert: input bytes
		equals: (ZnUTF8Encoder default encodeString: subject).
	self assert: input decoder class equals: ZnUTF8Encoder
]
