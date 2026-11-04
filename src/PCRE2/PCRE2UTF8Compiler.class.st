"
Public PCRE2 Compiler using 8-bit code units. The selected backend supplies the implementation; input and offset conventions are shared across backends.
"
Class {
	#name : 'PCRE2UTF8Compiler',
	#superclass : 'PCRE2Compiler',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'accessing' }
PCRE2UTF8Compiler >> codeUnitWidth [

	^ 8
]

{ #category : 'accessing' }
PCRE2UTF8Compiler >> compileContextClass [

	^ PCRE2UTF8CompileContext
]

{ #category : 'private' }
PCRE2UTF8Compiler >> inputClass [

	^ PCRE2UTF8Input
]

{ #category : 'private' }
PCRE2UTF8Compiler >> matcherClass [

	^ PCRE2UTF8Matcher
]

{ #category : 'private' }
PCRE2UTF8Compiler >> preparedPatternFor: aStringOrInput [

	^ aStringOrInput asPCRE2UTF8Input
]
