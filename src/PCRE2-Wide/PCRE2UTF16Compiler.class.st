"
`PCRE2Compiler` for 16-bit code units; the backend supplies the implementation.
"
Class {
	#name : 'PCRE2UTF16Compiler',
	#superclass : 'PCRE2Compiler',
	#category : 'PCRE2-Wide',
	#package : 'PCRE2-Wide'
}

{ #category : 'accessing' }
PCRE2UTF16Compiler >> codeUnitWidth [

	^ 16
]

{ #category : 'accessing' }
PCRE2UTF16Compiler >> compileContextClass [

	^ PCRE2UTF16CompileContext
]

{ #category : 'private' }
PCRE2UTF16Compiler >> inputClass [

	^ PCRE2UTF16Input
]

{ #category : 'private' }
PCRE2UTF16Compiler >> matcherClass [

	^ PCRE2UTF16Matcher
]

{ #category : 'private' }
PCRE2UTF16Compiler >> preparedPatternFor: aStringOrInput [

	^ aStringOrInput asPCRE2UTF16Input
]
