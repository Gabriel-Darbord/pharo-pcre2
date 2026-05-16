"
Represents UTF-32 code-unit input for PCRE2.

Instances can be created from a Pharo string or from already-encoded bytes. String-backed inputs keep the original string for fast result reading. Byte-backed inputs keep native-endian UTF-32 storage for FFI calls and decode only the slices requested by match-result APIs.

PCRE2's 32-bit API counts offsets in 32-bit code units. In UTF mode those code units correspond to Unicode code points, which match Pharo character indexes for normal strings.
"
Class {
	#name : 'PCRE2UTF32Input',
	#superclass : 'Object',
	#instVars : [
		'bytes',
		'string'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'instance creation' }
PCRE2UTF32Input class >> bytes: bytesObject string: aString [

	^ self new
		  bytes: bytesObject string: aString;
		  yourself
]

{ #category : 'instance creation' }
PCRE2UTF32Input class >> fromBigEndianBytes: aByteCollection [
	"Answer input from UTF-32 big-endian bytes, normalizing to native endianness when needed."

	^ self fromNativeEndianBytes:
		  (PCRE2WideInputBytes
			   normalizeBigEndianBytes: aByteCollection
			   width: 4)
]

{ #category : 'instance creation' }
PCRE2UTF32Input class >> fromBytes: aByteCollection [
	"Answer input from native-endian UTF-32 bytes."

	^ self fromNativeEndianBytes: aByteCollection
]

{ #category : 'instance creation' }
PCRE2UTF32Input class >> fromBytesDetectingBOM: aByteCollection [
	"Answer input from UTF-32 bytes, using and stripping a byte-order mark when present. Bytes without a BOM are treated as native-endian."

	(PCRE2WideInputBytes hasBigEndianBOM: aByteCollection width: 4)
		ifTrue: [
			^ self fromBigEndianBytes:
				  (PCRE2WideInputBytes bytesAfterBOM: aByteCollection byteCount: 4) ].
	(PCRE2WideInputBytes hasLittleEndianBOM: aByteCollection width: 4)
		ifTrue: [
			^ self fromLittleEndianBytes:
				  (PCRE2WideInputBytes bytesAfterBOM: aByteCollection byteCount: 4) ].
	^ self fromNativeEndianBytes: aByteCollection
]

{ #category : 'instance creation' }
PCRE2UTF32Input class >> fromBytesWithBOM: aByteCollection [
	"Answer input from UTF-32 bytes that must start with a byte-order mark. The BOM is stripped before matching."

	((PCRE2WideInputBytes hasBigEndianBOM: aByteCollection width: 4) or: [
		 PCRE2WideInputBytes hasLittleEndianBOM: aByteCollection width: 4 ])
		ifFalse: [
		PCRE2Error signal: 'UTF-32 input bytes do not start with a BOM' ].
	^ self fromBytesDetectingBOM: aByteCollection
]

{ #category : 'instance creation' }
PCRE2UTF32Input class >> fromLittleEndianBytes: aByteCollection [
	"Answer input from UTF-32 little-endian bytes, normalizing to native endianness when needed."

	^ self fromNativeEndianBytes: (PCRE2WideInputBytes
			   normalizeLittleEndianBytes: aByteCollection
			   width: 4)
]

{ #category : 'instance creation' }
PCRE2UTF32Input class >> fromNativeEndianBytes: aByteCollection [
	"Answer input from native-endian UTF-32 bytes. The byte size must be a multiple of four."

	PCRE2WideInputBytes
		validateByteSize: aByteCollection
		multipleOf: 4
		message:
		'UTF-32 input bytes must have a byte size divisible by four'.
	^ self bytes: aByteCollection copy string: nil
]

{ #category : 'instance creation' }
PCRE2UTF32Input class >> fromString: aString [
	"Encode a Pharo string as native-endian UTF-32 code units for PCRE2-32."

	| bytes copy |
	copy := aString copy.
	bytes := ByteArray new: copy size * 4.
	1 to: copy size do: [ :index |
		bytes
			uint32AtOffset: 4 * (index - 1)
			put: (copy at: index) asInteger ].
	^ self bytes: bytes string: copy
]

{ #category : 'converting' }
PCRE2UTF32Input >> asPCRE2UTF32Input [
	"Answer myself so matcher APIs can accept either Strings or prepared UTF-32 inputs."

	^ self
]

{ #category : 'accessing' }
PCRE2UTF32Input >> bytes [

	^ bytes
]

{ #category : 'initialization' }
PCRE2UTF32Input >> bytes: bytesObject string: aString [

	bytes := bytesObject.
	string := aString
]

{ #category : 'decoding' }
PCRE2UTF32Input >> characterCountUpToByteOffset: codeUnitOffset [
	"Compatibility with UTF-8 input protocol; for UTF-32 the offset is already a character/code-unit count."

	^ codeUnitOffset
]

{ #category : 'decoding' }
PCRE2UTF32Input >> characterRangeFromStartOffset: zeroBasedStartOffset endOffset: exclusiveEndOffset [
	"Translate PCRE2's zero-based UTF-32 code-unit offsets to a 1-based Pharo character range."

	^ zeroBasedStartOffset + 1 to: exclusiveEndOffset
]

{ #category : 'decoding' }
PCRE2UTF32Input >> decodeBytes: aByteCollection [
	"Decode a native-endian UTF-32 byte collection."

	^ String streamContents: [ :stream |
		  1 to: aByteCollection size by: 4 do: [ :index |
			  stream nextPut:
				  (Character value: (aByteCollection uint32AtOffset: index - 1)) ] ]
]

{ #category : 'accessing' }
PCRE2UTF32Input >> decoder [

	^ nil
]

{ #category : 'decoding' }
PCRE2UTF32Input >> nextFromStream: aStream [
	"Answer the next character from a stream over my UTF-32 byte storage."

	| codeUnit |
	codeUnit := ByteArray new: 4.
	1 to: 4 do: [ :index | codeUnit at: index put: aStream next ].
	^ Character value: (codeUnit uint32AtOffset: 0)
]

{ #category : 'matching' }
PCRE2UTF32Input >> nextMatchStartOffsetAfter: zeroBasedOffset [
	"Answer the next zero-based UTF-32 code-unit offset after one character, or one past the end."

	zeroBasedOffset >= self size ifTrue: [ ^ self size + 1 ].
	^ zeroBasedOffset + 1
]

{ #category : 'decoding' }
PCRE2UTF32Input >> readFrom: start to: end [
	"Answer the substring stored between the given 1-based UTF-32 code-unit indexes."

	| byteStart slice |
	start > end ifTrue: [ ^ String new ].
	string ifNotNil: [ ^ string copyFrom: start to: end ].
	byteStart := start - 1.
	byteStart := byteStart * 4 + 1.
	slice := bytes copyFrom: byteStart to: end * 4.
	^ self decodeBytes: slice
]

{ #category : 'matching' }
PCRE2UTF32Input >> recordOn: aPCRE2Match [

	aPCRE2Match input: self
]

{ #category : 'accessing' }
PCRE2UTF32Input >> size [

	^ string ifNil: [ bytes size // 4 ] ifNotNil: [ string size ]
]
