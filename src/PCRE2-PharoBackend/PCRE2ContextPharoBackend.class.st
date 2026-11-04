"
Compile- and match-context implementation for the Pharo backend. Its settings are ordinary image state, so it has no external handle to free or to restore when a session resumes.
"
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

{ #category : 'defaults' }
PCRE2ContextPharoBackend class >> defaultDepthLimit [

	^ 10000000
]

{ #category : 'defaults' }
PCRE2ContextPharoBackend class >> defaultHeapLimit [

	^ 20000000
]

{ #category : 'defaults' }
PCRE2ContextPharoBackend class >> defaultMatchLimit [

	^ 10000000
]

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

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> bsr [

	^ bsr
]

{ #category : 'configuration' }
PCRE2ContextPharoBackend >> bsr: value [

	(#( 1 2 ) includes: value) ifFalse: [ PCRE2Error signal: 'bad option value' ].
	bsr := value
]

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> calloutBlock [

	^ calloutBlock
]

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> calloutBlock: block [

	calloutBlock := block
]

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> characterTables [

	^ nil
]

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> characterTables: tables [

	tables ifNotNil: [ self signalLocaleTablesUnsupported ]
]

{ #category : 'callouts' }
PCRE2ContextPharoBackend >> clearCallout [

	calloutBlock := nil
]

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> clearCharacterTables [

	^ self
]

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> clearJITStack [

	^ self
]

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> codeUnitWidth [

	^ codeUnitWidth
]

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> codeUnitWidth: anInteger [

	codeUnitWidth := anInteger
]

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> depthLimit [

	^ depthLimit
]

{ #category : 'limits' }
PCRE2ContextPharoBackend >> depthLimit: anInteger [

	(anInteger isInteger and: [ anInteger between: 0 and: 16rFFFFFFFF ]) ifFalse: [
		PCRE2Error signal: 'Depth limit must be an unsigned 32-bit integer' ].
	depthLimit := anInteger
]

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> family [

	^ #pharo
]

{ #category : 'finalization' }
PCRE2ContextPharoBackend >> finalize [

	^ self
]

{ #category : 'configuration' }
PCRE2ContextPharoBackend >> free [

	^ self
]

{ #category : 'accessing' }
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

	matchLimit := self class defaultMatchLimit.
	depthLimit := self class defaultDepthLimit.
	heapLimit := self class defaultHeapLimit.
	newline := PCRE2 newlineLF.
	bsr := PCRE2 bsrUnicode.
	parensNestLimit := 250.
	maxVarLookbehind := 255
]

{ #category : 'initialization' }
PCRE2ContextPharoBackend >> isNull [

	^ false
]

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> jitStack [

	^ nil
]

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> jitStack: stack [

	stack ifNotNil: [ PCRE2UnsupportedFeature signal: 'PCRE2 JIT stacks are specific to the FFI backend' ]
]

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> matchLimit [

	^ matchLimit
]

{ #category : 'limits' }
PCRE2ContextPharoBackend >> matchLimit: anInteger [

	(anInteger isInteger and: [ anInteger between: 0 and: 16rFFFFFFFF ]) ifFalse: [
		PCRE2Error signal: 'Match limit must be an unsigned 32-bit integer' ].
	matchLimit := anInteger
]

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> maxPatternCompiledLength [

	^ maxPatternCompiledLength
]

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> maxPatternCompiledLength: anInteger [

	maxPatternCompiledLength := anInteger
]

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> maxPatternLength [

	^ maxPatternLength
]

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> maxPatternLength: anInteger [

	maxPatternLength := anInteger
]

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> maxVarLookbehind [

	^ maxVarLookbehind
]

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> maxVarLookbehind: anInteger [

	maxVarLookbehind := anInteger
]

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> newline [

	^ newline
]

{ #category : 'configuration' }
PCRE2ContextPharoBackend >> newline: value [

	(value isInteger and: [ value between: PCRE2 newlineCR and: PCRE2 newlineNul ]) ifFalse: [ PCRE2Error signal: 'bad option value' ].
	newline := value
]

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> offsetLimit [

	^ offsetLimit
]

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> offsetLimit: anInteger [

	offsetLimit := anInteger
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

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> parensNestLimit [

	^ parensNestLimit
]

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> parensNestLimit: anInteger [

	parensNestLimit := anInteger
]

{ #category : 'persistence' }
PCRE2ContextPharoBackend >> prepareForShutdown [

	^ self
]

{ #category : 'copying' }
PCRE2ContextPharoBackend >> privateCopy [
	"The settings are image state, so a plain copy is a private one."

	^ self copy
]

{ #category : 'configuration' }
PCRE2ContextPharoBackend >> removeOptions: flags [

	self options: (self options bitAnd: flags bitInvert)
]

{ #category : 'testing' }
PCRE2ContextPharoBackend >> requiresSessionRestore [

	^ false
]

{ #category : 'persistence' }
PCRE2ContextPharoBackend >> restoreAfterStartup [

	^ self
]

{ #category : 'private' }
PCRE2ContextPharoBackend >> signalLocaleTablesUnsupported [

	PCRE2UnsupportedFeature signal: 'Locale character tables are specific to the FFI backend'
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

{ #category : 'accessing' }
PCRE2ContextPharoBackend >> useCharacterTablesFromCurrentLocale [

	self signalLocaleTablesUnsupported
]
