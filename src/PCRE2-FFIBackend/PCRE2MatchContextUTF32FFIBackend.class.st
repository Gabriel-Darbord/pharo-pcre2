"
Owns a match-context handle of the 32-bit PCRE2 library.
"
Class {
	#name : 'PCRE2MatchContextUTF32FFIBackend',
	#superclass : 'PCRE2MatchContextFFIBackend',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> basicFree [

	self ffiCall: #(void pcre2_match_context_free_32(self))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> codeUnitWidth [

	^ 32
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> ffiLibraryName [

	^ LibPCRE2UTF32
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> privateCopy [
	"Answer NULL when memory cannot be obtained."

	self ffiCall: #(void *pcre2_match_context_copy_32(self))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> setCalloutCallback: callback [

	self ffiCall: #(int pcre2_set_callout_32(self, FFICallback callback, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> setDepthLimit: value [

	self ffiCall: #(int pcre2_set_depth_limit_32(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> setHeapLimit: value [

	self ffiCall: #(int pcre2_set_heap_limit_32(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> setJITStack: aJITStack [
	"With a NULL callback, PCRE2 takes the last argument as the stack itself."

	self ffiCall: #(void pcre2_jit_stack_assign_32(self, nil, void *aJITStack))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> setMatchLimit: value [

	self ffiCall: #(int pcre2_set_match_limit_32(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> setOffsetLimit: value [

	self ffiCall: #(int pcre2_set_offset_limit_32(self, size_t value))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> setSubstituteCalloutCallback: callback [

	self ffiCall: #(int pcre2_set_substitute_callout_32(self, FFICallback callback, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> setSubstituteCaseCalloutCallback: callback [

	self ffiCall: #(int pcre2_set_substitute_case_callout_32(self, FFICallback callback, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> unsetCalloutCallback [

	self ffiCall: #(int pcre2_set_callout_32(self, nil, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> unsetJITStack [

	self ffiCall: #(void pcre2_jit_stack_assign_32(self, nil, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> unsetSubstituteCalloutCallback [

	self ffiCall: #(int pcre2_set_substitute_callout_32(self, nil, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> unsetSubstituteCaseCalloutCallback [

	self ffiCall: #(int pcre2_set_substitute_case_callout_32(self, nil, nil))
]
