"
Public PCRE2 Compiler using 32-bit code units. The selected backend supplies the implementation; input and offset conventions are shared across backends.
"
Class {
	#name : 'PCRE2UTF32Compiler',
	#superclass : 'PCRE2Compiler',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'accessing' }
PCRE2UTF32Compiler >> codeUnitWidth [

	^ 32
]

{ #category : 'private' }
PCRE2UTF32Compiler >> inputClass [

	^ PCRE2UTF32Input
]

{ #category : 'private' }
PCRE2UTF32Compiler >> matcherClass [

	^ PCRE2UTF32Matcher
]

{ #category : 'private' }
PCRE2UTF32Compiler >> preparedPatternFor: aStringOrInput [

	^ aStringOrInput asPCRE2UTF32Input
]
