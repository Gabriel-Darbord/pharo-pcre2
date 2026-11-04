"
`PCRE2Matcher` for 16-bit code units; the backend supplies the implementation.
"
Class {
	#name : 'PCRE2UTF16Matcher',
	#superclass : 'PCRE2Matcher',
	#category : 'PCRE2-Wide',
	#package : 'PCRE2-Wide'
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
PCRE2UTF16Matcher >> matchContextClass [

	^ PCRE2UTF16MatchContext
]

{ #category : 'private' }
PCRE2UTF16Matcher >> preparedInputFor: aStringOrInput [

	^ aStringOrInput asPCRE2UTF16Input
]
