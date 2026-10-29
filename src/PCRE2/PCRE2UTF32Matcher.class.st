"
Represents a compiled PCRE2 pattern using 32-bit code units.

The shared matching API lives on PCRE2Matcher. This subclass supplies the libpcre2-32 FFI entry points, and offsets are interpreted as UTF-32 code-unit indexes before prepared input translates them back to Pharo character ranges.
"
Class {
	#name : 'PCRE2UTF32Matcher',
	#superclass : 'PCRE2Matcher',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'documentation' }
PCRE2UTF32Matcher >> codeUnitWidth [

	^ 32
]

{ #category : 'private' }
PCRE2UTF32Matcher >> compilerClass [

	^ PCRE2UTF32Compiler
]

{ #category : 'private' }
PCRE2UTF32Matcher >> decodeSubstitutionOutput: buffer codeUnits: codeUnitCount [
	"Decode a native-endian UTF-32 substitution output buffer."

	| byteSize bytes |
	codeUnitCount = 0 ifTrue: [ ^ String new ].
	byteSize := codeUnitCount * self codeUnitByteSize.
	bytes := buffer copyFrom: 1 to: byteSize.
	^ (PCRE2UTF32Input fromNativeEndianBytes: bytes) decodeBytes: bytes
]

{ #category : 'private' }
PCRE2UTF32Matcher >> matchClass [

	^ PCRE2UTF32Match
]

{ #category : 'private' }
PCRE2UTF32Matcher >> preparedInputFor: aStringOrInput [

	^ aStringOrInput asPCRE2UTF32Input
]
