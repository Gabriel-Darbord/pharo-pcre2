"
Compiles patterns for PCRE2's 32-bit code-unit API.

Use this compiler when the subject should cross the FFI boundary as UTF-32 code units instead of UTF-8 bytes. The high-level matching API is inherited through PCRE2UTF32Matcher; the native FFI methods are intentionally copied with _32 symbols because UFFI compiles ffiCall: methods to concrete functions.
"
Class {
	#name : 'PCRE2UTF32Compiler',
	#superclass : 'PCRE2Compiler',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'backends' }
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
