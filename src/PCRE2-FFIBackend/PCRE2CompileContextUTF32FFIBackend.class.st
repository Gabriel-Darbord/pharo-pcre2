"
Owns a compile-context handle of the 32-bit PCRE2 library.
"
Class {
	#name : 'PCRE2CompileContextUTF32FFIBackend',
	#superclass : 'PCRE2CompileContextFFIBackend',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'private - FFI' }
PCRE2CompileContextUTF32FFIBackend >> basicFree [

	self ffiCall: #(void pcre2_compile_context_free_32(self))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF32FFIBackend >> compilerClass [

	^ PCRE2UTF32Compiler
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF32FFIBackend >> ffiLibraryName [

	^ LibPCRE2UTF32
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF32FFIBackend >> privateCopy [
	"Answer NULL when memory cannot be obtained."

	self ffiCall: #(void *pcre2_compile_context_copy_32(self))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF32FFIBackend >> setBSR: value [
	"Answer zero, or PCRE2_ERROR_BADDATA unless value is PCRE2_BSR_ANYCRLF or PCRE2_BSR_UNICODE."

	self ffiCall: #(int pcre2_set_bsr_32(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF32FFIBackend >> setCharacterTables: characterTablesOrNil [

	self ffiCall: #(int pcre2_set_character_tables_32(self, void *characterTablesOrNil))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF32FFIBackend >> setMaxPatternCompiledLength: value [

	self ffiCall: #(int pcre2_set_max_pattern_compiled_length_32(self, size_t value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF32FFIBackend >> setMaxPatternLength: value [

	self ffiCall: #(int pcre2_set_max_pattern_length_32(self, size_t value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF32FFIBackend >> setMaxVarLookbehind: value [

	self ffiCall: #(int pcre2_set_max_varlookbehind_32(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF32FFIBackend >> setNewline: value [

	self ffiCall: #(int pcre2_set_newline_32(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF32FFIBackend >> setOptimize: directive [

	self ffiCall: #(int pcre2_set_optimize_32(self, uint32 directive))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF32FFIBackend >> setOptions: value [

	self ffiCall: #(int pcre2_set_compile_extra_options_32(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2CompileContextUTF32FFIBackend >> setParensNestLimit: value [

	self ffiCall: #(int pcre2_set_parens_nest_limit_32(self, uint32 value))
]
