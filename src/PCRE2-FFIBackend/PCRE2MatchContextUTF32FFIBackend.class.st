Class {
	#name : 'PCRE2MatchContextUTF32FFIBackend',
	#superclass : 'PCRE2MatchContextFFIBackend',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> codeUnitWidth [

	^ 32
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> ffiLibraryName [

	^ LibPCRE2UTF32
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> free [
	"This function frees the memory occupied by a match context, using the memory freeing function from the general context with which it was created, or free() if that was not set.
	If the argument is NULL, the function returns immediately without doing anything. "

	self ffiCall: #(void pcre2_match_context_free_32(self))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> privateCopy [
	"This function makes a new copy of a match context, using the memory allocation function that was used for the original context.
	The result is NULL if the memory cannot be obtained.
	pcre2_match_context *pcre2_match_context_copy_32(pcre2_match_context *mcontext)"

	self ffiCall: #(void *pcre2_match_context_copy_32(self))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> setCalloutCallback: callback [
	"Set the runtime match callout function for this context.
	int pcre2_set_callout_32(pcre2_match_context *mcontext, int (*callout_function)(pcre2_callout_block *, void *), void *callout_data)"

	self ffiCall: #(int pcre2_set_callout_32(self, FFICallback callback, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> setDepthLimit: value [
	"This function sets the backtracking depth limit field in a match context. The result is always zero.
	int pcre2_set_depth_limit(pcre2_match_context *mcontext, uint32_t value)"

	self ffiCall: #(int pcre2_set_depth_limit_32(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> setHeapLimit: value [
	"This function sets the heap limit field in a match context. The result is always zero.
	int pcre2_set_heap_limit(pcre2_match_context *mcontext, uint32_t value)"

	self ffiCall: #(int pcre2_set_heap_limit_32(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> setJITStack: aJITStack [
	"Assign a libpcre2-32 JIT stack to this match context. Passing NULL as callback tells PCRE2 that callback data is the stack pointer."

	self ffiCall: #(void pcre2_jit_stack_assign_32(self, nil, void *aJITStack))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> setMatchLimit: value [
	"This function sets the match limit field in a match context. The result is always zero.
	int pcre2_set_match_limit(pcre2_match_context *mcontext, uint32_t value)"

	self ffiCall: #(int pcre2_set_match_limit_32(self, uint32 value))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> setOffsetLimit: value [
	"Set the match-context offset limit as a zero-based PCRE2-32 code-unit offset."

	self ffiCall: #(int pcre2_set_offset_limit_32(self, size_t value))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> setSubstituteCalloutCallback: callback [
	"Set the runtime substitution callout function for this context.
	int pcre2_set_substitute_callout_32(pcre2_match_context *mcontext, int (*callout_function)(pcre2_substitute_callout_block *, void *), void *callout_data)"

	self ffiCall: #(int pcre2_set_substitute_callout_32(self, FFICallback callback, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> setSubstituteCaseCalloutCallback: callback [
	"Set the runtime substitution case callout function for this context.
	int pcre2_set_substitute_case_callout_32(pcre2_match_context *mcontext, PCRE2_SIZE (*callout_function)(PCRE2_SPTR32, PCRE2_SIZE, PCRE2_UCHAR32 *, PCRE2_SIZE, int, void *), void *callout_data)"

	self ffiCall: #(int pcre2_set_substitute_case_callout_32(self, FFICallback callback, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> unsetCalloutCallback [
	"Clear the runtime match callout function for this context.
	int pcre2_set_callout_32(pcre2_match_context *mcontext, NULL, NULL)"

	self ffiCall: #(int pcre2_set_callout_32(self, nil, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> unsetJITStack [
	"Clear the explicit libpcre2-32 JIT stack assignment."

	self ffiCall: #(void pcre2_jit_stack_assign_32(self, nil, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> unsetSubstituteCalloutCallback [
	"Clear the runtime substitution callout function for this context.
	int pcre2_set_substitute_callout_32(pcre2_match_context *mcontext, NULL, NULL)"

	self ffiCall: #(int pcre2_set_substitute_callout_32(self, nil, nil))
]

{ #category : 'private - FFI' }
PCRE2MatchContextUTF32FFIBackend >> unsetSubstituteCaseCalloutCallback [
	"Clear the runtime substitution case callout function for this context.
	int pcre2_set_substitute_case_callout_32(pcre2_match_context *mcontext, NULL, NULL)"

	self ffiCall: #(int pcre2_set_substitute_case_callout_32(self, nil, nil))
]
