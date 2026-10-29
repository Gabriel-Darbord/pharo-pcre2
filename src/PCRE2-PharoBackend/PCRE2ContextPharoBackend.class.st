Class {
	#name : 'PCRE2ContextPharoBackend',
	#superclass : 'Object',
	#instVars : [
		'matchLimit',
		'depthLimit',
		'heapLimit',
		'offsetLimit',
		'newline',
		'bsr',
		'maxVarLookbehind',
		'parensNestLimit',
		'maxPatternLength',
		'maxPatternCompiledLength',
		'codeUnitWidth',
		'options',
		'optimizationDirectives',
		'calloutBlock',
		'substituteCalloutBlock',
		'substituteCaseCalloutBlock'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'configuration' }
PCRE2ContextPharoBackend >> addOptions: flags [

	self options: (self options bitOr: flags)
]

{ #category : 'initialization' }
PCRE2ContextPharoBackend >> autoRelease [

	^ self
]

{ #category : 'initialization' }
PCRE2ContextPharoBackend >> backend [

	^ self
]

{ #category : 'private' }
PCRE2ContextPharoBackend >> bsr [

	^ bsr
]

{ #category : 'configuration' }
PCRE2ContextPharoBackend >> bsr: value [

	(#( 1 2 ) includes: value) ifFalse: [ PCRE2Error signal: 'bad option value' ].
	bsr := value
]

{ #category : 'callouts' }
PCRE2ContextPharoBackend >> calloutBlock [

	^ calloutBlock
]

{ #category : 'callouts' }
PCRE2ContextPharoBackend >> calloutBlock: block [

	calloutBlock := block
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> characterTables [

	^ nil
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> characterTables: tables [

	tables ifNotNil: [ PCRE2UnsupportedFeature signal: 'Locale character tables are specific to the FFI backend' ]
]

{ #category : 'callouts' }
PCRE2ContextPharoBackend >> clearCallout [

	calloutBlock := nil
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> clearCharacterTables [

	^ self
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> clearJITStack [

	^ self
]

{ #category : 'callouts' }
PCRE2ContextPharoBackend >> clearSubstituteCallout [

	substituteCalloutBlock := nil
]

{ #category : 'callouts' }
PCRE2ContextPharoBackend >> clearSubstituteCaseCallout [

	substituteCaseCalloutBlock := nil
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> codeUnitWidth [

	^ codeUnitWidth
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> codeUnitWidth: anInteger [

	codeUnitWidth := anInteger
]

{ #category : 'private' }
PCRE2ContextPharoBackend >> depthLimit [

	^ depthLimit
]

{ #category : 'limits' }
PCRE2ContextPharoBackend >> depthLimit: anInteger [

	(anInteger isInteger and: [ anInteger between: 0 and: 16rFFFFFFFF ]) ifFalse: [
		PCRE2Error signal: 'Depth limit must be an unsigned 32-bit integer' ].
	depthLimit := anInteger
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> family [

	^ #pharo
]

{ #category : 'configuration' }
PCRE2ContextPharoBackend >> finalize [

	^ self
]

{ #category : 'configuration' }
PCRE2ContextPharoBackend >> free [

	^ self
]

{ #category : 'private' }
PCRE2ContextPharoBackend >> heapLimit [

	^ heapLimit
]

{ #category : 'limits' }
PCRE2ContextPharoBackend >> heapLimit: value [

	(value isInteger and: [ value between: 0 and: 16rFFFFFFFF ]) ifFalse: [ PCRE2Error signal: 'bad option value' ].
	heapLimit := value
]

{ #category : 'initialization' }
PCRE2ContextPharoBackend >> initialize [

	matchLimit := 10000000.
	depthLimit := 10000000.
	heapLimit := 20000000.
	newline := PCRE2 newlineLF.
	bsr := PCRE2 bsrUnicode.
	parensNestLimit := 250.
	maxVarLookbehind := 255
]

{ #category : 'initialization' }
PCRE2ContextPharoBackend >> isNull [

	^ false
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> jitStack [

	^ nil
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> jitStack: stack [

	stack ifNotNil: [ PCRE2UnsupportedFeature signal: 'PCRE2 JIT stacks are specific to the FFI backend' ]
]

{ #category : 'private' }
PCRE2ContextPharoBackend >> matchLimit [

	^ matchLimit
]

{ #category : 'limits' }
PCRE2ContextPharoBackend >> matchLimit: anInteger [

	(anInteger isInteger and: [ anInteger between: 0 and: 16rFFFFFFFF ]) ifFalse: [
		PCRE2Error signal: 'Match limit must be an unsigned 32-bit integer' ].
	matchLimit := anInteger
]

{ #category : 'private' }
PCRE2ContextPharoBackend >> maxPatternCompiledLength [

	^ maxPatternCompiledLength
]

{ #category : 'private' }
PCRE2ContextPharoBackend >> maxPatternCompiledLength: aValue [

	maxPatternCompiledLength := aValue
]

{ #category : 'private' }
PCRE2ContextPharoBackend >> maxPatternLength [

	^ maxPatternLength
]

{ #category : 'private' }
PCRE2ContextPharoBackend >> maxPatternLength: aValue [

	maxPatternLength := aValue
]

{ #category : 'private' }
PCRE2ContextPharoBackend >> maxVarLookbehind [

	^ maxVarLookbehind
]

{ #category : 'private' }
PCRE2ContextPharoBackend >> maxVarLookbehind: aValue [

	maxVarLookbehind := aValue
]

{ #category : 'private' }
PCRE2ContextPharoBackend >> newline [

	^ newline
]

{ #category : 'configuration' }
PCRE2ContextPharoBackend >> newline: value [

	(value isInteger and: [ value between: PCRE2 newlineCR and: PCRE2 newlineNul ]) ifFalse: [ PCRE2Error signal: 'bad option value' ].
	newline := value
]

{ #category : 'private' }
PCRE2ContextPharoBackend >> offsetLimit [

	^ offsetLimit
]

{ #category : 'private' }
PCRE2ContextPharoBackend >> offsetLimit: aValue [

	offsetLimit := aValue
]

{ #category : 'configuration' }
PCRE2ContextPharoBackend >> optimizationDirectives [

	^ optimizationDirectives ifNil: [ #(  ) ]
]

{ #category : 'configuration' }
PCRE2ContextPharoBackend >> optimize: directive [

	({
		 PCRE2 optimizationFull.
		 PCRE2 optimizationNone.
		 PCRE2 optimizeStart.
		 PCRE2 optimizeStartOff.
		 PCRE2 optimizeAutoPossess.
		 PCRE2 optimizeAutoPossessOff.
		 PCRE2 optimizeDotstarAnchor.
		 PCRE2 optimizeDotstarAnchorOff } includes: directive) ifFalse: [ PCRE2Error signal: 'bad option value' ].
	optimizationDirectives := self optimizationDirectives copyWith: directive
]

{ #category : 'configuration' }
PCRE2ContextPharoBackend >> options [

	^ options ifNil: [ 0 ]
]

{ #category : 'configuration' }
PCRE2ContextPharoBackend >> options: flags [

	(flags isInteger and: [ flags between: 0 and: 16r7FFFFFFF ]) ifFalse: [ PCRE2Error signal: 'bad option value' ].
	options := flags
]

{ #category : 'private' }
PCRE2ContextPharoBackend >> parensNestLimit [

	^ parensNestLimit
]

{ #category : 'private' }
PCRE2ContextPharoBackend >> parensNestLimit: aValue [

	parensNestLimit := aValue
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> prepareForShutdown [

	^ self
]

{ #category : 'configuration' }
PCRE2ContextPharoBackend >> removeOptions: flags [

	self options: (self options bitAnd: flags bitInvert)
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> requiresSessionRestore [

	^ false
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> restoreAfterStartup [

	^ self
]

{ #category : 'configuration' }
PCRE2ContextPharoBackend >> startOptimizationEnabled [

	| enabled |
	enabled := true.
	self optimizationDirectives do: [ :directive |
			(directive = PCRE2 optimizationNone or: [ directive = PCRE2 optimizeStartOff ]) ifTrue: [ enabled := false ].
			(directive = PCRE2 optimizationFull or: [ directive = PCRE2 optimizeStart ]) ifTrue: [ enabled := true ] ].
	^ enabled
]

{ #category : 'callouts' }
PCRE2ContextPharoBackend >> substituteCalloutBlock [

	^ substituteCalloutBlock
]

{ #category : 'callouts' }
PCRE2ContextPharoBackend >> substituteCalloutBlock: block [

	substituteCalloutBlock := block
]

{ #category : 'callouts' }
PCRE2ContextPharoBackend >> substituteCaseCalloutBlock [

	^ substituteCaseCalloutBlock
]

{ #category : 'callouts' }
PCRE2ContextPharoBackend >> substituteCaseCalloutBlock: block [

	substituteCaseCalloutBlock := block
]
