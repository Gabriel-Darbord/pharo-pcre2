"
Match context for PCRE2's 32-bit code-unit API.

The common runtime limit and callback accessors live on PCRE2MatchContext. This subclass binds the native setters, copier, and finalizer to libpcre2-32.
"
Class {
	#name : 'PCRE2UTF32MatchContext',
	#superclass : 'PCRE2MatchContext',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'library path' }
PCRE2UTF32MatchContext >> ffiLibraryName [
	^ LibPCRE2UTF32
]

{ #category : 'external resource management' }
PCRE2UTF32MatchContext >> free [
	"This function frees the memory occupied by a match context, using the memory freeing function from the general context with which it was created, or free() if that was not set.
	If the argument is NULL, the function returns immediately without doing anything. "

	self ffiCall: #(void pcre2_match_context_free_32(self))
]

{ #category : 'private' }
PCRE2UTF32MatchContext >> privateCopy [
	"This function makes a new copy of a match context, using the memory allocation function that was used for the original context.
	The result is NULL if the memory cannot be obtained.
	pcre2_match_context *pcre2_match_context_copy_32(pcre2_match_context *mcontext)"

	self ffiCall: #( void #* pcre2_match_context_copy_32
	   #( self ) )
]

{ #category : 'private' }
PCRE2UTF32MatchContext >> setCalloutCallback: callback [
	"Set the runtime match callout function for this context.
	int pcre2_set_callout_32(pcre2_match_context *mcontext, int (*callout_function)(pcre2_callout_block *, void *), void *callout_data)"

	self ffiCall:
		#( int pcre2_set_callout_32 #( self #, FFICallback callback #, nil ) )
]

{ #category : 'private' }
PCRE2UTF32MatchContext >> setDepthLimit: value [
	"This function sets the backtracking depth limit field in a match context. The result is always zero.
	int pcre2_set_depth_limit(pcre2_match_context *mcontext, uint32_t value)"

	self ffiCall: #(int pcre2_set_depth_limit_32(self, uint32 value))
]

{ #category : 'private' }
PCRE2UTF32MatchContext >> setHeapLimit: value [
	"This function sets the heap limit field in a match context. The result is always zero.
	int pcre2_set_heap_limit(pcre2_match_context *mcontext, uint32_t value)"

	self ffiCall: #(int pcre2_set_heap_limit_32(self, uint32 value))
]

{ #category : 'private' }
PCRE2UTF32MatchContext >> setMatchLimit: value [
	"This function sets the match limit field in a match context. The result is always zero.
	int pcre2_set_match_limit(pcre2_match_context *mcontext, uint32_t value)"

	self ffiCall: #(int pcre2_set_match_limit_32(self, uint32 value))
]

{ #category : 'private' }
PCRE2UTF32MatchContext >> setOffsetLimit: value [
	"This function sets the offset limit field in a match context. The result is always zero.
	int pcre2_set_offset_limit(pcre2_match_context *mcontext, PCRE2_SIZE value)"

	self ffiCall: #(int pcre2_set_offset_limit_32(self, size_t value))
]

{ #category : 'private' }
PCRE2UTF32MatchContext >> setSubstituteCalloutCallback: callback [
	"Set the runtime substitution callout function for this context.
	int pcre2_set_substitute_callout_32(pcre2_match_context *mcontext, int (*callout_function)(pcre2_substitute_callout_block *, void *), void *callout_data)"

	self ffiCall:
		#( int pcre2_set_substitute_callout_32 #( self #, FFICallback
		      callback #, nil ) )
]

{ #category : 'private' }
PCRE2UTF32MatchContext >> unsetCalloutCallback [
	"Clear the runtime match callout function for this context.
	int pcre2_set_callout_32(pcre2_match_context *mcontext, NULL, NULL)"

	self ffiCall: #( int pcre2_set_callout_32 #( self #, nil #, nil ) )
]

{ #category : 'private' }
PCRE2UTF32MatchContext >> unsetSubstituteCalloutCallback [
	"Clear the runtime substitution callout function for this context.
	int pcre2_set_substitute_callout_32(pcre2_match_context *mcontext, NULL, NULL)"

	self ffiCall:
		#( int pcre2_set_substitute_callout_32 #( self #, nil #, nil ) )
]
