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
		'bsr'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

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

{ #category : 'copying' }
PCRE2CompileContext >> deepCopy [

	| copy |
	copy := self privateCopy.
	copy isNull ifTrue: [
		PCRE2Error signal: 'Failed to obtain memory to copy compile context' ].
	^ copy autoRelease
]

{ #category : 'initialize-release' }
PCRE2CompileContext >> free [
	"This function frees the memory occupied by a compile context.
	If the argument is NULL, the function returns immediately without doing anything."

	"void pcre2_compile_context_free(pcre2_compile_context *ccontext)"

	self ffiCall: #(void pcre2_compile_context_free_8(self))
]

{ #category : 'private' }
PCRE2CompileContext >> privateCopy [
	"This function makes a new copy of a compile context.
	The result is NULL if the memory cannot be obtained."

	"pcre2_compile_context *pcre2_compile_context_copy( pcre2_compile_context *ccontext)"

	self ffiCall: #(PCRECompileContext *pcre2_compile_context_copy(self))
]

{ #category : 'private' }
PCRE2CompileContext >> setBSR: value [
	"This function sets the convention for processing \R within a compile context.
	The second argument must be one of PCRE2_BSR_ANYCRLF or PCRE2_BSR_UNICODE.
	The result is zero for success or PCRE2_ERROR_BADDATA if the second argument is invalid."

	"int pcre2_set_bsr(pcre2_compile_context *ccontext, uint32_t value)"

	self ffiCall: #(int pcre2_set_bsr(self, uint32 value))
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
