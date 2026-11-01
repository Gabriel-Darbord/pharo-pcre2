"
Compiles patterns through the host PCRE2 library. Width-specific subclasses contain the UFFI entry points.
"
Class {
	#name : 'PCRE2CompilerFFIBackend',
	#superclass : 'PCRE2CompilerBackend',
	#instVars : [
		'options',
		'context',
		'optionsJIT'
	],
	#pools : [
		'PCRE2Types'
	],
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'instance creation' }
PCRE2CompilerFFIBackend class >> for: aCompiler [

	| backendClass |
	backendClass := aCompiler codeUnitWidth = 8
		                ifTrue: [ PCRE2CompilerUTF8FFIBackend ]
		                ifFalse: [
				                aCompiler codeUnitWidth = 16
					                ifTrue: [ PCRE2CompilerUTF16FFIBackend ]
					                ifFalse: [ PCRE2CompilerUTF32FFIBackend ] ].
	^ backendClass new compiler: aCompiler
]

{ #category : 'testing' }
PCRE2CompilerFFIBackend class >> isAbstract [

	^ self == PCRE2CompilerFFIBackend
]

{ #category : 'testing' }
PCRE2CompilerFFIBackend class >> isAvailable [

	^ LibPCRE2UTF8 isNativeLibraryAvailable
]

{ #category : 'testing' }
PCRE2CompilerFFIBackend class >> supportsCodeUnitWidth: anInteger [
	"Answer whether the host PCRE2 build provides the library for this code-unit width. The 16-bit and 32-bit libraries are optional and are often left out."

	anInteger = 8 ifTrue: [ ^ LibPCRE2 supports8BitCodeUnitWidth ].
	anInteger = 16 ifTrue: [ ^ LibPCRE2 supports16BitCodeUnitWidth ].
	anInteger = 32 ifTrue: [ ^ LibPCRE2 supports32BitCodeUnitWidth ].
	^ false
]

{ #category : 'private' }
PCRE2CompilerFFIBackend >> compile: pattern upTo: length errorCode: errorCode errorOffset: errorOffset [
	"Call the PCRE2 library of this backend's code-unit width. Each width subclass binds its own function."

	self subclassResponsibility
]

{ #category : 'compiling' }
PCRE2CompilerFFIBackend >> compileBasicInput: input [

	| errorCode errorOffset handle |
	self prepareForCompile.
	self ffiLibraryName assertCompatibleLibrary.
	errorCode := IntHolder new.
	errorOffset := SizeTHolder new.
	handle := self
		          compile: input bytes
		          upTo: input size
		          errorCode: errorCode
		          errorOffset: errorOffset.
	handle isNull ifTrue: [ compiler errorCode: errorCode value in: input at: errorOffset value ].
	^ handle
]

{ #category : 'compiling' }
PCRE2CompilerFFIBackend >> compilePreparedInput: input [

	^ (self matcherBackendClass fromHandle: (self compileBasicInput: input)) autoRelease
]

{ #category : 'accessing' }
PCRE2CompilerFFIBackend >> family [

	^ #ffi
]

{ #category : 'compiling' }
PCRE2CompilerFFIBackend >> newCompileContext [

	| pointer |
	pointer := self createCompileContext.
	pointer isNull ifTrue: [ PCRE2Error signal: 'Failed to obtain memory to create compile context' ].
	^ (self compileContextClass fromHandle: pointer) initialize autoRelease
]

{ #category : 'private' }
PCRE2CompilerFFIBackend >> prepareForCompile [

	options := compiler options.
	optionsJIT := compiler optionsJIT.
	context := compiler existingContext ifNotNil: [ :aContext | aContext backend ]
]

{ #category : 'compiling' }
PCRE2CompilerFFIBackend >> requiresSessionRestore [

	^ true
]

{ #category : 'compiling' }
PCRE2CompilerFFIBackend >> supportsJIT [

	^ self ffiLibraryName supportsJIT
]
