"
Public PCRE2 Matcher using 16-bit code units. The selected backend supplies the implementation; input and offset conventions are shared across backends.
"
Class {
	#name : 'PCRE2UTF16Matcher',
	#superclass : 'PCRE2Matcher',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'documentation' }
PCRE2UTF16Matcher >> codeUnitWidth [

	^ 16
]

{ #category : 'private' }
PCRE2UTF16Matcher >> compilerClass [

	^ PCRE2UTF16Compiler
]

{ #category : 'private' }
PCRE2UTF16Matcher >> decodeSubstitutionOutput: buffer codeUnits: codeUnitCount [
	"Decode a native-endian UTF-16 substitution output buffer."

	| byteSize bytes |
	codeUnitCount = 0 ifTrue: [ ^ String new ].
	byteSize := codeUnitCount * self codeUnitByteSize.
	bytes := buffer copyFrom: 1 to: byteSize.
	^ (PCRE2UTF16Input fromNativeEndianBytes: bytes) decodeBytes: bytes
]

{ #category : 'private' }
PCRE2UTF16Matcher >> matchClass [

	^ PCRE2UTF16Match
]

{ #category : 'private' }
PCRE2UTF16Matcher >> preparedInputFor: aStringOrInput [

	^ aStringOrInput asPCRE2UTF16Input
]
