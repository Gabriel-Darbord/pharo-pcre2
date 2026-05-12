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
