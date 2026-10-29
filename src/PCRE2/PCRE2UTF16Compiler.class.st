"
Compiles patterns for PCRE2's 16-bit code-unit API.

Use this compiler when the pattern and subject should cross the FFI boundary as UTF-16 code units instead of UTF-8 bytes. The high-level matching API is inherited through PCRE2UTF16Matcher; the native FFI methods are intentionally copied with _16 symbols because UFFI compiles ffiCall: methods to concrete functions.
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
