"
Represents a Pharo string prepared as UTF-8 input for PCRE2.

ASCII ByteStrings are already valid UTF-8, so they can be kept as byte storage without a decoder. Other strings are encoded through Zinc and keep the encoder needed to translate PCRE2 byte offsets back to Pharo character ranges.

Matcher APIs accept this object directly when a caller wants to reuse prepared subject bytes across repeated matches.
"
Class {
	#name : 'PCRE2UTF8Input',
	#superclass : 'PCRE2Input',
	#instVars : [
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

{ #category : 'initialization' }
PCRE2UTF8Input >> bytes: bytesObject decoder: aDecoder [

	self bytes: bytesObject.
	decoder := aDecoder
]

{ #category : 'decoding' }
PCRE2UTF8Input >> characterCountUpToByteOffset: byteOffset [
	"Answer the number of Pharo characters represented before byteOffset UTF-8 bytes."

	| count |
	byteOffset = 0 ifTrue: [ ^ 0 ].
	decoder ifNil: [ ^ byteOffset ].
	count := 0.
	1 to: byteOffset do: [ :index | "UTF-8 continuation bytes are 10xxxxxx, so every byte that is not a continuation byte starts one encoded character."
		((bytes at: index) bitAnd: 16rC0) = 16r80 ifFalse: [
			count := count + 1 ] ].
	^ count
]

{ #category : 'decoding' }
PCRE2UTF8Input >> decodeBytes: aByteCollection [
	"Decode a UTF-8 byte slice that came from my byte storage."

	^ decoder
		  ifNil: [ aByteCollection ]
		  ifNotNil: [ decoder decodeBytes: aByteCollection ]
]

{ #category : 'decoding' }
PCRE2UTF8Input >> decodeBytesFrom: start to: end [
	"Decode a UTF-8 byte range from my byte storage without copying the bytes first."

	| byteStream |
	byteStream := bytes readStream.
	byteStream position: start - 1.
	^ String streamContents: [ :stream |
		  [ byteStream position < end ] whileTrue: [
			  | codePoint |
			  codePoint := decoder nextCodePointFromStream: byteStream.
			  (codePoint > 255 and: [ stream originalContents isWideString not ])
				  ifTrue: [
					  | position wideString |
					  position := stream position.
					  wideString := WideString from: stream originalContents.
					  stream on: wideString.
					  stream setFrom: position + 1 to: position ].
			  stream nextPut: (Character value: codePoint) ] ]
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
PCRE2UTF8Input >> nextMatchStartOffsetAfter: zeroBasedOffset [
	"Answer the next zero-based code-unit offset after one character, or one past the end."

	| stream |
	zeroBasedOffset >= self size ifTrue: [ ^ self size + 1 ].
	decoder ifNil: [ ^ zeroBasedOffset + 1 ].
	stream := ReadStream on: bytes.
	stream position: zeroBasedOffset.
	decoder nextFromStream: stream.
	^ stream position
]

{ #category : 'decoding' }
PCRE2UTF8Input >> readFrom: start to: end [
	"Answer the decoded substring stored between the given 1-based PCRE2 code-unit indexes."

	start > end ifTrue: [ ^ String new ].
	decoder ifNil: [ ^ bytes copyFrom: start to: end ].
	^ self decodeBytesFrom: start to: end
]

{ #category : 'accessing' }
PCRE2UTF8Input >> size [

	^ bytes size
]
