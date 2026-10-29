"
Represents a compiled PCRE2 pattern using 8-bit UTF-8 code units.

Most users get this class through PCRE2Compiler or String>>asPerlCompatibleRegex. The shared matching API lives on PCRE2Matcher; this subclass supplies the libpcre2-8 FFI entry points and UTF-8 input preparation.
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
