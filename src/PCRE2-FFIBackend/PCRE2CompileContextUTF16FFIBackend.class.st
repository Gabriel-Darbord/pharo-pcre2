"
Owns a compile-context handle of the 16-bit PCRE2 library.
"
Class {
	#name : 'PCRE2CompileContextUTF16FFIBackend',
	#superclass : 'PCRE2CompileContextFFIBackend',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> compilerClass [

	^ PCRE2UTF16Compiler
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> ffiLibraryName [

	^ LibPCRE2UTF16
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> free [
	"This function frees the memory occupied by a compile context.
	If the argument is NULL, the function returns immediately without doing anything."

	self ffiCall: #(void pcre2_compile_context_free_16(self))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> privateCopy [
	"This function makes a new copy of a compile context.
	The result is NULL if the memory cannot be obtained.
	pcre2_compile_context *pcre2_compile_context_copy_16(pcre2_compile_context *ccontext)"

	self ffiCall: #(void *pcre2_compile_context_copy_16(self))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> setBSR: value [
	"This function sets the convention for processing \R within a compile context.
	The second argument must be one of PCRE2_BSR_ANYCRLF or PCRE2_BSR_UNICODE.
	The result is zero for success or PCRE2_ERROR_BADDATA if the second argument is invalid."

	self ffiCall: #(int pcre2_set_bsr_16(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> setCharacterTables: characterTablesOrNil [
	"Set low-character tables in the native UTF-16 compile context.
	int pcre2_set_character_tables_16(pcre2_compile_context *ccontext, const uint8_t *tables)"

	self ffiCall: #(int pcre2_set_character_tables_16(self, void *characterTablesOrNil))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> setMaxPatternCompiledLength: value [
	"Set the native compiled-pattern size limit.
	int pcre2_set_max_pattern_compiled_length_16(pcre2_compile_context *ccontext, PCRE2_SIZE value)"

	self ffiCall: #(int pcre2_set_max_pattern_compiled_length_16(self, size_t value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> setMaxPatternLength: value [
	"Set the native pattern length limit.
	int pcre2_set_max_pattern_length_16(pcre2_compile_context *ccontext, PCRE2_SIZE value)"

	self ffiCall: #(int pcre2_set_max_pattern_length_16(self, size_t value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> setMaxVarLookbehind: value [
	"Set the native bounded variable-lookbehind limit.
	int pcre2_set_max_varlookbehind_16(pcre2_compile_context *ccontext, uint32_t value)"

	self ffiCall: #(int pcre2_set_max_varlookbehind_16(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> setNewline: value [
	"Set the newline convention in the native compile context.
	int pcre2_set_newline_16(pcre2_compile_context *ccontext, uint32_t value)"

	self ffiCall: #(int pcre2_set_newline_16(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> setOptimize: directive [
	"Apply an optimization directive to the native compile context.
	int pcre2_set_optimize_16(pcre2_compile_context *ccontext, uint32_t directive)"

	self ffiCall: #(int pcre2_set_optimize_16(self, uint32 directive))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> setOptions: value [
	"Set extra compile options on the native context.
	int pcre2_set_compile_extra_options_16(pcre2_compile_context *ccontext, uint32_t extra_options)"

	self ffiCall: #(int pcre2_set_compile_extra_options_16(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> setParensNestLimit: value [
	"Set the native parenthesis nesting limit.
	int pcre2_set_parens_nest_limit_16(pcre2_compile_context *ccontext, uint32_t value)"

	self ffiCall: #(int pcre2_set_parens_nest_limit_16(self, uint32 value))
]
