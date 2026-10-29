"
Compiles patterns for PCRE2's 8-bit code-unit API.

This is the UTF-8 compiler returned by PCRE2Compiler new and used by String convenience methods. It binds compile and JIT calls to libpcre2-8 while the abstract superclass keeps the shared compiler state and high-level compile flow.
"
Class {
	#name : 'PCRE2UTF8Compiler',
	#superclass : 'PCRE2Compiler',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'backends' }
PCRE2UTF8Compiler >> codeUnitWidth [

	^ 8
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
