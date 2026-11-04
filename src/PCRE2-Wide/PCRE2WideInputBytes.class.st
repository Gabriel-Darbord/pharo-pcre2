"
Byte-order helpers shared by the UTF-16 and UTF-32 inputs: code-unit alignment, byte-order marks, host endianness, and conversion of explicit-endian bytes to the native order the inputs store.
"
Class {
	#name : 'PCRE2WideInputBytes',
	#superclass : 'Object',
	#category : 'PCRE2-Wide',
	#package : 'PCRE2-Wide'
}

{ #category : 'private' }
PCRE2WideInputBytes class >> bigEndianBOMForWidth: width [

	width = 2 ifTrue: [ ^ #[ 254 255 ] ].
	width = 4 ifTrue: [ ^ #[ 0 0 254 255 ] ].
	PCRE2Error signal: 'Unsupported BOM code-unit width'
]

{ #category : 'converting' }
PCRE2WideInputBytes class >> bytesAfterBOM: aByteCollection byteCount: bomByteCount [

	| byteSize |
	byteSize := aByteCollection size.
	byteSize <= bomByteCount ifTrue: [ ^ ByteArray new ].
	^ aByteCollection copyFrom: bomByteCount + 1 to: byteSize
]

{ #category : 'testing' }
PCRE2WideInputBytes class >> hasBigEndianBOM: aByteCollection width: width [

	^ self startsWith: aByteCollection bytes: (self bigEndianBOMForWidth: width)
]

{ #category : 'testing' }
PCRE2WideInputBytes class >> hasLittleEndianBOM: aByteCollection width: width [

	^ self startsWith: aByteCollection bytes: (self littleEndianBOMForWidth: width)
]

{ #category : 'private' }
PCRE2WideInputBytes class >> littleEndianBOMForWidth: width [

	width = 2 ifTrue: [ ^ #[ 255 254 ] ].
	width = 4 ifTrue: [ ^ #[ 255 254 0 0 ] ].
	PCRE2Error signal: 'Unsupported BOM code-unit width'
]

{ #category : 'testing' }
PCRE2WideInputBytes class >> nativeEndianIsLittle [

	^ EndianDetector isLittleEndian
]

{ #category : 'converting' }
PCRE2WideInputBytes class >> normalizeBigEndianBytes: aByteCollection width: width [

	^ self nativeEndianIsLittle
		  ifTrue: [ self swapBytes: aByteCollection width: width ]
		  ifFalse: [ aByteCollection ]
]

{ #category : 'converting' }
PCRE2WideInputBytes class >> normalizeLittleEndianBytes: aByteCollection width: width [

	^ self nativeEndianIsLittle
		  ifTrue: [ aByteCollection ]
		  ifFalse: [ self swapBytes: aByteCollection width: width ]
]

{ #category : 'private' }
PCRE2WideInputBytes class >> startsWith: aByteCollection bytes: prefixBytes [

	aByteCollection size < prefixBytes size ifTrue: [ ^ false ].
	1 to: prefixBytes size do: [ :index | (aByteCollection at: index) = (prefixBytes at: index) ifFalse: [ ^ false ] ].
	^ true
]

{ #category : 'converting' }
PCRE2WideInputBytes class >> swapBytes: aByteCollection width: width [
	"Answer a copy where each code unit of width bytes has its byte order reversed."

	| swapped |
	self validateByteSize: aByteCollection multipleOf: width message: 'Input byte size must be divisible by the code-unit width'.
	swapped := ByteArray new: aByteCollection size.
	1 to: aByteCollection size by: width do: [ :start |
	1 to: width do: [ :offset | swapped at: start + offset - 1 put: (aByteCollection at: start + width - offset) ] ].
	^ swapped
]

{ #category : 'validating' }
PCRE2WideInputBytes class >> validateByteSize: aByteCollection multipleOf: width message: messageText [

	(aByteCollection size rem: width) = 0 ifFalse: [ PCRE2Error signal: messageText ]
]
