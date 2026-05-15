"
Compile context for PCRE2's 8-bit UTF-8 API.

The common compile-context accessors live on PCRE2CompileContext. This subclass binds the native setters, copier, and finalizer to libpcre2-8.
"
Class {
	#name : 'PCRE2UTF8CompileContext',
	#superclass : 'PCRE2CompileContext',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'library path' }
PCRE2UTF8CompileContext >> ffiLibraryName [
	^ LibPCRE2
]

{ #category : 'external resource management' }
PCRE2UTF8CompileContext >> free [
	"This function frees the memory occupied by a compile context.
	If the argument is NULL, the function returns immediately without doing anything."

	self ffiCall: #(void pcre2_compile_context_free_8(self))
]

{ #category : 'private' }
PCRE2UTF8CompileContext >> privateCopy [
	"This function makes a new copy of a compile context.
	The result is NULL if the memory cannot be obtained.
	pcre2_compile_context *pcre2_compile_context_copy_8(pcre2_compile_context *ccontext)"

	self ffiCall: #( void #* pcre2_compile_context_copy_8
	   #( self ) )
]

{ #category : 'private' }
PCRE2UTF8CompileContext >> setBSR: value [
	"This function sets the convention for processing \R within a compile context.
	The second argument must be one of PCRE2_BSR_ANYCRLF or PCRE2_BSR_UNICODE.
	The result is zero for success or PCRE2_ERROR_BADDATA if the second argument is invalid."

	self ffiCall: #( int pcre2_set_bsr_8 #( self #, uint32 value ) )
]

{ #category : 'private' }
PCRE2UTF8CompileContext >> setMaxPatternCompiledLength: value [
	"Set the native compiled-pattern size limit.
	int pcre2_set_max_pattern_compiled_length_8(pcre2_compile_context *ccontext, PCRE2_SIZE value)"

	self ffiCall: #( int pcre2_set_max_pattern_compiled_length_8
		   #( self #, size_t value ) )
]

{ #category : 'private' }
PCRE2UTF8CompileContext >> setMaxPatternLength: value [
	"Set the native pattern length limit.
	int pcre2_set_max_pattern_length_8(pcre2_compile_context *ccontext, PCRE2_SIZE value)"

	self ffiCall:
		#( int pcre2_set_max_pattern_length_8 #( self #, size_t value ) )
]

{ #category : 'private' }
PCRE2UTF8CompileContext >> setMaxVarLookbehind: value [
	"Set the native bounded variable-lookbehind limit.
	int pcre2_set_max_varlookbehind_8(pcre2_compile_context *ccontext, uint32_t value)"

	self ffiCall:
		#( int pcre2_set_max_varlookbehind_8 #( self #, uint32 value ) )
]

{ #category : 'private' }
PCRE2UTF8CompileContext >> setNewline: value [
	"Set the newline convention in the native compile context.
	int pcre2_set_newline_8(pcre2_compile_context *ccontext, uint32_t value)"

	self ffiCall: #( int pcre2_set_newline_8 #( self #, uint32 value ) )
]

{ #category : 'private' }
PCRE2UTF8CompileContext >> setOptimize: directive [
	"Apply an optimization directive to the native compile context.
	int pcre2_set_optimize_8(pcre2_compile_context *ccontext, uint32_t directive)"

	self ffiCall:
		#( int pcre2_set_optimize_8 #( self #, uint32 directive ) )
]

{ #category : 'private' }
PCRE2UTF8CompileContext >> setOptions: value [
	"Set extra compile options on the native context.
	int pcre2_set_compile_extra_options_8(pcre2_compile_context *ccontext, uint32_t extra_options)"

	self ffiCall: #( int pcre2_set_compile_extra_options_8
		   #( self #, uint32 value ) )
]

{ #category : 'private' }
PCRE2UTF8CompileContext >> setParensNestLimit: value [
	"Set the native parenthesis nesting limit.
	int pcre2_set_parens_nest_limit_8(pcre2_compile_context *ccontext, uint32_t value)"

	self ffiCall:
		#( int pcre2_set_parens_nest_limit_8 #( self #, uint32 value ) )
]
