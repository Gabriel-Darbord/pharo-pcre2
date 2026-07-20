"
Compile context for PCRE2's 32-bit code-unit API.

The common compile-context accessors live on PCRE2CompileContext. This subclass binds the native setters, copier, and finalizer to libpcre2-32.
"
Class {
	#name : 'PCRE2UTF32CompileContext',
	#superclass : 'PCRE2CompileContext',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'library path' }
PCRE2UTF32CompileContext >> ffiLibraryName [

	^ LibPCRE2UTF32
]

{ #category : 'external resource management' }
PCRE2UTF32CompileContext >> free [
	"This function frees the memory occupied by a compile context.
	If the argument is NULL, the function returns immediately without doing anything."

	self ffiCall: #(void pcre2_compile_context_free_32(self))
]

{ #category : 'private' }
PCRE2UTF32CompileContext >> privateCopy [
	"This function makes a new copy of a compile context.
	The result is NULL if the memory cannot be obtained.
	pcre2_compile_context *pcre2_compile_context_copy_32(pcre2_compile_context *ccontext)"

	self ffiCall: #( void #* pcre2_compile_context_copy_32
	   #( self ) )
]

{ #category : 'private' }
PCRE2UTF32CompileContext >> setBSR: value [
	"This function sets the convention for processing \R within a compile context.
	The second argument must be one of PCRE2_BSR_ANYCRLF or PCRE2_BSR_UNICODE.
	The result is zero for success or PCRE2_ERROR_BADDATA if the second argument is invalid."

	self ffiCall: #( int pcre2_set_bsr_32 #( self #, uint32 value ) )
]

{ #category : 'private' }
PCRE2UTF32CompileContext >> setCharacterTables: characterTablesOrNil [
	"Set low-character tables in the native UTF-32 compile context.
	int pcre2_set_character_tables_32(pcre2_compile_context *ccontext, const uint8_t *tables)"

	self ffiCall:
		#( int pcre2_set_character_tables_32 #( self #, void #* characterTablesOrNil ) )
]

{ #category : 'private' }
PCRE2UTF32CompileContext >> setMaxPatternCompiledLength: value [
	"Set the native compiled-pattern size limit.
	int pcre2_set_max_pattern_compiled_length_32(pcre2_compile_context *ccontext, PCRE2_SIZE value)"

	self ffiCall: #( int pcre2_set_max_pattern_compiled_length_32
		   #( self #, size_t value ) )
]

{ #category : 'private' }
PCRE2UTF32CompileContext >> setMaxPatternLength: value [
	"Set the native pattern length limit.
	int pcre2_set_max_pattern_length_32(pcre2_compile_context *ccontext, PCRE2_SIZE value)"

	self ffiCall:
		#( int pcre2_set_max_pattern_length_32 #( self #, size_t value ) )
]

{ #category : 'private' }
PCRE2UTF32CompileContext >> setMaxVarLookbehind: value [
	"Set the native bounded variable-lookbehind limit.
	int pcre2_set_max_varlookbehind_32(pcre2_compile_context *ccontext, uint32_t value)"

	self ffiCall:
		#( int pcre2_set_max_varlookbehind_32 #( self #, uint32 value ) )
]

{ #category : 'private' }
PCRE2UTF32CompileContext >> setNewline: value [
	"Set the newline convention in the native compile context.
	int pcre2_set_newline_32(pcre2_compile_context *ccontext, uint32_t value)"

	self ffiCall: #( int pcre2_set_newline_32 #( self #, uint32 value ) )
]

{ #category : 'private' }
PCRE2UTF32CompileContext >> setOptimize: directive [
	"Apply an optimization directive to the native compile context.
	int pcre2_set_optimize_32(pcre2_compile_context *ccontext, uint32_t directive)"

	self ffiCall:
		#( int pcre2_set_optimize_32 #( self #, uint32 directive ) )
]

{ #category : 'private' }
PCRE2UTF32CompileContext >> setOptions: value [
	"Set extra compile options on the native context.
	int pcre2_set_compile_extra_options_32(pcre2_compile_context *ccontext, uint32_t extra_options)"

	self ffiCall: #( int pcre2_set_compile_extra_options_32
		   #( self #, uint32 value ) )
]

{ #category : 'private' }
PCRE2UTF32CompileContext >> setParensNestLimit: value [
	"Set the native parenthesis nesting limit.
	int pcre2_set_parens_nest_limit_32(pcre2_compile_context *ccontext, uint32_t value)"

	self ffiCall:
		#( int pcre2_set_parens_nest_limit_32 #( self #, uint32 value ) )
]
