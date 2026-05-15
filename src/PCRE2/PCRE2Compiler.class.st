"
Abstract superclass for PCRE2 compilers.

Concrete subclasses bind the width-specific PCRE2 compile and JIT entry points: PCRE2UTF8Compiler, PCRE2UTF16Compiler, and PCRE2UTF32Compiler. This class keeps the shared compile flow, options, compile context handling, error reporting, and default JIT policy.

For compatibility and normal user code, PCRE2Compiler new answers a PCRE2UTF8Compiler. Most users should keep using String>>asPerlCompatibleRegex or PCRE2Compiler directly unless they need a specific code-unit width.
"
Class {
	#name : 'PCRE2Compiler',
	#superclass : 'Object',
	#traits : 'PCRE2TWithOptions',
	#classTraits : 'PCRE2TWithOptions classTrait',
	#instVars : [
		'optionsJIT',
		'context'
	],
	#classVars : [
		'EagerJIT',
		'SupportsJIT'
	],
	#pools : [
		'PCRE2Types'
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
		(default isNil or: [ default class ~~ PCRE2UTF8Compiler ]) ifTrue: [
			default := PCRE2UTF8Compiler new ].
		^ default ].
	^ self new
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

{ #category : 'class initialization' }
PCRE2Compiler class >> initialize [

	EagerJIT := true.
	self startUp: true.
	SessionManager default registerToolClassNamed: self name
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

{ #category : 'system startup' }
PCRE2Compiler class >> startUp: resuming [
	"Verify that the loaded native library matches the assumptions of this binding."

	resuming ifFalse: [ ^ self ].
	PCRE2Types initialize. "Ensure shared UFFI holders exist before startup FFI calls."
	LibPCRE2 assertCompatibleLibrary.
	SupportsJIT := LibPCRE2 supportsJIT
]

{ #category : 'accessing' }
PCRE2Compiler class >> supportsJIT [

	^ SupportsJIT
]

{ #category : 'compiling' }
PCRE2Compiler >> compile: pattern [
	"Compile a pattern into a regular expression matcher.
	Patterns are usually strings. Width-specific compilers may also accept prepared encoded input."

	| input matcher |
	input := self preparedPatternFor: pattern.
	(matcher := self matcherClass fromHandle:
			            (self compilePreparedInput: input))
		autoRelease;
		initialize;
		pattern: (self patternStringFromInput: input);
		compiler: self.
	matcher isJIT: (EagerJIT and: [
			 SupportsJIT and: [ (self privateJITCompile: matcher) == 0 ] ]).
	^ matcher
]

{ #category : 'private' }
PCRE2Compiler >> compile: pattern upTo: length errorCode: errorCode errorOffset: errorOffset [
	^ self subclassResponsibility
]

{ #category : 'compiling' }
PCRE2Compiler >> compileBasic: pattern [
	"Creates a regex matcher from a pattern and returns its external address."

	^ self compilePreparedInput: (self preparedPatternFor: pattern)
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

	| rc |
	rc := self privateJITCompile: matcher.
	rc == 0 ifFalse: [ self errorCode: rc ].
	^ matcher isJIT: true
]

{ #category : 'compiling' }
PCRE2Compiler >> compilePreparedInput: input [
	"Create a regex matcher handle from prepared pattern input."

	| errorCode errorOffset handle |
	errorCode := IntHolder new.
	errorOffset := SizeTHolder new.
	handle := self
		          compile: input bytes
		          upTo: input size
		          errorCode: errorCode
		          errorOffset: errorOffset.
	handle isNull ifTrue: [
		self errorCode: errorCode value inInput: input at: errorOffset value ].
	^ handle
]

{ #category : 'accessing' }
PCRE2Compiler >> context [

	^ context ifNil: [
		  context := self createCompileContext.
		  context isNull ifTrue: [
			  context := nil.
			  PCRE2Error signal:
				  'Failed to obtain memory to create compile context' ].
		  context autoRelease ]
]

{ #category : 'accessing' }
PCRE2Compiler >> context: aCompileContext [

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
	^ self subclassResponsibility
]

{ #category : 'error handling' }
PCRE2Compiler >> errorCode: errorCode [

	<debuggerCompleteToSender>
	PCRE2CompileError signal: (PCRE2 translateErrorCode: errorCode)
]

{ #category : 'error handling' }
PCRE2Compiler >> errorCode: errorCode in: pattern at: offset [

	<debuggerCompleteToSender>
	PCRE2CompileError
		signal: (PCRE2 translateErrorCode: errorCode)
		in: pattern
		at: offset
]

{ #category : 'error handling' }
PCRE2Compiler >> errorCode: errorCode inInput: input at: offset [

	<debuggerCompleteToSender>
	PCRE2CompileError
		signal: (PCRE2 translateErrorCode: errorCode)
		inInput: input
		at: offset
]

{ #category : 'library path' }
PCRE2Compiler >> ffiLibraryName [
	^ self subclassResponsibility
]

{ #category : 'initialization' }
PCRE2Compiler >> initialize [
	"Set default options for (JIT-)compiling.
	Use UTF option because whether subjects will have non-ASCII codepoints cannot be known.
	You can skip this option if you are working with ASCII and need speed, although the difference is small."

	options := 524288. "PCRE2 utf"
	optionsJIT := 1 "PCRE2 jitComplete"
]

{ #category : 'private' }
PCRE2Compiler >> inputClass [
	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2Compiler >> matcherClass [
	^ self subclassResponsibility
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

	input size = 0 ifTrue: [ ^ '' ].
	^ input readFrom: 1 to: input size
]

{ #category : 'private' }
PCRE2Compiler >> preparedPatternFor: pattern [

	^ self inputClass fromString: pattern
]

{ #category : 'private' }
PCRE2Compiler >> privateJITCompile: matcher [
	^ self subclassResponsibility
]
