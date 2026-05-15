"
Represents a Pharo string prepared as UTF-32 input for PCRE2.

PCRE2's 32-bit API counts offsets in 32-bit code units. In UTF mode those code units correspond to Unicode code points, which match Pharo character indexes for normal strings. The object keeps native-endian 32-bit storage for FFI calls and a copied Pharo string for reading match results back without byte-offset translation.
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

{ #category : 'decoding' }
PCRE2UTF32Input >> readFrom: start to: end [
	"Answer the substring stored between the given 1-based UTF-32 code-unit indexes."

	^ string copyFrom: start to: end
]

{ #category : 'matching' }
PCRE2UTF32Input >> recordOn: aPCRE2Match [

	aPCRE2Match input: self
]

{ #category : 'accessing' }
PCRE2UTF32Input >> size [

	^ string size
]
