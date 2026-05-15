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

{ #category : 'private' }
PCRE2UTF16Compiler >> compile: pattern upTo: length errorCode: errorCode errorOffset: errorOffset [
	"Compile a native-endian UTF-16 pattern buffer.
	pcre2_code *pcre2_compile_16(PCRE2_SPTR16 pattern, PCRE2_SIZE length, uint32_t options, int *errorcode, PCRE2_SIZE *erroroffset, pcre2_compile_context *ccontext)"

	self ffiCall:
		#( void #* pcre2_compile_16 #( void #* pattern #, size_t length
		      #, uint32 options #, IntHolder errorCode #, SizeTHolder
		      errorOffset #, void #* context ) )
]

{ #category : 'private' }
PCRE2UTF16Compiler >> createCompileContext [
	"UTF-16 compile contexts need width-specific wrappers before they can be safely exposed."

	PCRE2Error signal: 'UTF-16 compile contexts are not implemented yet'
]

{ #category : 'library path' }
PCRE2UTF16Compiler >> ffiLibraryName [

	^ LibPCRE2UTF16
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

{ #category : 'private' }
PCRE2UTF16Compiler >> privateJITCompile: matcher [
	"int pcre2_jit_compile_16(pcre2_code_16 *code, uint32_t options)"

	self ffiCall:
		#( int pcre2_jit_compile_16 #( #PCRE2UTF16Matcher #* matcher #, uint32
		      optionsJIT ) )
]
