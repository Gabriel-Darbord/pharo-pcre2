"
I compile patterns into regular expression matchers.

Most of the time, patterns are compiled using String extensions such as `String>>#asPCRegex`.
If more control over the compilation process is needed, my API should be used instead.

Many options exist, use `PCRE2 optionsFor: #compile` to browse available options and combine them with the bitwise OR operator.
Patterns are compiled with the UTF option by default, which allows compilation and matching with UTF-encoded strings (which is the vast majority).
If speed is of the essence and only ASCII characters are handled, the default options can be overridden with `PCRE2Compiler>>#options:`.

My main API is through the `PCRE2Compiler>>#compile:` method.
If enabled and supported by the running architecture, matchers are further processed into machine code that runs much faster than the interpretive match() function.
The cost at compile time is higher, but the gain in matching speed should be well worth it.
This feature is enabled by default and can be toggled with `PCRE2Compiler class>>#eagerJIT:`.
A standard pattern compilation can be performed using `PCRE2Compiler>>#compileNoJIT:`.
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
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'accessing' }
PCRE2Compiler class >> eagerJIT [

	^ EagerJIT
]

{ #category : 'accessing' }
PCRE2Compiler class >> eagerJIT: aBoolean [
	"Whether to also try JIT compiling when processing a pattern"

	EagerJIT := aBoolean
]

{ #category : 'class initialization' }
PCRE2Compiler class >> initialize [

	EagerJIT := true.
	self startUp: true.
	SessionManager default registerToolClassNamed: self name
]

{ #category : 'API' }
PCRE2Compiler class >> pattern: aString [

	^ self new compile: aString
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
	"Verify that the library supports JIT compilation on the current platform"

	resuming ifTrue: [
		PCRE2Types initialize. "TODO handle dependency in baseline"
		SupportsJIT := (LibPCRE2 config: PCRE2 configJIT) == 1 ]
]

{ #category : 'accessing' }
PCRE2Compiler class >> supportsJIT [

	^ SupportsJIT
]

{ #category : 'compiling' }
PCRE2Compiler >> compile: pattern [
	"Compile a pattern string into a regex matcher.
	Try to use JIT compiling if it is available and enabled.
	In case of failure, the result will still be a regular matcher."

	| code |
	code := self compileNoJIT: pattern.
	(EagerJIT and: [ SupportsJIT ]) ifTrue: [
		(self privateJITCompile: code) == 0 ifTrue: [
			code optionsJIT: optionsJIT ] ].
	^ code
]

{ #category : 'private' }
PCRE2Compiler >> compile: pattern upTo: length errorCode: errorcode errorOffset: erroroffset [
"This function reads a regular expression in the form of a string and returns
a pointer to a block of store holding a compiled version of the expression.

Arguments:
  pattern       the regular expression
  patlen        the length of the pattern, or PCRE2_ZERO_TERMINATED
  options       option bits
  errorptr      pointer to errorcode
  erroroffset   pointer to error offset
  ccontext      points to a compile context or is NULL

Returns:        pointer to compiled data block, or NULL on error,
                with errorcode and erroroffset set"

	"pcre2_code *pcre2_compile_8(PCRE2_SPTR pattern, PCRE2_SIZE length, uint32_t options, int *errorcode, PCRE2_SIZE *erroroffset, pcre2_compile_context *ccontext)"

	self ffiCall: #(PCRE2Code *pcre2_compile_8(char *pattern, size_t length, uint32 options, IntHolder errorcode, SizeTHolder erroroffset, void *context))
]

{ #category : 'compiling' }
PCRE2Compiler >> compileJIT: code [
	"Request JIT compilation, which, if the just-in-time compiler is available,
	further processes a compiled pattern into machine code that runs much faster
	than the interpretive match() function.
	Can be called multiple times for the same compiled pattern and
	does nothing if it has previously compiled code for any of the option bits.
	If no options are set (=0), JIT compilation does nothing and always succeeds.
	Available options are jitComplete, jitPartialSoft and jitPartialHard."

	| rc |
	rc := self privateJITCompile: code.
	rc == 0 ifTrue: [ ^ code ].
	self errorCode: rc
]

{ #category : 'compiling' }
PCRE2Compiler >> compileNoJIT: pattern [
	"Compile a pattern string into a regex matcher"

	| utfPattern errorCode errorOffset code |
	utfPattern := ZnUTF8Encoder default encodeString: pattern.
	errorCode := IntHolder new.
	errorOffset := SizeTHolder new.
	code := self
		        compile: utfPattern
		        upTo: utfPattern size
		        errorCode: errorCode
		        errorOffset: errorOffset.
	code isNull ifTrue: [
		self errorCode: errorCode value in: utfPattern at: errorOffset value ].
	^ code autoRelease initialize
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

{ #category : 'accessing' }
PCRE2Compiler >> createCompileContext [
	"This function creates and initializes a new compile context.
	The result is NULL if the memory could not be obtained."

	"pcre2_compile_context *pcre2_compile_context_create(pcre2_general_context *gcontext)"

	self ffiCall: #(PCRE2CompileContext *pcre2_compile_context_create_8(nil))
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

{ #category : 'library path' }
PCRE2Compiler >> ffiLibraryName [

	^ LibPCRE2
]

{ #category : 'initialization' }
PCRE2Compiler >> initialize [
	"Set default options for (JIT-)compiling.
	Use UTF option because whether subjects will have non-ASCII codepoints cannot be known.
	You can skip this option if you are working with ASCII and need speed, although the difference is small."

	options := 524288. "PCRE2 utf"
	optionsJIT := 1 "PCRE2 jitComplete"
]

{ #category : 'accessing' }
PCRE2Compiler >> optionsJIT [

	^ optionsJIT
]

{ #category : 'accessing' }
PCRE2Compiler >> optionsJIT: anInteger [

	optionsJIT := anInteger
]

{ #category : 'private' }
PCRE2Compiler >> privateJITCompile: code [
	"int pcre2_jit_compile(pcre2_code *code, uint32_t options)"

	self ffiCall: #(int pcre2_jit_compile_8(PCRE2Code *code, uint32 optionsJIT))
]
