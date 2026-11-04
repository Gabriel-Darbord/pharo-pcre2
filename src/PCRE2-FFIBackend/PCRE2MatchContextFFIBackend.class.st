"
Owns a C match-context handle for a public PCRE2MatchContext. Each setting is written through to the library and kept in the image, to be reapplied to a copy or after startup; the JIT stack and the callbacks must be kept anyway, since the library only holds pointers to them. Width-specific subclasses contain the UFFI entry points.
"
Class {
	#name : 'PCRE2MatchContextFFIBackend',
	#superclass : 'PCRE2Object',
	#instVars : [
		'depthLimit',
		'heapLimit',
		'matchLimit',
		'offsetLimit',
		'calloutCallback',
		'calloutBlock',
		'substituteCalloutCallback',
		'substituteCalloutBlock',
		'substituteCaseCalloutCallback',
		'substituteCaseCalloutBlock',
		'jitStack'
	],
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'testing' }
PCRE2MatchContextFFIBackend class >> isAbstract [

	^ self == PCRE2MatchContextFFIBackend
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> calloutBlock: aBlock [
	"aBlock receives a PCRE2CalloutEvent; an integer answer is the callout's return code, anything else continues matching."

	| callback rc |
	callback := self
		            newCallbackWithSignature: #(int (void *calloutBlock, void *userData))
		            block: [ :calloutBlockAddress :userData |
			            | answer |
			            answer := aBlock value: (PCRE2CalloutEvent fromCalloutBlock: calloutBlockAddress codeUnitWidth: self codeUnitWidth).
			            answer isInteger
				            ifTrue: [ answer ]
				            ifFalse: [ 0 ] ].
	rc := self setCalloutCallback: callback.
	rc < 0 ifTrue: [ self errorCode: rc ].
	calloutBlock := aBlock.
	calloutCallback := callback
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> clearCallout [

	| rc |
	rc := self unsetCalloutCallback.
	rc < 0 ifTrue: [ self errorCode: rc ].
	calloutBlock := nil.
	calloutCallback := nil
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> clearJITStack [

	self unsetJITStack.
	jitStack := nil
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> clearSubstituteCallout [

	| rc |
	rc := self unsetSubstituteCalloutCallback.
	rc < 0 ifTrue: [ self errorCode: rc ].
	substituteCalloutBlock := nil.
	substituteCalloutCallback := nil
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> clearSubstituteCaseCallout [

	| rc |
	rc := self unsetSubstituteCaseCalloutCallback.
	rc < 0 ifTrue: [ self errorCode: rc ].
	substituteCaseCalloutBlock := nil.
	substituteCaseCalloutCallback := nil
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> codeUnitWidth [

	self subclassResponsibility
]

{ #category : 'accessing' }
PCRE2MatchContextFFIBackend >> depthLimit [

	^ depthLimit
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> depthLimit: anInteger [

	self setDepthLimit: (depthLimit := anInteger)
]

{ #category : 'accessing' }
PCRE2MatchContextFFIBackend >> heapLimit [

	^ heapLimit
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> heapLimit: anInteger [
	"anInteger is in kibibytes."

	self setHeapLimit: (heapLimit := anInteger)
]

{ #category : 'accessing' }
PCRE2MatchContextFFIBackend >> jitStack [
	"Assigned JIT stack, or nil when PCRE2 uses its default thread-local machine stack."

	^ jitStack
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> jitStack: aJITStack [
	"nil returns to PCRE2's default stack. A stack must not serve concurrent or nested matches."

	aJITStack ifNil: [ ^ self clearJITStack ].
	aJITStack codeUnitWidth = self codeUnitWidth ifFalse: [
		PCRE2Error signal: 'JIT stack code-unit width does not match this match context' ].
	self setJITStack: aJITStack.
	jitStack := aJITStack
]

{ #category : 'accessing' }
PCRE2MatchContextFFIBackend >> matchLimit [

	^ matchLimit
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> matchLimit: anInteger [

	self setMatchLimit: (matchLimit := anInteger)
]

{ #category : 'accessing' }
PCRE2MatchContextFFIBackend >> offsetLimit [

	^ offsetLimit
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> offsetLimit: anInteger [
	"anInteger is a zero-based code-unit offset."

	self setOffsetLimit: (offsetLimit := anInteger)
]

{ #category : 'copying' }
PCRE2MatchContextFFIBackend >> postCopy [

	handle := self privateCopy.
	handle isNull ifTrue: [ PCRE2Error signal: 'Failed to obtain memory to copy match context' ].
	jitStack ifNotNil: [ self setJITStack: jitStack ].
	calloutBlock ifNotNil: [ self calloutBlock: calloutBlock ].
	substituteCalloutBlock ifNotNil: [ self substituteCalloutBlock: substituteCalloutBlock ].
	substituteCaseCalloutBlock ifNotNil: [ self substituteCaseCalloutBlock: substituteCaseCalloutBlock ]
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> privateCopy [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> restoreAfterStartup [
	"Recreate my native match context and reapply my settings. The callout blocks are kept as they are, so what they capture must also be valid after startup."

	self setHandle: self ffiLibraryName uniqueInstance createMatchContext.
	self isNull ifTrue: [ PCRE2Error signal: 'Failed to restore match context' ].
	depthLimit ifNotNil: [ self depthLimit: depthLimit ].
	heapLimit ifNotNil: [ self heapLimit: heapLimit ].
	matchLimit ifNotNil: [ self matchLimit: matchLimit ].
	offsetLimit ifNotNil: [ self offsetLimit: offsetLimit ].
	jitStack ifNotNil: [
			jitStack isNull ifTrue: [ jitStack restoreAfterStartup ].
			self jitStack: jitStack ].
	calloutBlock ifNotNil: [ self calloutBlock: calloutBlock ].
	substituteCalloutBlock ifNotNil: [ self substituteCalloutBlock: substituteCalloutBlock ].
	substituteCaseCalloutBlock ifNotNil: [ self substituteCaseCalloutBlock: substituteCaseCalloutBlock ]
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> setCalloutCallback: callback [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> setDepthLimit: value [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> setHeapLimit: value [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> setJITStack: aJITStack [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> setMatchLimit: value [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> setOffsetLimit: value [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> setSubstituteCalloutCallback: callback [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> setSubstituteCaseCalloutCallback: callback [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> substituteCalloutBlock: aBlock [
	"aBlock receives a PCRE2SubstitutionCalloutEvent; an integer answer is the callout's return code, anything else accepts the replacement."

	| callback rc |
	self ffiLibraryName supportsSubstitutionCallouts ifFalse: [
		PCRE2Error signal: 'Substitution callouts require PCRE2 10.33 or newer; loaded ' , self ffiLibraryName versionString ].
	callback := self
		            newCallbackWithSignature: #(int (void *calloutBlock, void *userData))
		            block: [ :calloutBlockAddress :userData |
			            | answer |
			            answer := aBlock value:
				                      (PCRE2SubstitutionCalloutEvent fromCalloutBlock: calloutBlockAddress codeUnitWidth: self codeUnitWidth).
			            answer isInteger
				            ifTrue: [ answer ]
				            ifFalse: [ PCRE2 substituteCalloutAccept ] ].
	rc := self setSubstituteCalloutCallback: callback.
	rc < 0 ifTrue: [ self errorCode: rc ].
	substituteCalloutBlock := aBlock.
	substituteCalloutCallback := callback
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> substituteCaseCalloutBlock: aBlock [
	"aBlock receives a PCRE2SubstitutionCaseCalloutEvent and answers the transformed text. nil makes the substitution fail; any other non-string answer applies the requested case transform."

	| callback rc |
	self ffiLibraryName supportsSubstitutionCaseCallouts ifFalse: [
		PCRE2Error signal: 'Substitution case callouts require PCRE2 10.45 or newer; loaded ' , self ffiLibraryName versionString ].
	callback := self
		            newCallbackWithSignature: #(size_t (void *input, size_t inputLength, void *output, size_t outputCapacity, int caseType, void *userData))
		            block: [ :input :inputLength :output :outputCapacity :caseType :userData |
			            | event |
			            event := PCRE2SubstitutionCaseCalloutEvent
				                     fromInput: input
				                     length: inputLength
				                     outputCapacity: outputCapacity
				                     caseType: caseType
				                     codeUnitWidth: self codeUnitWidth.
			            self substituteCaseCalloutResultFor: event output: output block: aBlock ].
	rc := self setSubstituteCaseCalloutCallback: callback.
	rc < 0 ifTrue: [ self errorCode: rc ].
	substituteCaseCalloutBlock := aBlock.
	substituteCaseCalloutCallback := callback
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> substituteCaseCalloutResultFor: event output: outputPointer block: aBlock [
	"Copy the encoded answer into the output only when it fits, and answer its length in code units either way."

	| answer bytes codeUnitCount text |
	answer := aBlock value: event.
	answer ifNil: [ ^ PCRE2 zeroTerminated ].
	text := answer isString
		        ifTrue: [ answer ]
		        ifFalse: [ event defaultTransformedText ].
	bytes := PCRE2SubstitutionCaseCalloutEvent bytesForString: text codeUnitWidth: event codeUnitWidth.
	codeUnitCount := bytes size // (event codeUnitWidth // 8).
	codeUnitCount <= event outputCapacity ifTrue: [ PCRE2SubstitutionCaseCalloutEvent copyBytes: bytes to: outputPointer ].
	^ codeUnitCount
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> unsetCalloutCallback [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> unsetJITStack [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> unsetSubstituteCalloutCallback [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2MatchContextFFIBackend >> unsetSubstituteCaseCalloutCallback [

	self subclassResponsibility
]
