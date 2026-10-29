"
Public compiler facade. New compilers capture the configured default backend; backend: explicitly selects an implementation before context creation. Width-specific subclasses preserve the UTF-8/16/32 input API. FFI remains the default when loaded; the Pharo implementation is experimental.
"
Class {
	#name : 'PCRE2Compiler',
	#superclass : 'Object',
	#traits : 'PCRE2TWithOptions',
	#classTraits : 'PCRE2TWithOptions classTrait',
	#instVars : [
		'optionsJIT',
		'context',
		'backend'
	],
	#classVars : [
		'DefaultBackend',
		'EagerJIT',
		'SupportsJIT'
	],
	#classInstVars : [
		'default'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'accessing' }
PCRE2Compiler class >> default [

	self == PCRE2Compiler ifTrue: [
			(default isNil or: [ default class ~~ PCRE2UTF8Compiler ]) ifTrue: [ default := PCRE2UTF8Compiler new ].
			^ default ].
	^ self new
]

{ #category : 'accessing' }
PCRE2Compiler class >> defaultBackend [

	^ DefaultBackend ifNil: [
			  Smalltalk globals
				  at: #PCRE2CompilerFFIBackend
				  ifAbsent: [ Smalltalk globals at: #PCRE2CompilerPharoBackend ifAbsent: [ PCRE2Error signal: 'No PCRE2 backend is loaded' ] ] ]
]

{ #category : 'backends' }
PCRE2Compiler class >> defaultBackend: aBackendClass [

	(aBackendClass isBehavior and: [ aBackendClass inheritsFrom: PCRE2CompilerBackend ]) ifFalse: [
		PCRE2Error signal: 'Expected a PCRE2 compiler backend class' ].
	DefaultBackend := aBackendClass.
	default := nil.
	SupportsJIT := nil
]

{ #category : 'accessing' }
PCRE2Compiler class >> eagerJIT [

	^ EagerJIT
]

{ #category : 'accessing' }
PCRE2Compiler class >> eagerJIT: aBoolean [
	"Whether to also try JIT compilation when processing a pattern"

	EagerJIT := aBoolean
]

{ #category : 'backends' }
PCRE2Compiler class >> initialize [

	EagerJIT := true.
	SupportsJIT := nil
]

{ #category : 'testing' }
PCRE2Compiler class >> isAbstract [

	^ self == PCRE2Compiler
]

{ #category : 'backends' }
PCRE2Compiler class >> nativeLibraryAvailable [

	^ self defaultBackend isAvailable
]

{ #category : 'instance creation' }
PCRE2Compiler class >> new [

	self == PCRE2Compiler ifTrue: [ ^ PCRE2UTF8Compiler basicNew initialize ].
	^ super new
]

{ #category : 'API' }
PCRE2Compiler class >> pattern: aString [
	"Compile a regular expression with default options"

	^ self default compile: aString
]

{ #category : 'API' }
PCRE2Compiler class >> pattern: aString options: anInteger [
	"Overwrite default options"

	^ self new
		  options: anInteger;
		  compile: aString
]

{ #category : 'backends' }
PCRE2Compiler class >> startUp: resuming [

	SupportsJIT := false.
	default := nil.
	resuming ifTrue: [ self nativeLibraryAvailable ifTrue: [ SupportsJIT := self new backend supportsJIT ] ]
]

{ #category : 'backends' }
PCRE2Compiler class >> supportsJIT [

	^ SupportsJIT ifNil: [ SupportsJIT := self new backend supportsJIT ]
]

{ #category : 'backends' }
PCRE2Compiler >> backend [

	^ backend ifNil: [ backend := self class defaultBackend for: self ]
]

{ #category : 'backends' }
PCRE2Compiler >> backend: aBackendClass [

	(aBackendClass isBehavior and: [ aBackendClass inheritsFrom: PCRE2CompilerBackend ]) ifFalse: [
		PCRE2Error signal: 'Expected a PCRE2 compiler backend class' ].
	context ifNotNil: [ PCRE2Error signal: 'Select a backend before creating the compile context' ].
	backend := aBackendClass for: self
]

{ #category : 'backends' }
PCRE2Compiler >> compile: pattern [

	| input matcher |
	input := self preparedPatternFor: pattern.
	matcher := self matcherClass new backend: (self backend compilePreparedInput: input).
	matcher
		pattern: (self patternStringFromInput: input);
		patternInput: input;
		compiler: self.
	matcher isJIT: (EagerJIT and: [ self backend supportsJIT and: [ (self backend privateJITCompile: matcher backend) = 0 ] ]).
	^ matcher
]

{ #category : 'private' }
PCRE2Compiler >> compile: pattern upTo: length errorCode: errorCode errorOffset: errorOffset [

	self subclassResponsibility
]

{ #category : 'compiling' }
PCRE2Compiler >> compileBasic: pattern [
	"Creates a regex matcher from a pattern and returns its external address."

	^ self compilePreparedInput: (self preparedPatternFor: pattern)
]

{ #category : 'private' }
PCRE2Compiler >> compileContextClass [

	^ self backend compileContextClass
]

{ #category : 'compiling' }
PCRE2Compiler >> compileJIT: matcher [
	"Request JIT compilation, which, if the just-in-time compiler is available,
	further processes a compiled pattern into machine code that runs much faster
	than the interpretive match() function.
	Can be called multiple times for the same compiled pattern and
	does nothing if it has previously compiled code for any of the option bits.
	If no options are set (=0), JIT compilation does nothing and always succeeds.
	Available options are jitComplete, jitPartialSoft and jitPartialHard."

	^ self compileJIT: matcher onError: [ :rc | self errorCode: rc ]
]

{ #category : 'compiling' }
PCRE2Compiler >> compileJIT: matcher onError: aBlock [

	| rc |
	rc := self privateJITCompile: matcher.
	rc == 0 ifFalse: [ aBlock value: rc ].
	^ matcher isJIT: true
]

{ #category : 'compiling' }
PCRE2Compiler >> compilePreparedInput: input [

	^ self backend compileBasicInput: input
]

{ #category : 'accessing' }
PCRE2Compiler >> context [

	^ context ifNil: [ context := self newCompileContext ]
]

{ #category : 'accessing' }
PCRE2Compiler >> context: aCompileContext [

	aCompileContext ifNotNil: [
			(aCompileContext isKindOf: PCRE2CompileContext) ifFalse: [ PCRE2Error signal: 'Expected a compile context' ].
			(aCompileContext backend family = self backend family and: [ aCompileContext backend codeUnitWidth = self codeUnitWidth ])
				ifFalse: [ PCRE2Error signal: 'Compile context must use the same backend and code-unit width as the compiler' ] ].
	context := aCompileContext
]

{ #category : 'copying' }
PCRE2Compiler >> copyContextIfPresent [
	"Answer a copy of the compile context when one was explicitly created, without forcing a new context. A stale wrapper whose native handle is already null is treated as absent."

	context ifNil: [ ^ nil ].
	context isNull ifTrue: [
			context := nil.
			^ nil ].
	^ context copy
]

{ #category : 'private' }
PCRE2Compiler >> createCompileContext [

	^ self backend createCompileContext
]

{ #category : 'error handling' }
PCRE2Compiler >> errorCode: errorCode [

	<debuggerCompleteToSender>
	PCRE2CompileError signal: (PCRE2 translateErrorCode: errorCode)
]

{ #category : 'error handling' }
PCRE2Compiler >> errorCode: errorCode in: input at: codeUnitOffset [
	"Signal a compile error reported for prepared PCRE2 input at a zero-based code-unit offset."

	<debuggerCompleteToSender>
	PCRE2CompileError signal: (PCRE2 translateErrorCode: errorCode) in: input at: codeUnitOffset
]

{ #category : 'backends' }
PCRE2Compiler >> existingContext [

	^ context
]

{ #category : 'backends' }
PCRE2Compiler >> ffiLibraryName [

	^ self backend ffiLibraryName
]

{ #category : 'initialization' }
PCRE2Compiler >> initialize [

	options := PCRE2 utf.
	optionsJIT := PCRE2 jitComplete.
	backend := self class defaultBackend for: self
]

{ #category : 'private' }
PCRE2Compiler >> inputClass [

	self subclassResponsibility
]

{ #category : 'private' }
PCRE2Compiler >> matcherClass [

	self subclassResponsibility
]

{ #category : 'backends' }
PCRE2Compiler >> newCompileContext [

	^ self backend newCompileContext
]

{ #category : 'accessing' }
PCRE2Compiler >> optionsJIT [

	^ optionsJIT
]

{ #category : 'accessing' }
PCRE2Compiler >> optionsJIT: anInteger [
	"See jitComplete, jitPartialSoft and jitPartialHard class methods of PCRE2."

	optionsJIT := anInteger
]

{ #category : 'private' }
PCRE2Compiler >> patternStringFromInput: input [

	^ input displayFrom: 1 to: input size
]

{ #category : 'backends' }
PCRE2Compiler >> postCopy [

	backend := backend ifNotNil: [ backend copy compiler: self ].
	context := context ifNotNil: [ context copy autoRelease ]
]

{ #category : 'private' }
PCRE2Compiler >> preparedPatternFor: aStringOrInput [
	"Prepare a pattern object for this compiler's PCRE2 code-unit width. Concrete compilers accept Strings and may also accept width-specific prepared input objects or byte storage."

	self subclassResponsibility
]

{ #category : 'private' }
PCRE2Compiler >> privateJITCompile: matcher [

	^ self backend
		  prepareForCompile;
		  privateJITCompile: matcher backend
]
