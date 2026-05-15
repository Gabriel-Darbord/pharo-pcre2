"
Represents UTF-16 code-unit input for PCRE2.

Instances can be created from a Pharo string or from already-encoded bytes. String-backed inputs keep the original string for fast result reading. Byte-backed inputs keep native-endian UTF-16 storage for FFI calls and decode only the slices or character ranges requested by match-result APIs.

PCRE2's 16-bit API counts offsets in UTF-16 code units. Supplementary Unicode characters therefore occupy two native code units even though they are one Pharo Character.
"
Class {
	#name : 'PCRE2UTF16Input',
	#superclass : 'Object',
	#instVars : [
		'bytes',
		'string',
		'codeUnitStartOffsets'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'instance creation' }
PCRE2UTF16Input class >> bytes: bytesObject string: aString codeUnitStartOffsets: offsets [

	^ self new
		  bytes: bytesObject string: aString codeUnitStartOffsets: offsets;
		  yourself
]

{ #category : 'instance creation' }
PCRE2UTF16Input class >> fromBigEndianBytes: aByteCollection [
	"Answer input from UTF-16 big-endian bytes, normalizing to native endianness when needed."

	^ self fromNativeEndianBytes: (self nativeEndianIsLittle
			   ifTrue: [ self swapBytes: aByteCollection width: 2 ]
			   ifFalse: [ aByteCollection ])
]

{ #category : 'instance creation' }
PCRE2UTF16Input class >> fromBytes: aByteCollection [
	"Answer input from native-endian UTF-16 bytes."

	^ self fromNativeEndianBytes: aByteCollection
]

{ #category : 'instance creation' }
PCRE2UTF16Input class >> fromLittleEndianBytes: aByteCollection [
	"Answer input from UTF-16 little-endian bytes, normalizing to native endianness when needed."

	^ self fromNativeEndianBytes: (self nativeEndianIsLittle
			   ifTrue: [ aByteCollection ]
			   ifFalse: [ self swapBytes: aByteCollection width: 2 ])
]

{ #category : 'instance creation' }
PCRE2UTF16Input class >> fromNativeEndianBytes: aByteCollection [
	"Answer input from native-endian UTF-16 bytes. The byte size must be a multiple of two."

	self validateByteSize: aByteCollection multipleOf: 2.
	^ self
		  bytes: aByteCollection copy
		  string: nil
		  codeUnitStartOffsets: nil
]

{ #category : 'instance creation' }
PCRE2UTF16Input class >> fromString: aString [
	"Encode a Pharo string as native-endian UTF-16 code units for PCRE2-16."

	| bytes codeUnitCount codeUnitOffset copy offsets |
	copy := aString copy.
	codeUnitCount := 0.
	1 to: copy size do: [ :index |
		(copy at: index) asInteger <= 16rFFFF
			ifTrue: [ codeUnitCount := codeUnitCount + 1 ]
			ifFalse: [ codeUnitCount := codeUnitCount + 2 ] ].

	bytes := ByteArray new: codeUnitCount * 2.
	offsets := Array new: copy size + 1.
	codeUnitOffset := 0.
	1 to: copy size do: [ :index |
		| codePoint |
		offsets at: index put: codeUnitOffset.
		codePoint := (copy at: index) asInteger.
		codePoint <= 16rFFFF
			ifTrue: [
				bytes uint16AtOffset: codeUnitOffset * 2 put: codePoint.
				codeUnitOffset := codeUnitOffset + 1 ]
			ifFalse: [
				| high low nextCodeUnitOffset scalar |
				scalar := codePoint - 16r10000.
				high := 16rD800 + (scalar bitShift: -10).
				low := 16rDC00 + (scalar bitAnd: 16r3FF).
				nextCodeUnitOffset := codeUnitOffset + 1.
				bytes uint16AtOffset: codeUnitOffset * 2 put: high.
				bytes uint16AtOffset: nextCodeUnitOffset * 2 put: low.
				codeUnitOffset := codeUnitOffset + 2 ] ].
	offsets at: copy size + 1 put: codeUnitOffset.
	^ self bytes: bytes string: copy codeUnitStartOffsets: offsets
]

{ #category : 'testing' }
PCRE2UTF16Input class >> nativeEndianIsLittle [

	| bytes |
	bytes := ByteArray new: 2.
	bytes uint16AtOffset: 0 put: 16r0102.
	^ (bytes at: 1) = 16r02
]

{ #category : 'converting' }
PCRE2UTF16Input class >> swapBytes: aByteCollection width: width [

	| swapped |
	self validateByteSize: aByteCollection multipleOf: width.
	swapped := ByteArray new: aByteCollection size.
	1 to: aByteCollection size by: width do: [ :start |
		1 to: width do: [ :offset |
			swapped
				at: start + offset - 1
				put: (aByteCollection at: start + width - offset) ] ].
	^ swapped
]

{ #category : 'validating' }
PCRE2UTF16Input class >> validateByteSize: aByteCollection multipleOf: width [

	(aByteCollection size rem: width) = 0 ifFalse: [
		PCRE2Error signal: 'UTF-16 input bytes must have an even byte size' ]
]

{ #category : 'converting' }
PCRE2UTF16Input >> asPCRE2UTF16Input [
	"Answer myself so matcher APIs can accept either Strings or prepared UTF-16 inputs."

	^ self
]

{ #category : 'accessing' }
PCRE2UTF16Input >> bytes [

	^ bytes
]

{ #category : 'initialization' }
PCRE2UTF16Input >> bytes: bytesObject string: aString codeUnitStartOffsets: offsets [

	bytes := bytesObject.
	string := aString.
	codeUnitStartOffsets := offsets
]

{ #category : 'decoding' }
PCRE2UTF16Input >> characterCountUpToByteOffset: codeUnitOffset [
	"Compatibility with UTF-8 input protocol; for UTF-16 the offset is a code-unit count."

	codeUnitStartOffsets ifNotNil: [
		^ self mappedCharacterCountUpToCodeUnitOffset: codeUnitOffset ].
	^ self scannedCharacterCountUpToCodeUnitOffset: codeUnitOffset
]

{ #category : 'decoding' }
PCRE2UTF16Input >> characterRangeFromStartOffset: zeroBasedStartOffset endOffset: exclusiveEndOffset [
	"Translate PCRE2's zero-based UTF-16 code-unit offsets to a 1-based Pharo character range."

	^ (self characterCountUpToByteOffset: zeroBasedStartOffset) + 1 to:
	  (self characterCountUpToByteOffset: exclusiveEndOffset)
]

{ #category : 'decoding' }
PCRE2UTF16Input >> codePointFromHighSurrogate: highSurrogate lowSurrogate: lowSurrogate [

	| highBits lowBits |
	highBits := highSurrogate - 16rD800.
	lowBits := lowSurrogate - 16rDC00.
	^ 16r10000 + (highBits bitShift: 10) + lowBits
]

{ #category : 'decoding' }
PCRE2UTF16Input >> decodeBytes: aByteCollection [
	"Decode a native-endian UTF-16 byte collection."

	^ String streamContents: [ :stream |
		  | byteIndex |
		  byteIndex := 1.
		  [ byteIndex <= aByteCollection size ] whileTrue: [
			  | first |
			  first := aByteCollection uint16AtOffset: byteIndex - 1.
			  ((self isHighSurrogate: first) and: [
				   byteIndex + 2 <= aByteCollection size ])
				  ifTrue: [
					  | second |
					  second := aByteCollection uint16AtOffset: byteIndex + 1.
					  (self isLowSurrogate: second)
						  ifTrue: [
							  stream nextPut: (Character value:
									   (self
										    codePointFromHighSurrogate: first
										    lowSurrogate: second)).
							  byteIndex := byteIndex + 4 ]
						  ifFalse: [
							  stream nextPut: (Character value: first).
							  byteIndex := byteIndex + 2 ] ]
				  ifFalse: [
					  stream nextPut: (Character value: first).
					  byteIndex := byteIndex + 2 ] ] ]
]

{ #category : 'accessing' }
PCRE2UTF16Input >> decoder [

	^ nil
]

{ #category : 'decoding' }
PCRE2UTF16Input >> isHighSurrogate: codeUnit [

	^ codeUnit between: 16rD800 and: 16rDBFF
]

{ #category : 'decoding' }
PCRE2UTF16Input >> isLowSurrogate: codeUnit [

	^ codeUnit between: 16rDC00 and: 16rDFFF
]

{ #category : 'decoding' }
PCRE2UTF16Input >> mappedCharacterCountUpToCodeUnitOffset: codeUnitOffset [

	| count |
	codeUnitOffset <= 0 ifTrue: [ ^ 0 ].
	codeUnitOffset >= self size ifTrue: [ ^ string size ].
	count := 0.
	[
	count < string size and: [
		(codeUnitStartOffsets at: count + 2) <= codeUnitOffset ] ]
		whileTrue: [ count := count + 1 ].
	^ count
]

{ #category : 'decoding' }
PCRE2UTF16Input >> nextFromStream: aStream [
	"Answer the next character from a stream over my UTF-16 byte storage."

	| first firstBytes |
	firstBytes := ByteArray new: 2.
	1 to: 2 do: [ :index | firstBytes at: index put: aStream next ].
	first := firstBytes uint16AtOffset: 0.
	((self isHighSurrogate: first) and: [ aStream atEnd not ]) ifFalse: [
		^ Character value: first ].
	^ self nextSurrogatePairFromStream: aStream highSurrogate: first
]

{ #category : 'decoding' }
PCRE2UTF16Input >> nextSurrogatePairFromStream: aStream highSurrogate: highSurrogate [

	| lowSurrogate secondBytes |
	secondBytes := ByteArray new: 2.
	1 to: 2 do: [ :index | secondBytes at: index put: aStream next ].
	lowSurrogate := secondBytes uint16AtOffset: 0.
	(self isLowSurrogate: lowSurrogate) ifFalse: [
		^ Character value: highSurrogate ].
	^ Character value: (self
			   codePointFromHighSurrogate: highSurrogate
			   lowSurrogate: lowSurrogate)
]

{ #category : 'decoding' }
PCRE2UTF16Input >> readFrom: start to: end [
	"Answer the substring stored between the given 1-based UTF-16 code-unit indexes."

	| byteStart characterEnd characterStart slice |
	start > end ifTrue: [ ^ String new ].
	string ifNotNil: [
		characterStart := (self characterCountUpToByteOffset: start - 1) + 1.
		characterEnd := self characterCountUpToByteOffset: end.
		characterStart > characterEnd ifTrue: [ ^ String new ].
		^ string copyFrom: characterStart to: characterEnd ].
	byteStart := start - 1.
	byteStart := byteStart * 2 + 1.
	slice := bytes copyFrom: byteStart to: end * 2.
	^ self decodeBytes: slice
]

{ #category : 'matching' }
PCRE2UTF16Input >> recordOn: aPCRE2Match [

	aPCRE2Match input: self
]

{ #category : 'decoding' }
PCRE2UTF16Input >> scannedCharacterCountUpToCodeUnitOffset: codeUnitOffset [

	| byteIndex codeUnitsSeen count limit |
	codeUnitOffset <= 0 ifTrue: [ ^ 0 ].
	limit := codeUnitOffset min: self size.
	byteIndex := 1.
	codeUnitsSeen := 0.
	count := 0.
	[ codeUnitsSeen < limit and: [ byteIndex <= bytes size ] ]
		whileTrue: [
			| first |
			first := bytes uint16AtOffset: byteIndex - 1.
			((self isHighSurrogate: first) and: [
				 codeUnitsSeen + 2 <= limit and: [
					 byteIndex + 2 <= bytes size and: [
						 self isLowSurrogate: (bytes uint16AtOffset: byteIndex + 1) ] ] ])
				ifTrue: [
					byteIndex := byteIndex + 4.
					codeUnitsSeen := codeUnitsSeen + 2.
					count := count + 1 ]
				ifFalse: [
					((self isHighSurrogate: first) and: [ codeUnitsSeen + 1 < limit ])
						ifTrue: [ "The requested offset splits a surrogate pair; answer the previous character boundary."
							^ count ].
					byteIndex := byteIndex + 2.
					codeUnitsSeen := codeUnitsSeen + 1.
					count := count + 1 ] ].
	^ count
]

{ #category : 'accessing' }
PCRE2UTF16Input >> size [

	^ codeUnitStartOffsets
		  ifNil: [ bytes size // 2 ]
		  ifNotNil: [ codeUnitStartOffsets last ]
]
