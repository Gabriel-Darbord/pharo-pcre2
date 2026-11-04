"
`PCRE2Matcher` for 32-bit code units; the backend supplies the implementation.
"
Class {
	#name : 'PCRE2UTF32Matcher',
	#superclass : 'PCRE2Matcher',
	#category : 'PCRE2-Wide',
	#package : 'PCRE2-Wide'
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
PCRE2UTF32Matcher >> matchContextClass [

	^ PCRE2UTF32MatchContext
]

{ #category : 'private' }
PCRE2UTF32Matcher >> preparedInputFor: aStringOrInput [

	^ aStringOrInput asPCRE2UTF32Input
]
