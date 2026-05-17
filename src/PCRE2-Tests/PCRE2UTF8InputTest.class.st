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
PCRE2UTF8InputTest >> testASCIIRangeTranslationUsesCodeUnitOffsets [

	| input |
	input := PCRE2UTF8Input fromString: 'abc123'.

	self assert: (input characterCountUpToCodeUnitOffset: 0) equals: 0.
	self assert: (input characterCountUpToCodeUnitOffset: 3) equals: 3.
	self
		assert: (input characterRangeFromStartOffset: 1 endOffset: 4)
		equals: (2 to: 4).
	self assert: (input decodeBytes: 'bc') equals: 'bc'
]

{ #category : 'tests' }
PCRE2UTF8InputTest >> testAsPCRE2UTF8InputReturnsSelf [

	| input |
	input := PCRE2UTF8Input fromString: 'abc'.

	self assert: input asPCRE2UTF8Input identicalTo: input
]

{ #category : 'tests' }
PCRE2UTF8InputTest >> testByteArrayCanCreateReusableUTF8Input [

	| bytes input subject |
	subject := 'café'.
	bytes := ZnUTF8Encoder default encodeString: subject.
	input := bytes asPCRE2UTF8Input.

	self assert: input class equals: PCRE2UTF8Input.
	self assert: input bytes equals: bytes.
	self deny: input bytes identicalTo: bytes.
	self assert: input decoder class equals: ZnUTF8Encoder.
	self assert: input size equals: bytes size.
	self assert: (input readFrom: 1 to: input size) equals: subject.
	self
		assert: (input characterCountUpToCodeUnitOffset: input size)
		equals: subject size
]

{ #category : 'tests' }
PCRE2UTF8InputTest >> testCharacterRangeTranslationHandlesUTF8CodeUnitOffsets [

	| input subject |
	subject := String streamContents: [ :stream |
		           stream
			           nextPut: (Character value: 16rE9);
			           nextPut: $a;
			           nextPut: (Character value: 16r20AC);
			           nextPut: (Character value: 16r1F60A) ].
	input := PCRE2UTF8Input fromString: subject.

	self
		assert: input bytes
		equals: #[ 195 169 97 226 130 172 240 159 152 138 ].
	self assert: (input characterCountUpToCodeUnitOffset: 0) equals: 0.
	self assert: (input characterCountUpToCodeUnitOffset: 2) equals: 1.
	self assert: (input characterCountUpToCodeUnitOffset: 3) equals: 2.
	self assert: (input characterCountUpToCodeUnitOffset: 6) equals: 3.
	self assert: (input characterCountUpToCodeUnitOffset: 10) equals: 4.
	self
		assert: (input characterRangeFromStartOffset: 0 endOffset: 2)
		equals: (1 to: 1).
	self
		assert: (input characterRangeFromStartOffset: 2 endOffset: 6)
		equals: (2 to: 3).
	self
		assert: (input characterRangeFromStartOffset: 6 endOffset: 10)
		equals: (4 to: 4)
]

{ #category : 'tests' }
PCRE2UTF8InputTest >> testDecodingAndStreamingUsePreparedDecoder [

	| input stream |
	input := PCRE2UTF8Input fromString:
		         (String with: (Character value: 16rE9) with: $a).
	stream := input bytes readStream.

	self
		assert: (input decodeBytes: (input bytes copyFrom: 1 to: 2))
		equals: (String with: (Character value: 16rE9)).
	self
		assert: (input nextFromStream: stream)
		equals: (Character value: 16rE9).
	self assert: (input nextFromStream: stream) equals: $a
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
