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
	"Compile a prepared UTF-8 pattern buffer; length and errorOffset are PCRE2-8 code-unit counts/offsets, which are byte counts for this width."

	self ffiCall: #(void *pcre2_compile_8(void *pattern, size_t length, uint32 options, IntHolder errorCode, SizeTHolder errorOffset, void *context))
]

{ #category : 'private - FFI' }
PCRE2CompilerUTF8FFIBackend >> compileContextClass [

	^ PCRE2UTF8CompileContext
]

{ #category : 'private' }
PCRE2CompilerUTF8FFIBackend >> createCompileContext [
	"Create and initialize a new UTF-8 compile context.
	The result is NULL if memory could not be obtained.
	pcre2_compile_context_8 *pcre2_compile_context_create_8(pcre2_general_context *gcontext)"

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
	"int pcre2_jit_compile(pcre2_code *code, uint32_t options)"

	self ffiCall: #(int pcre2_jit_compile_8(PCRE2MatcherUTF8FFIBackend *matcher, uint32 optionsJIT))
]
