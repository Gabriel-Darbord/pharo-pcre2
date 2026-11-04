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
PCRE2CompileContextUTF8FFIBackend >> basicFree [

	self ffiCall: #(void pcre2_compile_context_free_8(self))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> compilerClass [

	^ PCRE2UTF8Compiler
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> ffiLibraryName [

	^ LibPCRE2UTF8
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> privateCopy [
	"Answer NULL when memory cannot be obtained."

	self ffiCall: #(void *pcre2_compile_context_copy_8(self))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> setBSR: value [
	"Answer zero, or PCRE2_ERROR_BADDATA unless value is PCRE2_BSR_ANYCRLF or PCRE2_BSR_UNICODE."

	self ffiCall: #(int pcre2_set_bsr_8(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> setCharacterTables: characterTablesOrNil [

	self ffiCall: #(int pcre2_set_character_tables_8(self, void *characterTablesOrNil))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> setMaxPatternCompiledLength: value [

	self ffiCall: #(int pcre2_set_max_pattern_compiled_length_8(self, size_t value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> setMaxPatternLength: value [

	self ffiCall: #(int pcre2_set_max_pattern_length_8(self, size_t value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> setMaxVarLookbehind: value [

	self ffiCall: #(int pcre2_set_max_varlookbehind_8(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> setNewline: value [

	self ffiCall: #(int pcre2_set_newline_8(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> setOptimize: directive [

	self ffiCall: #(int pcre2_set_optimize_8(self, uint32 directive))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> setOptions: value [

	self ffiCall: #(int pcre2_set_compile_extra_options_8(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF8FFIBackend >> setParensNestLimit: value [

	self ffiCall: #(int pcre2_set_parens_nest_limit_8(self, uint32 value))
]
