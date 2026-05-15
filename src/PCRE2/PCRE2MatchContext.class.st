"
Holds runtime PCRE2 matching settings and callbacks.

Most callers use matcher convenience methods. Use a match context when you need runtime limits such as depth, heap, match, or offset limits, or when building lower-level integrations with callout callbacks.

Callback-aware PCRE2Matcher methods install callbacks on temporary matchers so the receiver is not left with callback state after the operation.
"
Class {
	#name : 'PCRE2MatchContext',
	#superclass : 'PCRE2Object',
	#instVars : [
		'depthLimit',
		'heapLimit',
		'matchLimit',
		'offsetLimit',
		'calloutCallback',
		'substituteCalloutCallback'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'callouts' }
PCRE2MatchContext >> calloutBlock: aBlock [
	"Install a runtime callout. aBlock receives a PCRE2CalloutEvent and may answer an integer PCRE2 return code; non-integer answers continue matching."

	| callback rc |
	callback := FFICallback
		            signature:
		            #( int #( void #* calloutBlock #, void #* userData ) )
		            block: [ :calloutBlock :userData |
			            | answer |
			            answer := aBlock value:
				                      (PCRE2CalloutEvent fromCalloutBlock:
					                       calloutBlock).
			            answer isInteger
				            ifTrue: [ answer ]
				            ifFalse: [ 0 ] ].
	rc := self setCalloutCallback: callback.
	rc < 0 ifTrue: [ self errorCode: rc ].
	calloutCallback := callback.
	^ self
]

{ #category : 'callouts' }
PCRE2MatchContext >> clearCallout [
	"Remove the runtime callout from this match context."

	| rc |
	rc := self unsetCalloutCallback.
	rc < 0 ifTrue: [ self errorCode: rc ].
	calloutCallback := nil.
	^ self
]

{ #category : 'callouts' }
PCRE2MatchContext >> clearSubstituteCallout [
	"Remove the runtime substitution callout from this match context."

	| rc |
	rc := self unsetSubstituteCalloutCallback.
	rc < 0 ifTrue: [ self errorCode: rc ].
	substituteCalloutCallback := nil.
	^ self
]

{ #category : 'accessing' }
PCRE2MatchContext >> depthLimit [

	^ depthLimit
]

{ #category : 'accessing' }
PCRE2MatchContext >> depthLimit: anInteger [
	"Set the backtracking depth limit"

	self setDepthLimit: (depthLimit := anInteger)
]

{ #category : 'external resource management' }
PCRE2MatchContext >> free [
	"This function frees the memory occupied by a match context, using the memory freeing function from the general context with which it was created, or free() if that was not set.
	If the argument is NULL, the function returns immediately without doing anything. "

	self ffiCall: #(void pcre2_match_context_free_8(self))
]

{ #category : 'accessing' }
PCRE2MatchContext >> heapLimit [

	^ heapLimit
]

{ #category : 'accessing' }
PCRE2MatchContext >> heapLimit: anInteger [
	"Set the heap memory limit"

	self setHeapLimit: (heapLimit := anInteger)
]

{ #category : 'accessing' }
PCRE2MatchContext >> matchLimit [

	^ matchLimit
]

{ #category : 'accessing' }
PCRE2MatchContext >> matchLimit: anInteger [
	"Set the backtracking match limit"

	self setMatchLimit: (matchLimit := anInteger)
]

{ #category : 'accessing' }
PCRE2MatchContext >> offsetLimit [

	^ offsetLimit
]

{ #category : 'accessing' }
PCRE2MatchContext >> offsetLimit: anInteger [
	"Set a matching offset limit"

	self setOffsetLimit: (offsetLimit := anInteger)
]

{ #category : 'copying' }
PCRE2MatchContext >> postCopy [

	handle := self privateCopy.
	handle isNull ifTrue: [
		PCRE2Error signal: 'Failed to obtain memory to copy match context' ]
]

{ #category : 'private' }
PCRE2MatchContext >> privateCopy [
	"This function makes a new copy of a match context, using the memory allocation function that was used for the original context.
	The result is NULL if the memory cannot be obtained.
	pcre2_match_context *pcre2_match_context_copy_8(pcre2_match_context *mcontext)"

	self ffiCall: #( void #* pcre2_match_context_copy_8
	   #( self ) )
]

{ #category : 'private' }
PCRE2MatchContext >> setCalloutCallback: callback [
	"Set the runtime match callout function for this context.
	int pcre2_set_callout_8(pcre2_match_context *mcontext, int (*callout_function)(pcre2_callout_block *, void *), void *callout_data)"

	self ffiCall:
		#( int pcre2_set_callout_8 #( self #, FFICallback callback #, nil ) )
]

{ #category : 'private' }
PCRE2MatchContext >> setDepthLimit: value [
	"This function sets the backtracking depth limit field in a match context. The result is always zero.
	int pcre2_set_depth_limit(pcre2_match_context *mcontext, uint32_t value)"

	self ffiCall: #(int pcre2_set_depth_limit_8(self, uint32 value))
]

{ #category : 'private' }
PCRE2MatchContext >> setHeapLimit: value [
	"This function sets the heap limit field in a match context. The result is always zero.
	int pcre2_set_heap_limit(pcre2_match_context *mcontext, uint32_t value)"

	self ffiCall: #(int pcre2_set_heap_limit_8(self, uint32 value))
]

{ #category : 'private' }
PCRE2MatchContext >> setMatchLimit: value [
	"This function sets the match limit field in a match context. The result is always zero.
	int pcre2_set_match_limit(pcre2_match_context *mcontext, uint32_t value)"

	self ffiCall: #(int pcre2_set_match_limit_8(self, uint32 value))
]

{ #category : 'private' }
PCRE2MatchContext >> setOffsetLimit: value [
	"This function sets the offset limit field in a match context. The result is always zero.
	int pcre2_set_offset_limit(pcre2_match_context *mcontext, PCRE2_SIZE value)"

	self ffiCall: #(int pcre2_set_offset_limit_8(self, size_t value))
]

{ #category : 'private' }
PCRE2MatchContext >> setSubstituteCalloutCallback: callback [
	"Set the runtime substitution callout function for this context.
	int pcre2_set_substitute_callout_8(pcre2_match_context *mcontext, int (*callout_function)(pcre2_substitute_callout_block *, void *), void *callout_data)"

	self ffiCall:
		#( int pcre2_set_substitute_callout_8 #( self #, FFICallback
		      callback #, nil ) )
]

{ #category : 'callouts' }
PCRE2MatchContext >> substituteCalloutBlock: aBlock [
	"Install a runtime substitution callout. aBlock receives a PCRE2SubstitutionCalloutEvent and may answer a PCRE2 substitution-callout return code; non-integer answers accept the replacement."

	| callback rc |
	LibPCRE2 supportsSubstitutionCallouts ifFalse: [
		PCRE2Error signal:
			'Substitution callouts require PCRE2 10.33 or newer; loaded '
			, LibPCRE2 versionString ].
	callback := FFICallback
		            signature:
		            #( int #( void #* calloutBlock #, void #* userData ) )
		            block: [ :calloutBlock :userData |
			            | answer |
			            answer := aBlock value:
				                      (PCRE2SubstitutionCalloutEvent
					                       fromCalloutBlock: calloutBlock).
			            answer isInteger
				            ifTrue: [ answer ]
				            ifFalse: [ PCRE2 substituteCalloutAccept ] ].
	rc := self setSubstituteCalloutCallback: callback.
	rc < 0 ifTrue: [ self errorCode: rc ].
	substituteCalloutCallback := callback.
	^ self
]

{ #category : 'private' }
PCRE2MatchContext >> unsetCalloutCallback [
	"Clear the runtime match callout function for this context.
	int pcre2_set_callout_8(pcre2_match_context *mcontext, NULL, NULL)"

	self ffiCall: #( int pcre2_set_callout_8 #( self #, nil #, nil ) )
]

{ #category : 'private' }
PCRE2MatchContext >> unsetSubstituteCalloutCallback [
	"Clear the runtime substitution callout function for this context.
	int pcre2_set_substitute_callout_8(pcre2_match_context *mcontext, NULL, NULL)"

	self ffiCall:
		#( int pcre2_set_substitute_callout_8 #( self #, nil #, nil ) )
]
