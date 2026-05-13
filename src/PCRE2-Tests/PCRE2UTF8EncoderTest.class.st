"
Tests for `PCRE2UTF8Encoder` byte output and range translation.

The suite compares encoded bytes with Zinc and protects edge cases where ASCII runs follow non-ASCII characters.
"
Class {
	#name : 'PCRE2UTF8EncoderTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'asserting' }
PCRE2UTF8EncoderTest >> assertAllSubstrings: string [
	"Assert all substrings are converted correctly"

	1 to: string size do: [ :start |
		start to: string size do: [ :end |
		self assertSubstring: string from: start to: end ] ]
]

{ #category : 'asserting' }
PCRE2UTF8EncoderTest >> assertEncodingMatchesZinc: string [
	"Assert that the optimized encoder produces exactly the same UTF-8 bytes as Zinc."

	| bytes encoder zincBytes |
	encoder := self encoderClass from: 1 to: string size.
	bytes := encoder encodeString: string.
	zincBytes := ZnUTF8Encoder default encodeString: string.

	self assert: bytes equals: zincBytes.
	string ifNotEmpty: [
		self assert: encoder utfStart equals: 1.
		self assert: encoder utfEnd equals: zincBytes size ]
]

{ #category : 'asserting' }
PCRE2UTF8EncoderTest >> assertSubstring: string from: start to: end [
	"Encode the string, get substring using translated range, decode it, and assert equality with regular substring"

	| encoder bytes substring |
	encoder := self encoderClass from: start to: end.
	bytes := encoder encodeString: string.
	substring := encoder decodeBytes:
		             (bytes copyFrom: encoder utfStart to: encoder utfEnd).
	self assert: substring equals: (string copyFrom: start to: end)
]

{ #category : 'asserting' }
PCRE2UTF8EncoderTest >> encoderClass [

	^ PCRE2UTF8Encoder
]

{ #category : 'tests' }
PCRE2UTF8EncoderTest >> testEmptyEncodingAndRangeAccessors [

	| encoder bytes |
	encoder := self encoderClass from: 2 to: 3.
	self assert: encoder start equals: 2.
	self assert: encoder end equals: 3.

	bytes := encoder encodeString: ''.
	self assert: bytes equals: ByteArray new.
	self assert: encoder utfStart equals: 0.
	self assert: encoder utfEnd equals: 0
]

{ #category : 'tests' }
PCRE2UTF8EncoderTest >> testEncodeString [

	self assertAllSubstrings: 'ascii'. "only ASCII (single bytes)"
	self assertAllSubstrings: 'ûnïcòdé'. "mix ASCII and Latin-1"
	self assertAllSubstrings: 'ùñîçöðè'. "only Latin-1 (double bytes)"

	"wide strings"
	self assertAllSubstrings: '€où'. "#[226 130 172 111 195 185]"
	self assertAllSubstrings: 'こんにちは'. "#[227 129 147 227 130 147 227 129 171 227 129 161 227 129 175]"
	self assertAllSubstrings: '😊👍🏽'. "#[240 159 152 138 240 159 145 141 240 159 143 189]"
	self assertAllSubstrings: 'a̐éö̲' "#[97 204 144 101 204 129 111 204 136 204 178]"
]

{ #category : 'tests' }
PCRE2UTF8EncoderTest >> testEncodeStringMatchesZinc [

	{ 'ascii'. 'éa'. 'éab'. 'aé'. 'aéa'. 'ûnïcòdé'. 'ùñîçöðè'. '€où'.
	'こんにちは'. '😊👍🏽'. 'a̐éö̲' } do: [ :string |
		self assertEncodingMatchesZinc: string ]
]

{ #category : 'tests' }
PCRE2UTF8EncoderTest >> testInvalidCodePointRaisesError [

	| stream |
	stream := ByteArray new writeStream.

	self
		should: [
		self encoderClass new nextPutCodePoint: 16r110000 toStream: stream ]
		raise: Error
]

{ #category : 'tests' }
PCRE2UTF8EncoderTest >> testTranslatedRangeIncludesSingleTrailingASCIIAfterNonASCII [

	| bytes encoder string substring |
	string := 'éa'.
	encoder := self encoderClass from: 1 to: string size.
	bytes := encoder encodeString: string.
	substring := encoder decodeBytes:
		             (bytes copyFrom: encoder utfStart to: encoder utfEnd).

	self assert: bytes equals: #[ 195 169 97 ].
	self assert: encoder utfStart equals: 1.
	self assert: encoder utfEnd equals: 3.
	self assert: substring equals: string
]
