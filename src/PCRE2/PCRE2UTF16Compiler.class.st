"
Public PCRE2 Compiler using 16-bit code units. The selected backend supplies the implementation; input and offset conventions are shared across backends.
"
Class {
	#name : 'PCRE2UTF16Compiler',
	#superclass : 'PCRE2Compiler',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'backends' }
PCRE2UTF16Compiler >> codeUnitWidth [

	^ 16
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
