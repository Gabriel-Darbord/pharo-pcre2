"
Compiles patterns for PCRE2's 32-bit code-unit API.

Use this compiler when the subject should cross the FFI boundary as UTF-32 code units instead of UTF-8 bytes. The high-level matching API is inherited from PCRE2Matcher through PCRE2Matcher32; the native FFI methods are intentionally copied with _32 suffixes because UFFI compiles ffiCall: methods to concrete symbols.
"
Class {
	#name : 'PCRE2Compiler32',
	#superclass : 'PCRE2Compiler',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'private' }
PCRE2Compiler32 >> compile: pattern upTo: length errorCode: errorCode errorOffset: errorOffset [
	"Compile a native-endian UTF-32 pattern buffer.
	pcre2_code *pcre2_compile_32(PCRE2_SPTR32 pattern, PCRE2_SIZE length, uint32_t options, int *errorcode, PCRE2_SIZE *erroroffset, pcre2_compile_context *ccontext)"

	self ffiCall:
		#( void #* pcre2_compile_32 #( void #* pattern #, size_t length
		      #, uint32 options #, IntHolder errorCode #, SizeTHolder
		      errorOffset #, void #* context ) )
]

{ #category : 'private' }
PCRE2Compiler32 >> createCompileContext [
	"UTF-32 compile contexts need width-specific wrappers before they can be safely exposed."

	PCRE2Error signal: 'UTF-32 compile contexts are not implemented yet'
]

{ #category : 'library path' }
PCRE2Compiler32 >> ffiLibraryName [

	^ LibPCRE232
]

{ #category : 'private' }
PCRE2Compiler32 >> inputClass [

	^ PCRE2UTF32Input
]

{ #category : 'private' }
PCRE2Compiler32 >> matcherClass [

	^ PCRE2Matcher32
]

{ #category : 'private' }
PCRE2Compiler32 >> privateJITCompile: matcher [
	"int pcre2_jit_compile_32(pcre2_code_32 *code, uint32_t options)"

	self ffiCall:
		#( int pcre2_jit_compile_32 #( PCRE2Matcher32 #* matcher #, uint32
		      optionsJIT ) )
]
