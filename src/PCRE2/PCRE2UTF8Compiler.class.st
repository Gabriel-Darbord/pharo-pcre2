"
Compiles patterns for PCRE2's 8-bit code-unit API.

This is the UTF-8 compiler returned by PCRE2Compiler new and used by String convenience methods. It binds compile and JIT calls to libpcre2-8 while the abstract superclass keeps the shared compiler state and high-level compile flow.
"
Class {
	#name : 'PCRE2UTF8Compiler',
	#superclass : 'PCRE2Compiler',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'private' }
PCRE2UTF8Compiler >> compile: pattern upTo: length errorCode: errorCode errorOffset: errorOffset [
	"Compile a prepared UTF-8 pattern buffer; length and errorOffset are PCRE2-8 code-unit counts/offsets, which are byte counts for this width."

	self ffiCall:
		#( void #* pcre2_compile_8 #( void #* pattern #, size_t length
		      #, uint32 options #, IntHolder errorCode #, SizeTHolder
		      errorOffset #, void #* context ) )
]

{ #category : 'private' }
PCRE2UTF8Compiler >> createCompileContext [
	"Create and initialize a new UTF-8 compile context.
	The result is NULL if memory could not be obtained.
	pcre2_compile_context_8 *pcre2_compile_context_create_8(pcre2_general_context *gcontext)"

	self ffiCall:
		#( #PCRE2UTF8CompileContext #* pcre2_compile_context_create_8
		   #( nil ) )
]

{ #category : 'library path' }
PCRE2UTF8Compiler >> ffiLibraryName [

	^ LibPCRE2UTF8
]

{ #category : 'private' }
PCRE2UTF8Compiler >> inputClass [

	^ PCRE2UTF8Input
]

{ #category : 'private' }
PCRE2UTF8Compiler >> matcherClass [

	^ PCRE2UTF8Matcher
]

{ #category : 'private' }
PCRE2UTF8Compiler >> preparedPatternFor: aStringOrInput [

	^ aStringOrInput asPCRE2UTF8Input
]

{ #category : 'private' }
PCRE2UTF8Compiler >> privateJITCompile: matcher [
	"int pcre2_jit_compile(pcre2_code *code, uint32_t options)"

	self ffiCall: #(int pcre2_jit_compile_8(PCRE2Matcher *matcher, uint32 optionsJIT))
]
