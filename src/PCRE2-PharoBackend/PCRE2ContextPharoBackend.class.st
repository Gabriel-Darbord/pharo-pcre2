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
		'codeUnitWidth'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'backends' }
PCRE2ContextPharoBackend >> addOptions: anInteger [

	self options: anInteger
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

{ #category : 'private' }
PCRE2ContextPharoBackend >> bsr: aValue [

	bsr := aValue
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> calloutBlock: aBlock [

	PCRE2UnsupportedFeature signal: 'Callouts are not yet implemented by the Pharo backend'
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> characterTables [

	^ nil
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> characterTables: tables [

	tables ifNotNil: [ PCRE2UnsupportedFeature signal: 'Locale character tables are specific to the FFI backend' ]
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> clearCallout [

	^ self
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> clearCharacterTables [

	^ self
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> clearJITStack [

	^ self
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> clearSubstituteCallout [

	^ self
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> clearSubstituteCaseCallout [

	^ self
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

{ #category : 'private' }
PCRE2ContextPharoBackend >> heapLimit [

	^ heapLimit
]

{ #category : 'limits' }
PCRE2ContextPharoBackend >> heapLimit: anInteger [

	anInteger = 20000000 ifFalse: [ PCRE2UnsupportedFeature signal: 'Heap byte limits are not yet implemented by the Pharo backend' ].
	heapLimit := anInteger
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

{ #category : 'private' }
PCRE2ContextPharoBackend >> newline: aValue [

	newline := aValue
]

{ #category : 'private' }
PCRE2ContextPharoBackend >> offsetLimit [

	^ offsetLimit
]

{ #category : 'private' }
PCRE2ContextPharoBackend >> offsetLimit: aValue [

	offsetLimit := aValue
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> options [

	^ 0
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> options: anInteger [

	anInteger = 0 ifFalse: [ PCRE2UnsupportedFeature signal: 'Extra compile options are not yet implemented by the Pharo backend' ]
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

{ #category : 'backends' }
PCRE2ContextPharoBackend >> removeOptions: anInteger [

	^ self
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> requiresSessionRestore [

	^ false
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> restoreAfterStartup [

	^ self
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> substituteCalloutBlock: aBlock [

	PCRE2UnsupportedFeature signal: 'Substitution callouts are not yet implemented by the Pharo backend'
]

{ #category : 'backends' }
PCRE2ContextPharoBackend >> substituteCaseCalloutBlock: aBlock [

	PCRE2UnsupportedFeature signal: 'Substitution case callouts are not yet implemented by the Pharo backend'
]
