Class {
	#name : 'PCRE2MatchContext',
	#superclass : 'PCRE2Object',
	#instVars : [
		'depthLimit',
		'heapLimit',
		'matchLimit',
		'offsetLimit'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'copying' }
PCRE2MatchContext >> copy [

	^ self deepCopy
]

{ #category : 'copying' }
PCRE2MatchContext >> deepCopy [

	| copy |
	copy := self privateCopy.
	copy isNull ifTrue: [
		PCRE2Error signal: 'Failed to obtain memory to copy match context' ].
	"use reflection to avoid the setters' FFI calls"
	^ copy autoRelease
		  instVarNamed: #depthLimit put: depthLimit;
		  instVarNamed: #heapLimit put: heapLimit;
		  instVarNamed: #matchLimit put: matchLimit;
		  instVarNamed: #offsetLimit put: offsetLimit
]

{ #category : 'accessing' }
PCRE2MatchContext >> depthLimit [

	^ depthLimit
]

{ #category : 'accessing' }
PCRE2MatchContext >> depthLimit: anInteger [

	self setDepthLimit: (depthLimit := anInteger)
]

{ #category : 'initialize-release' }
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

	self setHeapLimit: (heapLimit := anInteger)
]

{ #category : 'accessing' }
PCRE2MatchContext >> matchLimit [

	^ matchLimit
]

{ #category : 'accessing' }
PCRE2MatchContext >> matchLimit: anInteger [

	self setMatchLimit: (matchLimit := anInteger)
]

{ #category : 'accessing' }
PCRE2MatchContext >> offsetLimit [

	^ offsetLimit
]

{ #category : 'accessing' }
PCRE2MatchContext >> offsetLimit: anInteger [

	self setOffsetLimit: (offsetLimit := anInteger)
]

{ #category : 'private' }
PCRE2MatchContext >> privateCopy [
	"This function makes a new copy of a match context, using the memory allocation function that was used for the original context.
	The result is NULL if the memory cannot be obtained. "

	"pcre2_match_context *pcre2_match_context_copy( pcre2_match_context *mcontext)"

	self ffiCall: #(PCRE2MatchContext *pcre2_match_context_copy(self))
]

{ #category : 'private' }
PCRE2MatchContext >> setDepthLimit: value [
	"This function sets the backtracking depth limit field in a match context. The result is always zero."

	"int pcre2_set_depth_limit(pcre2_match_context *mcontext, uint32_t value)"

	self ffiCall: #(int pcre2_set_depth_limit_8(self, uint32 value))
]

{ #category : 'private' }
PCRE2MatchContext >> setHeapLimit: value [
	"This function sets the heap limit field in a match context. The result is always zero."

	"int pcre2_set_heap_limit(pcre2_match_context *mcontext, uint32_t value)"

	self ffiCall: #(int pcre2_set_heap_limit_8(self, uint32 value))
]

{ #category : 'private' }
PCRE2MatchContext >> setMatchLimit: value [
	"This function sets the match limit field in a match context. The result is always zero."

	"int pcre2_set_match_limit(pcre2_match_context *mcontext, uint32_t value)"

	self ffiCall: #(int pcre2_set_match_limit_8(self, uint32 value))
]

{ #category : 'private' }
PCRE2MatchContext >> setOffsetLimit: value [
	"This function sets the offset limit field in a match context. The result is always zero."

	"int pcre2_set_offset_limit(pcre2_match_context *mcontext, PCRE2_SIZE value)"

	self ffiCall: #(int pcre2_set_offset_limit_8(self, size_t value))
]
