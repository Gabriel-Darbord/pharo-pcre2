"
Represents UTF-16 code-unit input for PCRE2-16.

Instances can be created from a Pharo string or from already-encoded bytes. String-backed inputs keep the original string and a character-to-code-unit offset map for fast result reading. Byte-backed inputs keep native-endian UTF-16 storage for FFI calls and decode only the requested slices or character ranges.

For PCRE2-16, offsets count UTF-16 code units. Supplementary Unicode characters therefore occupy two PCRE2 code units even though they are one Pharo Character.
"
Class {
	#name : 'PCRE2UTF16Input',
	#superclass : 'PCRE2Input',
	#instVars : [
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

	^ self fromNativeEndianBytes: (PCRE2WideInputBytes normalizeBigEndianBytes: aByteCollection width: 2)
]

{ #category : 'instance creation' }
PCRE2UTF16Input class >> fromBytes: aByteCollection [
	"Answer input from native-endian UTF-16 bytes."

	^ self fromNativeEndianBytes: aByteCollection
]

{ #category : 'instance creation' }
PCRE2UTF16Input class >> fromBytesDetectingBOM: aByteCollection [
	"Answer input from UTF-16 bytes, using and stripping a byte-order mark when present. Bytes without a BOM are treated as native-endian."

	(PCRE2WideInputBytes hasBigEndianBOM: aByteCollection width: 2) ifTrue: [
		^ self fromBigEndianBytes: (PCRE2WideInputBytes bytesAfterBOM: aByteCollection byteCount: 2) ].
	(PCRE2WideInputBytes hasLittleEndianBOM: aByteCollection width: 2) ifTrue: [
		^ self fromLittleEndianBytes: (PCRE2WideInputBytes bytesAfterBOM: aByteCollection byteCount: 2) ].
	^ self fromNativeEndianBytes: aByteCollection
]

{ #category : 'instance creation' }
PCRE2UTF16Input class >> fromBytesWithBOM: aByteCollection [
	"Answer input from UTF-16 bytes that must start with a byte-order mark. The BOM is stripped before matching."

	((PCRE2WideInputBytes hasBigEndianBOM: aByteCollection width: 2) or: [
		 PCRE2WideInputBytes hasLittleEndianBOM: aByteCollection width: 2 ]) ifFalse: [
		PCRE2Error signal: 'UTF-16 input bytes do not start with a BOM' ].
	^ self fromBytesDetectingBOM: aByteCollection
]

{ #category : 'instance creation' }
PCRE2UTF16Input class >> fromLittleEndianBytes: aByteCollection [
	"Answer input from UTF-16 little-endian bytes, normalizing to native endianness when needed."

	^ self fromNativeEndianBytes: (PCRE2WideInputBytes normalizeLittleEndianBytes: aByteCollection width: 2)
]

{ #category : 'instance creation' }
PCRE2UTF16Input class >> fromNativeEndianBytes: aByteCollection [
	"Answer input from native-endian UTF-16 bytes. The byte size must be a multiple of two."

	PCRE2WideInputBytes validateByteSize: aByteCollection multipleOf: 2 message: 'UTF-16 input bytes must have an even byte size'.
	^ self bytes: aByteCollection copy string: nil codeUnitStartOffsets: nil
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

{ #category : 'converting' }
PCRE2UTF16Input >> asPCRE2UTF16Input [
	"Answer myself so matcher APIs can accept either Strings or prepared UTF-16 inputs."

	^ self
]

{ #category : 'initialization' }
PCRE2UTF16Input >> bytes: bytesObject string: aString codeUnitStartOffsets: offsets [

	self bytes: bytesObject.
	string := aString.
	codeUnitStartOffsets := offsets
]

{ #category : 'decoding' }
PCRE2UTF16Input >> characterCountUpToCodeUnitOffset: codeUnitOffset [
	"For PCRE2-16, code-unit offsets count UTF-16 units; surrogate pairs are two code units but one Pharo character."

	^ self characterCountUpToCodeUnitOffset: codeUnitOffset fromCodeUnitOffset: 0 characterCount: 0
]

{ #category : 'decoding' }
PCRE2UTF16Input >> characterCountUpToCodeUnitOffset: codeUnitOffset fromCodeUnitOffset: knownCodeUnitOffset characterCount: knownCharacterCount [
	"Continue counting UTF-16 characters from a known code-unit offset. String-backed inputs use the offset map; byte-backed inputs fall back to scanning from the beginning."

	codeUnitOffset <= 0 ifTrue: [ ^ 0 ].
	codeUnitOffset = knownCodeUnitOffset ifTrue: [ ^ knownCharacterCount ].
	codeUnitOffset < knownCodeUnitOffset ifTrue: [
		^ self characterCountUpToCodeUnitOffset: codeUnitOffset fromCodeUnitOffset: 0 characterCount: 0 ].
	codeUnitStartOffsets ifNotNil: [
			^ self
				  mappedCharacterCountUpToCodeUnitOffset: codeUnitOffset
				  fromCodeUnitOffset: knownCodeUnitOffset
				  characterCount: knownCharacterCount ].
	^ self scannedCharacterCountUpToCodeUnitOffset: codeUnitOffset
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

	^ self decodeBytes: aByteCollection from: 1 to: aByteCollection size
]

{ #category : 'decoding' }
PCRE2UTF16Input >> decodeBytes: aByteCollection from: byteStart to: byteEnd [
	"Decode a 1-based inclusive byte range from native-endian UTF-16 storage."

	^ String streamContents: [ :stream |
			  | byteIndex |
			  byteIndex := byteStart.
			  [ byteIndex <= byteEnd ] whileTrue: [
					  | first |
					  first := aByteCollection uint16AtOffset: byteIndex - 1.
					  ((self isHighSurrogate: first) and: [ byteIndex + 2 <= byteEnd ])
						  ifTrue: [
								  | second |
								  second := aByteCollection uint16AtOffset: byteIndex + 1.
								  (self isLowSurrogate: second)
									  ifTrue: [
											  stream nextPut: (Character value: (self codePointFromHighSurrogate: first lowSurrogate: second)).
											  byteIndex := byteIndex + 4 ]
									  ifFalse: [
											  stream nextPut: (Character value: first).
											  byteIndex := byteIndex + 2 ] ]
						  ifFalse: [
								  stream nextPut: (Character value: first).
								  byteIndex := byteIndex + 2 ] ] ]
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
	[ count < string size and: [ (codeUnitStartOffsets at: count + 2) <= codeUnitOffset ] ] whileTrue: [ count := count + 1 ].
	^ count
]

{ #category : 'decoding' }
PCRE2UTF16Input >> mappedCharacterCountUpToCodeUnitOffset: codeUnitOffset fromCodeUnitOffset: knownCodeUnitOffset characterCount: knownCharacterCount [
	"Use the string-backed offset map to continue from a known character count instead of scanning code units."

	| count |
	codeUnitOffset <= 0 ifTrue: [ ^ 0 ].
	codeUnitOffset = knownCodeUnitOffset ifTrue: [ ^ knownCharacterCount ].
	codeUnitOffset >= self size ifTrue: [ ^ string size ].
	count := knownCharacterCount.
	[ count < string size and: [ (codeUnitStartOffsets at: count + 2) <= codeUnitOffset ] ] whileTrue: [ count := count + 1 ].
	^ count
]

{ #category : 'decoding' }
PCRE2UTF16Input >> nextFromStream: aStream [
	"Answer the next character from a stream over my UTF-16 byte storage."

	| first firstBytes |
	firstBytes := ByteArray new: 2.
	1 to: 2 do: [ :index | firstBytes at: index put: aStream next ].
	first := firstBytes uint16AtOffset: 0.
	((self isHighSurrogate: first) and: [ aStream atEnd not ]) ifFalse: [ ^ Character value: first ].
	^ self nextSurrogatePairFromStream: aStream highSurrogate: first
]

{ #category : 'matching' }
PCRE2UTF16Input >> nextMatchStartOffsetAfter: zeroBasedOffset [
	"Answer the next zero-based PCRE2-16 code-unit offset after one Pharo character, or one past the end."

	| first nextOffset |
	zeroBasedOffset >= self size ifTrue: [ ^ self size + 1 ].
	first := bytes uint16AtOffset: zeroBasedOffset * 2.
	nextOffset := zeroBasedOffset + 1.
	((self isHighSurrogate: first) and: [ nextOffset < self size ]) ifTrue: [ ^ zeroBasedOffset + 2 ].
	^ nextOffset
]

{ #category : 'decoding' }
PCRE2UTF16Input >> nextSurrogatePairFromStream: aStream highSurrogate: highSurrogate [

	| lowSurrogate secondBytes |
	secondBytes := ByteArray new: 2.
	1 to: 2 do: [ :index | secondBytes at: index put: aStream next ].
	lowSurrogate := secondBytes uint16AtOffset: 0.
	(self isLowSurrogate: lowSurrogate) ifFalse: [ ^ Character value: highSurrogate ].
	^ Character value: (self codePointFromHighSurrogate: highSurrogate lowSurrogate: lowSurrogate)
]

{ #category : 'decoding' }
PCRE2UTF16Input >> readFrom: start to: end [
	"Answer decoded text between the inclusive 1-based PCRE2-16 code-unit indexes."

	| byteStart characterRange |
	start > end ifTrue: [ ^ String new ].
	string ifNotNil: [
			characterRange := self characterRangeFromStartOffset: start - 1 endOffset: end.
			characterRange first > characterRange last ifTrue: [ ^ String new ].
			^ string copyFrom: characterRange first to: characterRange last ].
	byteStart := start - 1.
	byteStart := byteStart * 2 + 1.
	^ self decodeBytes: bytes from: byteStart to: end * 2
]

{ #category : 'decoding' }
PCRE2UTF16Input >> scannedCharacterCountUpToCodeUnitOffset: codeUnitOffset [

	| byteIndex codeUnitsSeen count limit |
	codeUnitOffset <= 0 ifTrue: [ ^ 0 ].
	limit := codeUnitOffset min: self size.
	byteIndex := 1.
	codeUnitsSeen := 0.
	count := 0.
	[ codeUnitsSeen < limit and: [ byteIndex <= bytes size ] ] whileTrue: [
			| first |
			first := bytes uint16AtOffset: byteIndex - 1.
			((self isHighSurrogate: first) and: [
				 codeUnitsSeen + 2 <= limit and: [
					 byteIndex + 2 <= bytes size and: [ self isLowSurrogate: (bytes uint16AtOffset: byteIndex + 1) ] ] ])
				ifTrue: [
						byteIndex := byteIndex + 4.
						codeUnitsSeen := codeUnitsSeen + 2.
						count := count + 1 ]
				ifFalse: [
						((self isHighSurrogate: first) and: [ codeUnitsSeen + 1 < limit ]) ifTrue: [ "The requested offset splits a surrogate pair; answer the previous character boundary."
							^ count ].
						byteIndex := byteIndex + 2.
						codeUnitsSeen := codeUnitsSeen + 1.
						count := count + 1 ] ].
	^ count
]

{ #category : 'accessing' }
PCRE2UTF16Input >> size [

	^ codeUnitStartOffsets ifNil: [ bytes size // 2 ] ifNotNil: [ codeUnitStartOffsets last ]
]
