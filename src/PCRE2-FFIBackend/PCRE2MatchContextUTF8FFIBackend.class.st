"
Owns a match-context handle of the 8-bit PCRE2 library.
"
Class {
	#name : 'PCRE2MatchContextUTF8FFIBackend',
	#superclass : 'PCRE2MatchContextFFIBackend',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'private - FFI' }
PCRE2MatchContextUTF8FFIBackend >> basicFree [

	self ffiCall: #(void pcre2_match_context_free_8(self))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF8FFIBackend >> codeUnitWidth [

	^ 8
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF8FFIBackend >> ffiLibraryName [

	^ LibPCRE2UTF8
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF8FFIBackend >> privateCopy [
	"Answer NULL when memory cannot be obtained."

	self ffiCall: #(void *pcre2_match_context_copy_8(self))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF8FFIBackend >> setCalloutCallback: callback [

	self ffiCall: #(int pcre2_set_callout_8(self, FFICallback callback, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF8FFIBackend >> setDepthLimit: value [

	self ffiCall: #(int pcre2_set_depth_limit_8(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF8FFIBackend >> setHeapLimit: value [

	self ffiCall: #(int pcre2_set_heap_limit_8(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF8FFIBackend >> setJITStack: aJITStack [
	"With a NULL callback, PCRE2 takes the last argument as the stack itself."

	self ffiCall: #(void pcre2_jit_stack_assign_8(self, nil, void *aJITStack))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF8FFIBackend >> setMatchLimit: value [

	self ffiCall: #(int pcre2_set_match_limit_8(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF8FFIBackend >> setOffsetLimit: value [

	self ffiCall: #(int pcre2_set_offset_limit_8(self, size_t value))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF8FFIBackend >> setSubstituteCalloutCallback: callback [

	self ffiCall: #(int pcre2_set_substitute_callout_8(self, FFICallback callback, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF8FFIBackend >> setSubstituteCaseCalloutCallback: callback [

	self ffiCall: #(int pcre2_set_substitute_case_callout_8(self, FFICallback callback, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF8FFIBackend >> unsetCalloutCallback [

	self ffiCall: #(int pcre2_set_callout_8(self, nil, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF8FFIBackend >> unsetJITStack [

	self ffiCall: #(void pcre2_jit_stack_assign_8(self, nil, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF8FFIBackend >> unsetSubstituteCalloutCallback [

	self ffiCall: #(int pcre2_set_substitute_callout_8(self, nil, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF8FFIBackend >> unsetSubstituteCaseCalloutCallback [

	self ffiCall: #(int pcre2_set_substitute_case_callout_8(self, nil, nil))
]
