"
Class-side helper for byte-order operations shared by UTF-16 and UTF-32 prepared inputs.

It only handles byte collections: validating code-unit alignment, stripping byte-order marks, checking host endianness, and normalizing explicit-endian bytes to the native-endian storage expected by the PCRE2 FFI calls. Width-specific input classes keep ownership of decoding, character offset translation, and public constructors.
"
Class {
	#name : 'PCRE2WideInputBytes',
	#superclass : 'Object',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'private' }
PCRE2WideInputBytes class >> bigEndianBOMForWidth: width [
	"Answer the Unicode BOM bytes for a big-endian code-unit width."

	width = 2 ifTrue: [ ^ #[ 254 255 ] ].
	width = 4 ifTrue: [ ^ #[ 0 0 254 255 ] ].
	PCRE2Error signal: 'Unsupported BOM code-unit width'
]

{ #category : 'converting' }
PCRE2WideInputBytes class >> bytesAfterBOM: aByteCollection byteCount: bomByteCount [
	"Answer bytes after a BOM, allowing a byte collection that contains only the BOM."

	| byteSize |
	byteSize := aByteCollection size.
	byteSize <= bomByteCount ifTrue: [ ^ ByteArray new ].
	^ aByteCollection copyFrom: bomByteCount + 1 to: byteSize
]

{ #category : 'testing' }
PCRE2WideInputBytes class >> hasBigEndianBOM: aByteCollection width: width [
	"Answer whether a byte collection starts with the big-endian BOM for width."

	^ self
		  startsWith: aByteCollection
		  bytes: (self bigEndianBOMForWidth: width)
]

{ #category : 'testing' }
PCRE2WideInputBytes class >> hasLittleEndianBOM: aByteCollection width: width [
	"Answer whether a byte collection starts with the little-endian BOM for width."

	^ self
		  startsWith: aByteCollection
		  bytes: (self littleEndianBOMForWidth: width)
]

{ #category : 'private' }
PCRE2WideInputBytes class >> littleEndianBOMForWidth: width [
	"Answer the Unicode BOM bytes for a little-endian code-unit width."

	width = 2 ifTrue: [ ^ #[ 255 254 ] ].
	width = 4 ifTrue: [ ^ #[ 255 254 0 0 ] ].
	PCRE2Error signal: 'Unsupported BOM code-unit width'
]

{ #category : 'testing' }
PCRE2WideInputBytes class >> nativeEndianIsLittle [
	"Answer whether the host stores multi-byte integer values in little-endian order."

	| bytes |
	bytes := ByteArray new: 2.
	bytes uint16AtOffset: 0 put: 16r0102.
	^ (bytes at: 1) = 16r02
]

{ #category : 'converting' }
PCRE2WideInputBytes class >> normalizeBigEndianBytes: aByteCollection width: width [
	"Answer bytes normalized from explicit big-endian order to host-native order."

	^ self nativeEndianIsLittle
		  ifTrue: [ self swapBytes: aByteCollection width: width ]
		  ifFalse: [ aByteCollection ]
]

{ #category : 'converting' }
PCRE2WideInputBytes class >> normalizeLittleEndianBytes: aByteCollection width: width [
	"Answer bytes normalized from explicit little-endian order to host-native order."

	^ self nativeEndianIsLittle
		  ifTrue: [ aByteCollection ]
		  ifFalse: [ self swapBytes: aByteCollection width: width ]
]

{ #category : 'private' }
PCRE2WideInputBytes class >> startsWith: aByteCollection bytes: prefixBytes [
	"Answer whether a byte collection starts with prefixBytes."

	aByteCollection size < prefixBytes size ifTrue: [ ^ false ].
	1 to: prefixBytes size do: [ :index |
		(aByteCollection at: index) = (prefixBytes at: index) ifFalse: [
			^ false ] ].
	^ true
]

{ #category : 'converting' }
PCRE2WideInputBytes class >> swapBytes: aByteCollection width: width [
	"Answer a copy where each code unit of width bytes has its byte order reversed."

	| swapped |
	self
		validateByteSize: aByteCollection
		multipleOf: width
		message: 'Input byte size must be divisible by the code-unit width'.
	swapped := ByteArray new: aByteCollection size.
	1 to: aByteCollection size by: width do: [ :start |
		1 to: width do: [ :offset |
			swapped
				at: start + offset - 1
				put: (aByteCollection at: start + width - offset) ] ].
	^ swapped
]

{ #category : 'validating' }
PCRE2WideInputBytes class >> validateByteSize: aByteCollection multipleOf: width message: messageText [
	"Signal when a byte collection cannot be split into whole code units of width bytes."

	(aByteCollection size rem: width) = 0 ifFalse: [
		PCRE2Error signal: messageText ]
]
