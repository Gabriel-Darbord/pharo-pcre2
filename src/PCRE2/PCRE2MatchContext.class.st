"
Abstract superclass for PCRE2 match contexts.

Concrete subclasses bind PCRE2's width-specific native setters and lifetime functions: PCRE2UTF8MatchContext, PCRE2UTF16MatchContext, and PCRE2UTF32MatchContext. This class keeps the shared Pharo-side runtime limit accessors, callback installation protocol, and explicit JIT stack assignment.

A non-nil JIT stack is an advanced ownership-sensitive resource. Use it only when large or complex JIT-compiled patterns need more runtime stack than PCRE2's default.
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
		'substituteCalloutCallback',
		'substituteCaseCalloutCallback',
		'jitStack'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'testing' }
PCRE2MatchContext class >> isAbstract [

	^ self == PCRE2MatchContext
]

{ #category : 'callouts' }
PCRE2MatchContext >> calloutBlock: aBlock [
	"Install a runtime callout. aBlock receives a PCRE2CalloutEvent and may answer an integer PCRE2 return code; non-integer answers continue matching."

	| callback rc |
	callback := FFICallback
		            signature:
		            #( int #( void #* calloutBlock #, void #* userData ) )
		            block: [ :calloutBlock :userData |
			            | answer |
			            answer := aBlock value: (PCRE2CalloutEvent
					                       fromCalloutBlock: calloutBlock
					                       codeUnitWidth: self codeUnitWidth).
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

{ #category : 'accessing' }
PCRE2MatchContext >> clearJITStack [
	"Remove the explicit JIT stack assignment so PCRE2 uses its default stack."

	self unsetJITStack.
	jitStack := nil.
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

{ #category : 'callouts' }
PCRE2MatchContext >> clearSubstituteCaseCallout [
	"Remove the runtime substitution case callout from this match context."

	| rc |
	rc := self unsetSubstituteCaseCalloutCallback.
	rc < 0 ifTrue: [ self errorCode: rc ].
	substituteCaseCalloutCallback := nil.
	^ self
]

{ #category : 'private' }
PCRE2MatchContext >> codeUnitWidth [
	"Answer the PCRE2 code-unit width used to decode callback payloads."

	^ self subclassResponsibility
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
	^ self subclassResponsibility
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
PCRE2MatchContext >> jitStack [
	"Assigned JIT stack, or nil when PCRE2 uses its default thread-local machine stack."

	^ jitStack
]

{ #category : 'accessing' }
PCRE2MatchContext >> jitStack: aJITStack [
	"Assign an explicit JIT stack to this match context. Use nil or clearJITStack to return to PCRE2's default stack. The same non-nil stack must not be used by concurrent or nested matches."

	aJITStack ifNil: [ ^ self clearJITStack ].
	aJITStack codeUnitWidth = self codeUnitWidth ifFalse: [
		PCRE2Error signal:
			'JIT stack code-unit width does not match this match context' ].
	self setJITStack: aJITStack.
	jitStack := aJITStack.
	^ self
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
		PCRE2Error signal: 'Failed to obtain memory to copy match context' ].
	jitStack ifNotNil: [ self setJITStack: jitStack ]
]

{ #category : 'private' }
PCRE2MatchContext >> privateCopy [
	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2MatchContext >> setCalloutCallback: callback [
	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2MatchContext >> setDepthLimit: value [
	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2MatchContext >> setHeapLimit: value [
	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2MatchContext >> setJITStack: aJITStack [

	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2MatchContext >> setMatchLimit: value [
	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2MatchContext >> setOffsetLimit: value [
	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2MatchContext >> setSubstituteCalloutCallback: callback [
	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2MatchContext >> setSubstituteCaseCalloutCallback: callback [

	^ self subclassResponsibility
]

{ #category : 'callouts' }
PCRE2MatchContext >> substituteCalloutBlock: aBlock [
	"Install a runtime substitution callout. aBlock receives a PCRE2SubstitutionCalloutEvent and may answer a PCRE2 substitution-callout return code; non-integer answers accept the replacement."

	| callback rc |
	self ffiLibraryName supportsSubstitutionCallouts ifFalse: [
		PCRE2Error signal:
			'Substitution callouts require PCRE2 10.33 or newer; loaded '
			, self ffiLibraryName versionString ].
	callback := FFICallback
		            signature:
		            #( int #( void #* calloutBlock #, void #* userData ) )
		            block: [ :calloutBlock :userData |
			            | answer |
			            answer := aBlock value: (PCRE2SubstitutionCalloutEvent
					                       fromCalloutBlock: calloutBlock
					                       codeUnitWidth: self codeUnitWidth).
			            answer isInteger
				            ifTrue: [ answer ]
				            ifFalse: [ PCRE2 substituteCalloutAccept ] ].
	rc := self setSubstituteCalloutCallback: callback.
	rc < 0 ifTrue: [ self errorCode: rc ].
	substituteCalloutCallback := callback.
	^ self
]

{ #category : 'callouts' }
PCRE2MatchContext >> substituteCaseCalloutBlock: aBlock [
	"Install a runtime substitution case callout. aBlock receives a PCRE2SubstitutionCaseCalloutEvent and should answer transformed text. Answer nil to make PCRE2 fail with a replace-case error; non-string answers use PCRE2's requested default transform in Pharo."

	| callback rc |
	self ffiLibraryName supportsSubstitutionCaseCallouts ifFalse: [
		PCRE2Error signal:
			'Substitution case callouts require PCRE2 10.45 or newer; loaded '
			, self ffiLibraryName versionString ].
	callback := FFICallback
		            signature:
			            #( size_t #( void #* input #, size_t inputLength
			                  #, void #* output #, size_t outputCapacity
			                  #, int caseType #, void #* userData ) )
		            block: [
			            :input
			            :inputLength
			            :output
			            :outputCapacity
			            :caseType
			            :userData |
			            | event |
			            event := PCRE2SubstitutionCaseCalloutEvent
				                     fromInput: input
				                     length: inputLength
				                     outputCapacity: outputCapacity
				                     caseType: caseType
				                     codeUnitWidth: self codeUnitWidth.
			            self
				            substituteCaseCalloutResultFor: event
				            output: output
				            block: aBlock ].
	rc := self setSubstituteCaseCalloutCallback: callback.
	rc < 0 ifTrue: [ self errorCode: rc ].
	substituteCaseCalloutCallback := callback.
	^ self
]

{ #category : 'private' }
PCRE2MatchContext >> substituteCaseCalloutResultFor: event output: outputPointer block: aBlock [
	"Run the user block and copy its encoded answer into PCRE2's output buffer when it fits."

	| answer bytes codeUnitCount text |
	answer := aBlock value: event.
	answer ifNil: [ ^ PCRE2 zeroTerminated ].
	text := answer isString
		        ifTrue: [ answer ]
		        ifFalse: [ event defaultTransformedText ].
	bytes := PCRE2SubstitutionCaseCalloutEvent
		         bytesForString: text
		         codeUnitWidth: event codeUnitWidth.
	codeUnitCount := bytes size // (event codeUnitWidth // 8).
	codeUnitCount <= event outputCapacity ifTrue: [
		PCRE2SubstitutionCaseCalloutEvent copyBytes: bytes to: outputPointer ].
	^ codeUnitCount
]

{ #category : 'private' }
PCRE2MatchContext >> unsetCalloutCallback [
	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2MatchContext >> unsetJITStack [

	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2MatchContext >> unsetSubstituteCalloutCallback [
	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2MatchContext >> unsetSubstituteCaseCalloutCallback [

	^ self subclassResponsibility
]
