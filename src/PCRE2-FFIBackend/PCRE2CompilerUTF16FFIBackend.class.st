Class {
	#name : 'PCRE2CompilerUTF16FFIBackend',
	#superclass : 'PCRE2CompilerFFIBackend',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'private' }
PCRE2CompilerUTF16FFIBackend >> compile: pattern upTo: length errorCode: errorCode errorOffset: errorOffset [
	"Compile a native-endian UTF-16 pattern buffer; length and errorOffset are PCRE2-16 code-unit counts/offsets, not byte counts."

	self ffiCall: #(void *pcre2_compile_16(void *pattern, size_t length, uint32 options, IntHolder errorCode, SizeTHolder errorOffset, void *context))
]

{ #category : 'private - native' }
PCRE2CompilerUTF16FFIBackend >> compileContextClass [

	^ PCRE2UTF16CompileContext
]

{ #category : 'private' }
PCRE2CompilerUTF16FFIBackend >> createCompileContext [
	"Create and initialize a new UTF-16 compile context.
	The result is NULL if memory could not be obtained.
	pcre2_compile_context_16 *pcre2_compile_context_create_16(pcre2_general_context *gcontext)"

	self ffiCall: #(void *pcre2_compile_context_create_16(nil))
]

{ #category : 'private - native' }
PCRE2CompilerUTF16FFIBackend >> ffiLibraryName [

	^ LibPCRE2UTF16
]

{ #category : 'private - native' }
PCRE2CompilerUTF16FFIBackend >> inputClass [

	^ PCRE2UTF16Input
]

{ #category : 'private' }
PCRE2CompilerUTF16FFIBackend >> matcherBackendClass [

	^ PCRE2MatcherUTF16FFIBackend
]

{ #category : 'private' }
PCRE2CompilerUTF16FFIBackend >> privateJITCompile: matcher [
	"int pcre2_jit_compile_16(pcre2_code_16 *code, uint32_t options)"

	self ffiCall: #(int pcre2_jit_compile_16(PCRE2MatcherUTF16FFIBackend *matcher, uint32 optionsJIT))
]
