"
Public PCRE2 Matcher using 8-bit code units. The selected backend supplies the implementation; input and offset conventions are shared across backends.
"
Class {
	#name : 'PCRE2UTF8Matcher',
	#superclass : 'PCRE2Matcher',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'documentation' }
PCRE2UTF8Matcher >> codeUnitWidth [
	"Answer the PCRE2 code-unit width used by this matcher."

	^ 8
]

{ #category : 'private' }
PCRE2UTF8Matcher >> compilerClass [

	^ PCRE2UTF8Compiler
]

{ #category : 'private' }
PCRE2UTF8Matcher >> decodeSubstitutionOutput: buffer codeUnits: codeUnitCount [
	"Decode a PCRE2-8 substitution output buffer. For this width, code units are bytes."

	codeUnitCount = 0 ifTrue: [ ^ String new ].
	^ ZnUTF8Encoder default decodeBytes: (buffer copyFrom: 1 to: codeUnitCount)
]

{ #category : 'private' }
PCRE2UTF8Matcher >> matchClass [

	^ PCRE2UTF8Match
]

{ #category : 'private' }
PCRE2UTF8Matcher >> preparedInputFor: aStringOrInput [

	^ aStringOrInput asPCRE2UTF8Input
]
