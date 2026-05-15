"
Represents a Pharo string prepared as UTF-8 input for PCRE2.

ASCII ByteStrings are already valid UTF-8, so they can be kept as byte storage without a decoder. Other strings are encoded through Zinc and keep the encoder needed to translate PCRE2 byte offsets back to Pharo character ranges.

Matcher APIs accept this object directly when a caller wants to reuse prepared subject bytes across repeated matches.
"
Class {
	#name : 'PCRE2UTF8Input',
	#superclass : 'Object',
	#instVars : [
		'bytes',
		'decoder'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'instance creation' }
PCRE2UTF8Input class >> bytes: bytesObject decoder: aDecoder [

	^ self new
		  bytes: bytesObject decoder: aDecoder;
		  yourself
]

{ #category : 'testing' }
PCRE2UTF8Input class >> canUseDirectly: aString [
	"Answer whether aString can be passed to PCRE2-8 as already-valid UTF-8 bytes. Only ASCII ByteStrings qualify; non-ASCII ByteStrings contain byte-sized Unicode code points, not UTF-8."

	^ aString isByteString and: [
		  (ZnUTF8Encoder default findFirstNonASCIIIn: aString startingAt: 1)
		  = 0 ]
]

{ #category : 'instance creation' }
PCRE2UTF8Input class >> fromString: aString [

	| encoder |
	(self canUseDirectly: aString) ifTrue: [
		^ self bytes: aString decoder: nil ].
	encoder := ZnUTF8Encoder default.
	^ self bytes: (encoder encodeString: aString) decoder: encoder
]

{ #category : 'converting' }
PCRE2UTF8Input >> asPCRE2UTF8Input [
	"Answer myself so matcher APIs can accept either Strings or prepared inputs."

	^ self
]

{ #category : 'accessing' }
PCRE2UTF8Input >> bytes [

	^ bytes
]

{ #category : 'initialization' }
PCRE2UTF8Input >> bytes: bytesObject decoder: aDecoder [

	bytes := bytesObject.
	decoder := aDecoder
]

{ #category : 'decoding' }
PCRE2UTF8Input >> characterCountUpToByteOffset: byteOffset [
	"Answer the number of Pharo characters represented before byteOffset UTF-8 bytes."

	byteOffset = 0 ifTrue: [ ^ 0 ].
	decoder ifNil: [ ^ byteOffset ].
	^ (decoder decodeBytes: (bytes copyFrom: 1 to: byteOffset)) size
]

{ #category : 'decoding' }
PCRE2UTF8Input >> characterRangeFromStartOffset: zeroBasedStartOffset endOffset: exclusiveEndOffset [
	"Translate PCRE2's zero-based byte offsets to a 1-based Pharo character range."

	^ (self characterCountUpToByteOffset: zeroBasedStartOffset) + 1 to:
	  (self characterCountUpToByteOffset: exclusiveEndOffset)
]

{ #category : 'decoding' }
PCRE2UTF8Input >> decodeBytes: aByteCollection [
	"Decode a UTF-8 byte slice that came from my byte storage."

	^ decoder
		  ifNil: [ aByteCollection ]
		  ifNotNil: [ decoder decodeBytes: aByteCollection ]
]

{ #category : 'accessing' }
PCRE2UTF8Input >> decoder [

	^ decoder
]

{ #category : 'decoding' }
PCRE2UTF8Input >> nextFromStream: aStream [
	"Answer the next character from a stream over my UTF-8 byte storage."

	^ decoder
		  ifNil: [ aStream next ]
		  ifNotNil: [ decoder nextFromStream: aStream ]
]

{ #category : 'matching' }
PCRE2UTF8Input >> recordOn: aPCRE2Match [

	aPCRE2Match subject: bytes decoder: decoder
]

{ #category : 'accessing' }
PCRE2UTF8Input >> size [

	^ bytes size
]
