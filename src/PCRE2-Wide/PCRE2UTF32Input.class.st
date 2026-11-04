"
Prepared UTF-32 input for PCRE2-32, where each code unit is one code point and one character, so offsets translate by arithmetic. A string-backed input keeps the string; a byte-backed one keeps native-endian bytes and decodes only the slices asked for.
"
Class {
	#name : 'PCRE2UTF32Input',
	#superclass : 'PCRE2Input',
	#instVars : [
		'string'
	],
	#category : 'PCRE2-Wide',
	#package : 'PCRE2-Wide'
}

{ #category : 'instance creation' }
PCRE2UTF32Input class >> bytes: bytesObject string: aString [

	^ self new
		  bytes: bytesObject string: aString;
		  yourself
]

{ #category : 'instance creation' }
PCRE2UTF32Input class >> fromBigEndianBytes: aByteCollection [

	^ self fromNativeEndianBytes: (PCRE2WideInputBytes normalizeBigEndianBytes: aByteCollection width: 4)
]

{ #category : 'instance creation' }
PCRE2UTF32Input class >> fromBytes: aByteCollection [

	^ self fromNativeEndianBytes: aByteCollection
]

{ #category : 'instance creation' }
PCRE2UTF32Input class >> fromBytesDetectingBOM: aByteCollection [
	"Without a byte-order mark, the bytes are taken as native-endian."

	(PCRE2WideInputBytes hasBigEndianBOM: aByteCollection width: 4) ifTrue: [
		^ self fromBigEndianBytes: (PCRE2WideInputBytes bytesAfterBOM: aByteCollection byteCount: 4) ].
	(PCRE2WideInputBytes hasLittleEndianBOM: aByteCollection width: 4) ifTrue: [
		^ self fromLittleEndianBytes: (PCRE2WideInputBytes bytesAfterBOM: aByteCollection byteCount: 4) ].
	^ self fromNativeEndianBytes: aByteCollection
]

{ #category : 'instance creation' }
PCRE2UTF32Input class >> fromBytesWithBOM: aByteCollection [

	((PCRE2WideInputBytes hasBigEndianBOM: aByteCollection width: 4) or: [
		 PCRE2WideInputBytes hasLittleEndianBOM: aByteCollection width: 4 ]) ifFalse: [
		PCRE2Error signal: 'UTF-32 input bytes do not start with a BOM' ].
	^ self fromBytesDetectingBOM: aByteCollection
]

{ #category : 'instance creation' }
PCRE2UTF32Input class >> fromLittleEndianBytes: aByteCollection [

	^ self fromNativeEndianBytes: (PCRE2WideInputBytes normalizeLittleEndianBytes: aByteCollection width: 4)
]

{ #category : 'instance creation' }
PCRE2UTF32Input class >> fromNativeEndianBytes: aByteCollection [

	PCRE2WideInputBytes
		validateByteSize: aByteCollection
		multipleOf: 4
		message: 'UTF-32 input bytes must have a byte size divisible by four'.
	^ self bytes: aByteCollection copy string: nil
]

{ #category : 'instance creation' }
PCRE2UTF32Input class >> fromString: aString [
	"Encode a Pharo string as native-endian UTF-32 code units for PCRE2-32."

	| bytes copy |
	copy := aString copy.
	bytes := ByteArray new: copy size * 4.
	1 to: copy size do: [ :index | bytes uint32AtOffset: 4 * (index - 1) put: (copy at: index) asInteger ].
	^ self bytes: bytes string: copy
]

{ #category : 'converting' }
PCRE2UTF32Input >> asPCRE2UTF32Input [

	^ self
]

{ #category : 'initialization' }
PCRE2UTF32Input >> bytes: bytesObject string: aString [

	self bytes: bytesObject.
	string := aString
]

{ #category : 'decoding' }
PCRE2UTF32Input >> characterCountUpToCodeUnitOffset: codeUnitOffset [
	"Each code unit is one character."

	^ codeUnitOffset
]

{ #category : 'decoding' }
PCRE2UTF32Input >> characterCountUpToCodeUnitOffset: codeUnitOffset fromCodeUnitOffset: knownCodeUnitOffset characterCount: knownCharacterCount [
	"Each code unit is one character, so the known prefix is not needed."

	^ codeUnitOffset
]

{ #category : 'decoding' }
PCRE2UTF32Input >> characterRangeFromStartOffset: zeroBasedStartOffset endOffset: exclusiveEndOffset [

	^ zeroBasedStartOffset + 1 to: exclusiveEndOffset
]

{ #category : 'decoding' }
PCRE2UTF32Input >> decodeBytes: aByteCollection [

	^ self decodeBytes: aByteCollection from: 1 to: aByteCollection size
]

{ #category : 'decoding' }
PCRE2UTF32Input >> decodeBytes: aByteCollection from: byteStart to: byteEnd [
	"Decode a 1-based inclusive byte range from native-endian UTF-32 storage."

	^ String streamContents: [ :stream |
		  byteStart to: byteEnd by: 4 do: [ :index | stream nextPut: (Character value: (aByteCollection uint32AtOffset: index - 1)) ] ]
]

{ #category : 'decoding' }
PCRE2UTF32Input >> nextFromStream: aStream [

	| codeUnit |
	codeUnit := ByteArray new: 4.
	1 to: 4 do: [ :index | codeUnit at: index put: aStream next ].
	^ Character value: (codeUnit uint32AtOffset: 0)
]

{ #category : 'matching' }
PCRE2UTF32Input >> nextMatchStartOffsetAfter: zeroBasedOffset [

	zeroBasedOffset >= self size ifTrue: [ ^ self size + 1 ].
	^ zeroBasedOffset + 1
]

{ #category : 'decoding' }
PCRE2UTF32Input >> readFrom: start to: end [
	"Answer decoded text between the inclusive 1-based PCRE2-32 code-unit indexes."

	| byteStart |
	start > end ifTrue: [ ^ String new ].
	string ifNotNil: [ ^ string copyFrom: start to: end ].
	byteStart := start - 1.
	byteStart := byteStart * 4 + 1.
	^ self decodeBytes: bytes from: byteStart to: end * 4
]

{ #category : 'accessing' }
PCRE2UTF32Input >> size [

	^ string ifNil: [ bytes size // 4 ] ifNotNil: [ string size ]
]
