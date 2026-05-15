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

{ #category : 'private' }
PCRE2UTF32Compiler >> compile: pattern upTo: length errorCode: errorCode errorOffset: errorOffset [
	"Compile a native-endian UTF-32 pattern buffer.
	pcre2_code *pcre2_compile_32(PCRE2_SPTR32 pattern, PCRE2_SIZE length, uint32_t options, int *errorcode, PCRE2_SIZE *erroroffset, pcre2_compile_context *ccontext)"

	self ffiCall:
		#( void #* pcre2_compile_32 #( void #* pattern #, size_t length
		      #, uint32 options #, IntHolder errorCode #, SizeTHolder
		      errorOffset #, void #* context ) )
]

{ #category : 'private' }
PCRE2UTF32Compiler >> createCompileContext [
	"Create and initialize a new UTF-32 compile context.
	The result is NULL if memory could not be obtained.
	pcre2_compile_context_32 *pcre2_compile_context_create_32(pcre2_general_context *gcontext)"

	self ffiCall:
		#( #PCRE2UTF32CompileContext #* pcre2_compile_context_create_32
		   #( nil ) )
]

{ #category : 'library path' }
PCRE2UTF32Compiler >> ffiLibraryName [

	^ LibPCRE2UTF32
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

{ #category : 'private' }
PCRE2UTF32Compiler >> privateJITCompile: matcher [
	"int pcre2_jit_compile_32(pcre2_code_32 *code, uint32_t options)"

	self ffiCall:
		#( int pcre2_jit_compile_32 #( #PCRE2UTF32Matcher #* matcher #, uint32
		      optionsJIT ) )
]
