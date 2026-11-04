"
Public PCRE2 Matcher using 8-bit code units.
"
Class {
	#name : 'PCRE2UTF8Matcher',
	#superclass : 'PCRE2Matcher',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'documentation' }
PCRE2UTF8Matcher >> codeUnitWidth [

	^ 8
]

{ #category : 'private' }
PCRE2UTF8Matcher >> compilerClass [

	^ PCRE2UTF8Compiler
]

{ #category : 'private' }
PCRE2UTF8Matcher >> matchClass [

	^ PCRE2UTF8Match
]

{ #category : 'private' }
PCRE2UTF8Matcher >> matchContextClass [

	^ PCRE2UTF8MatchContext
]

{ #category : 'private' }
PCRE2UTF8Matcher >> preparedInputFor: aStringOrInput [

	^ aStringOrInput asPCRE2UTF8Input
]
