"
Owns a match-context handle of the 16-bit PCRE2 library.
"
Class {
	#name : 'PCRE2MatchContextUTF16FFIBackend',
	#superclass : 'PCRE2MatchContextFFIBackend',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'private - FFI' }
PCRE2MatchContextUTF16FFIBackend >> basicFree [

	self ffiCall: #(void pcre2_match_context_free_16(self))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF16FFIBackend >> codeUnitWidth [

	^ 16
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF16FFIBackend >> ffiLibraryName [

	^ LibPCRE2UTF16
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF16FFIBackend >> privateCopy [
	"Answer NULL when memory cannot be obtained."

	self ffiCall: #(void *pcre2_match_context_copy_16(self))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF16FFIBackend >> setCalloutCallback: callback [

	self ffiCall: #(int pcre2_set_callout_16(self, FFICallback callback, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF16FFIBackend >> setDepthLimit: value [

	self ffiCall: #(int pcre2_set_depth_limit_16(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF16FFIBackend >> setHeapLimit: value [

	self ffiCall: #(int pcre2_set_heap_limit_16(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF16FFIBackend >> setJITStack: aJITStack [
	"With a NULL callback, PCRE2 takes the last argument as the stack itself."

	self ffiCall: #(void pcre2_jit_stack_assign_16(self, nil, void *aJITStack))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF16FFIBackend >> setMatchLimit: value [

	self ffiCall: #(int pcre2_set_match_limit_16(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF16FFIBackend >> setOffsetLimit: value [

	self ffiCall: #(int pcre2_set_offset_limit_16(self, size_t value))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF16FFIBackend >> setSubstituteCalloutCallback: callback [

	self ffiCall: #(int pcre2_set_substitute_callout_16(self, FFICallback callback, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF16FFIBackend >> setSubstituteCaseCalloutCallback: callback [

	self ffiCall: #(int pcre2_set_substitute_case_callout_16(self, FFICallback callback, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF16FFIBackend >> unsetCalloutCallback [

	self ffiCall: #(int pcre2_set_callout_16(self, nil, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF16FFIBackend >> unsetJITStack [

	self ffiCall: #(void pcre2_jit_stack_assign_16(self, nil, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF16FFIBackend >> unsetSubstituteCalloutCallback [

	self ffiCall: #(int pcre2_set_substitute_callout_16(self, nil, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF16FFIBackend >> unsetSubstituteCaseCalloutCallback [

	self ffiCall: #(int pcre2_set_substitute_case_callout_16(self, nil, nil))
]
