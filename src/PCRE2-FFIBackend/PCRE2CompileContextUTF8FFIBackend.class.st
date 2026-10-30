"
Owns a compile-context handle of the 8-bit PCRE2 library.
"
Class {
	#name : 'PCRE2CompileContextUTF8FFIBackend',
	#superclass : 'PCRE2CompileContextFFIBackend',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> compilerClass [

	^ PCRE2UTF8Compiler
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> ffiLibraryName [

	^ LibPCRE2UTF8
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> free [
	"This function frees the memory occupied by a compile context.
	If the argument is NULL, the function returns immediately without doing anything."

	self ffiCall: #(void pcre2_compile_context_free_8(self))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> privateCopy [
	"This function makes a new copy of a compile context.
	The result is NULL if the memory cannot be obtained.
	pcre2_compile_context *pcre2_compile_context_copy_8(pcre2_compile_context *ccontext)"

	self ffiCall: #(void *pcre2_compile_context_copy_8(self))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> setBSR: value [
	"This function sets the convention for processing \R within a compile context.
	The second argument must be one of PCRE2_BSR_ANYCRLF or PCRE2_BSR_UNICODE.
	The result is zero for success or PCRE2_ERROR_BADDATA if the second argument is invalid."

	self ffiCall: #(int pcre2_set_bsr_8(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> setCharacterTables: characterTablesOrNil [
	"Set low-character tables in the native UTF-8 compile context.
	int pcre2_set_character_tables_8(pcre2_compile_context *ccontext, const uint8_t *tables)"

	self ffiCall: #(int pcre2_set_character_tables_8(self, void *characterTablesOrNil))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> setMaxPatternCompiledLength: value [
	"Set the native compiled-pattern size limit.
	int pcre2_set_max_pattern_compiled_length_8(pcre2_compile_context *ccontext, PCRE2_SIZE value)"

	self ffiCall: #(int pcre2_set_max_pattern_compiled_length_8(self, size_t value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> setMaxPatternLength: value [
	"Set the native pattern length limit.
	int pcre2_set_max_pattern_length_8(pcre2_compile_context *ccontext, PCRE2_SIZE value)"

	self ffiCall: #(int pcre2_set_max_pattern_length_8(self, size_t value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> setMaxVarLookbehind: value [
	"Set the native bounded variable-lookbehind limit.
	int pcre2_set_max_varlookbehind_8(pcre2_compile_context *ccontext, uint32_t value)"

	self ffiCall: #(int pcre2_set_max_varlookbehind_8(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> setNewline: value [
	"Set the newline convention in the native compile context.
	int pcre2_set_newline_8(pcre2_compile_context *ccontext, uint32_t value)"

	self ffiCall: #(int pcre2_set_newline_8(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> setOptimize: directive [
	"Apply an optimization directive to the native compile context.
	int pcre2_set_optimize_8(pcre2_compile_context *ccontext, uint32_t directive)"

	self ffiCall: #(int pcre2_set_optimize_8(self, uint32 directive))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> setOptions: value [
	"Set extra compile options on the native context.
	int pcre2_set_compile_extra_options_8(pcre2_compile_context *ccontext, uint32_t extra_options)"

	self ffiCall: #(int pcre2_set_compile_extra_options_8(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> setParensNestLimit: value [
	"Set the native parenthesis nesting limit.
	int pcre2_set_parens_nest_limit_8(pcre2_compile_context *ccontext, uint32_t value)"

	self ffiCall: #(int pcre2_set_parens_nest_limit_8(self, uint32 value))
]
