"
UTF-8 code-unit input for PCRE2-8, from a Pharo string, a prepared input, or encoded bytes. ASCII ByteStrings are kept as they are, with no decoder; other strings and byte-backed inputs keep the decoder that translates code-unit offsets back to character ranges. Matchers and compilers accept me directly to reuse prepared input across calls.
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
	"Answer input from encoded UTF-8 bytes, copied so that callers can reuse their storage."

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
PCRE2UTF8Input >> decodeBytes: collection [

	^ decoder ifNil: [ collection ] ifNotNil: [ (self class bytes: collection decoder: decoder) readFrom: 1 to: collection size ]
]

{ #category : 'decoding' }
PCRE2UTF8Input >> decodeBytesFrom: start to: end [
	"Decode a 1-based inclusive byte range from my UTF-8 storage without copying that range first."

	| byteStream |
	byteStream := ReadStream on: bytes from: start to: end.
	^ String streamContents: [ :stream |
			  [ byteStream position < end ] whileTrue: [
					  | codePoint |
					  codePoint := self nextCodePointFromStream: byteStream.
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
PCRE2UTF8Input >> nextCodePointFromStream: stream [
	"PCRE2 treats U+FEFF as subject data; Zinc's decoder discards it."

	| position |
	(stream peek = 239 and: [ stream size - stream position >= 3 ]) ifTrue: [
			position := stream position.
			(stream next: 3) asByteArray = #[ 239 187 191 ] ifTrue: [ ^ 16rFEFF ].
			stream position: position ].
	^ decoder nextCodePointFromStream: stream
]

{ #category : 'decoding' }
PCRE2UTF8Input >> nextFromStream: stream [

	^ decoder ifNil: [ stream next ] ifNotNil: [ Character value: (self nextCodePointFromStream: stream) ]
]

{ #category : 'decoding' }
PCRE2UTF8Input >> nextMatchStartOffsetAfter: zeroBasedOffset [
	"Answer the next zero-based PCRE2-8 code-unit offset after one Pharo character, or one past the end."

	| stream |
	zeroBasedOffset >= self size ifTrue: [ ^ self size + 1 ].
	decoder ifNil: [ ^ zeroBasedOffset + 1 ].
	stream := ReadStream on: bytes.
	stream position: zeroBasedOffset.
	self nextFromStream: stream.
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
