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
