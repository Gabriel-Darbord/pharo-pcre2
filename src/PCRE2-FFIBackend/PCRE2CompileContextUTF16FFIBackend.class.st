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
PCRE2CompileContextUTF16FFIBackend >> basicFree [

	self ffiCall: #(void pcre2_compile_context_free_16(self))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> compilerClass [

	^ PCRE2UTF16Compiler
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> ffiLibraryName [

	^ LibPCRE2UTF16
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> privateCopy [
	"Answer NULL when memory cannot be obtained."

	self ffiCall: #(void *pcre2_compile_context_copy_16(self))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> setBSR: value [
	"Answer zero, or PCRE2_ERROR_BADDATA unless value is PCRE2_BSR_ANYCRLF or PCRE2_BSR_UNICODE."

	self ffiCall: #(int pcre2_set_bsr_16(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> setCharacterTables: characterTablesOrNil [

	self ffiCall: #(int pcre2_set_character_tables_16(self, void *characterTablesOrNil))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> setMaxPatternCompiledLength: value [

	self ffiCall: #(int pcre2_set_max_pattern_compiled_length_16(self, size_t value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> setMaxPatternLength: value [

	self ffiCall: #(int pcre2_set_max_pattern_length_16(self, size_t value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> setMaxVarLookbehind: value [

	self ffiCall: #(int pcre2_set_max_varlookbehind_16(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> setNewline: value [

	self ffiCall: #(int pcre2_set_newline_16(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> setOptimize: directive [

	self ffiCall: #(int pcre2_set_optimize_16(self, uint32 directive))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> setOptions: value [

	self ffiCall: #(int pcre2_set_compile_extra_options_16(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF16FFIBackend >> setParensNestLimit: value [

	self ffiCall: #(int pcre2_set_parens_nest_limit_16(self, uint32 value))
]
