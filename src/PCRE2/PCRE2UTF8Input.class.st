"
Represents UTF-8 code-unit input for PCRE2-8.

Instances can be created from a Pharo string, an already prepared PCRE2UTF8Input, or already-encoded UTF-8 bytes. ASCII ByteStrings are already valid UTF-8, so they can be kept as encoded storage without a decoder. Non-ASCII strings are encoded through Zinc and keep the decoder needed to translate PCRE2-8 code-unit offsets back to Pharo character ranges. Byte-backed inputs always keep a decoder because raw ByteArrays decode to text rather than returning byte storage.

For PCRE2-8, each code unit is one byte of UTF-8 storage. A Pharo character may therefore occupy one or more PCRE2 code units. Matcher and compiler APIs accept this object directly when a caller wants to reuse prepared pattern or subject bytes across repeated calls.
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

	^ aString isByteString and: [ (ZnUTF8Encoder default findFirstNonASCIIIn: aString startingAt: 1) = 0 ]
]

{ #category : 'instance creation' }
PCRE2UTF8Input class >> fromBytes: aByteCollection [
	"Answer input from already-encoded UTF-8 bytes. The byte collection is copied so callers can safely reuse or mutate their original storage."

	^ self bytes: aByteCollection copy decoder: ZnUTF8Encoder default
]

{ #category : 'instance creation' }
PCRE2UTF8Input class >> fromString: aString [

	| encoder |
	(self canUseDirectly: aString) ifTrue: [ ^ self bytes: aString decoder: nil ].
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
PCRE2UTF8Input >> characterCountUpToCodeUnitOffset: codeUnitOffset [
	"For PCRE2-8, each code unit is one byte of UTF-8 storage. Count encoded characters before that code-unit position."

	^ self characterCountUpToCodeUnitOffset: codeUnitOffset fromCodeUnitOffset: 0 characterCount: 0
]

{ #category : 'decoding' }
PCRE2UTF8Input >> characterCountUpToCodeUnitOffset: codeUnitOffset fromCodeUnitOffset: knownCodeUnitOffset characterCount: knownCharacterCount [
	"Continue counting UTF-8 characters from a known PCRE2-8 code-unit offset."

	| count |
	codeUnitOffset <= 0 ifTrue: [ ^ 0 ].
	codeUnitOffset = knownCodeUnitOffset ifTrue: [ ^ knownCharacterCount ].
	codeUnitOffset < knownCodeUnitOffset ifTrue: [
		^ self characterCountUpToCodeUnitOffset: codeUnitOffset fromCodeUnitOffset: 0 characterCount: 0 ].
	decoder ifNil: [ ^ codeUnitOffset ].
	count := knownCharacterCount.
	"UTF-8 continuation bytes are 10xxxxxx; only non-continuation bytes start encoded characters."
	knownCodeUnitOffset + 1 to: codeUnitOffset do: [ :index |
	((bytes at: index) bitAnd: 16rC0) = 16r80 ifFalse: [ count := count + 1 ] ].
	^ count
]

{ #category : 'decoding' }
PCRE2UTF8Input >> decodeBytes: aByteCollection [
	"Decode a UTF-8 byte slice that came from my byte storage."

	^ decoder ifNil: [ aByteCollection ] ifNotNil: [ decoder decodeBytes: aByteCollection ]
]

{ #category : 'decoding' }
PCRE2UTF8Input >> decodeBytesFrom: start to: end [
	"Decode a 1-based inclusive byte range from my UTF-8 storage without copying that range first."

	| byteStream |
	byteStream := bytes readStream.
	byteStream position: start - 1.
	^ String streamContents: [ :stream |
			  [ byteStream position < end ] whileTrue: [
					  | codePoint |
					  codePoint := decoder nextCodePointFromStream: byteStream.
					  (codePoint > 255 and: [ stream originalContents isWideString not ]) ifTrue: [
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

	^ decoder ifNil: [ aStream next ] ifNotNil: [ decoder nextFromStream: aStream ]
]

{ #category : 'matching' }
PCRE2UTF8Input >> nextMatchStartOffsetAfter: zeroBasedOffset [
	"Answer the next zero-based PCRE2-8 code-unit offset after one Pharo character, or one past the end."

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
	"Answer decoded text between the inclusive 1-based PCRE2-8 code-unit indexes."

	start > end ifTrue: [ ^ String new ].
	decoder ifNil: [ ^ bytes copyFrom: start to: end ].
	^ self decodeBytesFrom: start to: end
]

{ #category : 'accessing' }
PCRE2UTF8Input >> size [

	^ bytes size
]
