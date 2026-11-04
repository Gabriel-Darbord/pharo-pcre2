"
Compiles patterns through the 32-bit PCRE2 library.
"
Class {
	#name : 'PCRE2CompilerUTF32FFIBackend',
	#superclass : 'PCRE2CompilerFFIBackend',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'private' }
PCRE2CompilerUTF32FFIBackend >> compile: pattern upTo: length errorCode: errorCode errorOffset: errorOffset [
	"length and errorOffset count code units, not bytes."

	self ffiCall: #(void *pcre2_compile_32(void *pattern, size_t length, uint32 options, IntHolder errorCode, SizeTHolder errorOffset, void *context))
]

{ #category : 'private - FFI' }
PCRE2CompilerUTF32FFIBackend >> compileContextClass [

	^ PCRE2UTF32CompileContext
]

{ #category : 'private' }
PCRE2CompilerUTF32FFIBackend >> createCompileContext [
	"Answer NULL when memory cannot be obtained."

	self ffiCall: #(void *pcre2_compile_context_create_32(nil))
]

{ #category : 'private - FFI' }
PCRE2CompilerUTF32FFIBackend >> ffiLibraryName [

	^ LibPCRE2UTF32
]

{ #category : 'private - FFI' }
PCRE2CompilerUTF32FFIBackend >> inputClass [

	^ PCRE2UTF32Input
]

{ #category : 'private' }
PCRE2CompilerUTF32FFIBackend >> matcherBackendClass [

	^ PCRE2MatcherUTF32FFIBackend
]

{ #category : 'private' }
PCRE2CompilerUTF32FFIBackend >> privateJITCompile: matcher [

	self ffiCall: #(int pcre2_jit_compile_32(PCRE2MatcherUTF32FFIBackend *matcher, uint32 optionsJIT))
]
