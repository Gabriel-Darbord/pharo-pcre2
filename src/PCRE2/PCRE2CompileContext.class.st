"
A compile context is required if you want to provide an external function for stack checking during compilation or to change the default values of any of the following compile-time parameters:
- What \R matches (Unicode newlines or CR, LF, CRLF only)
- PCRE2's character tables
- The newline character sequence
- The compile time nested parentheses limit
- The maximum length of the pattern string
- The extra options bits (none set by default)
"
Class {
	#name : 'PCRE2CompileContext',
	#superclass : 'PCRE2Object',
	#instVars : [
		'bsr',
		'options'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'accessing' }
PCRE2CompileContext >> addOptions: anInteger [

	options := options bitOr: anInteger.
	self setOptions
]

{ #category : 'accessing' }
PCRE2CompileContext >> bsr [

	^ bsr
]

{ #category : 'accessing' }
PCRE2CompileContext >> bsr: anInteger [
	"Preferably use `useBSRAnyCRLF` and `useBSRUnicode`.
	The value is used by the JIT compiler and the two interpreted matching functions: match and dfa_match."

	| rc |
	rc := self setBSR: anInteger.
	rc < 0 ifTrue: [ self errorCode: rc ].
	bsr := anInteger
]

{ #category : 'external resource management' }
PCRE2CompileContext >> free [
	"This function frees the memory occupied by a compile context.
	If the argument is NULL, the function returns immediately without doing anything."

	self ffiCall: #(void pcre2_compile_context_free_8(self))
]

{ #category : 'accessing' }
PCRE2CompileContext >> options [

	^ options
]

{ #category : 'accessing' }
PCRE2CompileContext >> options: anInteger [
	"Set the extra compile options.
	See class-side methods of PCRE2 starting with 'extra' to find valid arguments."

	options := anInteger.
	self setOptions
]

{ #category : 'copying' }
PCRE2CompileContext >> postCopy [

	handle := self privateCopy.
	handle isNull ifTrue: [
		PCRE2Error signal: 'Failed to obtain memory to copy compile context' ].
	self autoRelease
]

{ #category : 'private' }
PCRE2CompileContext >> privateCopy [
	"This function makes a new copy of a compile context.
	The result is NULL if the memory cannot be obtained."

	"pcre2_compile_context *pcre2_compile_context_copy( pcre2_compile_context *ccontext)"

	self ffiCall: #(void *pcre2_compile_context_copy(self))
]

{ #category : 'accessing' }
PCRE2CompileContext >> removeOptions: anInteger [

	options := options bitAnd: anInteger bitInvert.
	self setOptions
]

{ #category : 'private' }
PCRE2CompileContext >> setBSR: value [
	"This function sets the convention for processing \R within a compile context.
	The second argument must be one of PCRE2_BSR_ANYCRLF or PCRE2_BSR_UNICODE.
	The result is zero for success or PCRE2_ERROR_BADDATA if the second argument is invalid."

	self ffiCall: #(int pcre2_set_bsr(self, uint32 value))
]

{ #category : 'private' }
PCRE2CompileContext >> setOptions [

	self ffiCall: #(int pcre2_set_compile_extra_options_8(self, uint32 options))
]

{ #category : 'accessing' }
PCRE2CompileContext >> useBSRAnyCRLF [
	"\R matches only CR, LF, or CRLF"

	self bsr: 2
]

{ #category : 'accessing' }
PCRE2CompileContext >> useBSRUnicode [
	"\R matches any Unicode line ending sequence"

	self bsr: 1
]
