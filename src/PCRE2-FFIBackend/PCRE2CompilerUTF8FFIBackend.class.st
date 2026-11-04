"
Compiles patterns through the 8-bit PCRE2 library.
"
Class {
	#name : 'PCRE2CompilerUTF8FFIBackend',
	#superclass : 'PCRE2CompilerFFIBackend',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'private' }
PCRE2CompilerUTF8FFIBackend >> compile: pattern upTo: length errorCode: errorCode errorOffset: errorOffset [
	"length and errorOffset count code units, which are bytes at this width."

	self ffiCall: #(void *pcre2_compile_8(void *pattern, size_t length, uint32 options, IntHolder errorCode, SizeTHolder errorOffset, void *context))
]

{ #category : 'private - FFI' }
PCRE2CompilerUTF8FFIBackend >> compileContextClass [

	^ PCRE2UTF8CompileContext
]

{ #category : 'private' }
PCRE2CompilerUTF8FFIBackend >> createCompileContext [
	"Answer NULL when memory cannot be obtained."

	self ffiCall: #(void *pcre2_compile_context_create_8(nil))
]

{ #category : 'private - FFI' }
PCRE2CompilerUTF8FFIBackend >> ffiLibraryName [

	^ LibPCRE2UTF8
]

{ #category : 'private - FFI' }
PCRE2CompilerUTF8FFIBackend >> inputClass [

	^ PCRE2UTF8Input
]

{ #category : 'private' }
PCRE2CompilerUTF8FFIBackend >> matcherBackendClass [

	^ PCRE2MatcherUTF8FFIBackend
]

{ #category : 'private' }
PCRE2CompilerUTF8FFIBackend >> privateJITCompile: matcher [

	self ffiCall: #(int pcre2_jit_compile_8(PCRE2MatcherUTF8FFIBackend *matcher, uint32 optionsJIT))
]
