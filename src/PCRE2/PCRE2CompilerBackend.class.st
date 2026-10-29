"
Abstract implementation selected by a PCRE2Compiler. Backends own compilation details; public compilers own the API and backend choice.
"
Class {
	#name : 'PCRE2CompilerBackend',
	#superclass : 'Object',
	#instVars : [
		'compiler'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'instance creation' }
PCRE2CompilerBackend class >> for: aCompiler [

	^ self new compiler: aCompiler
]

{ #category : 'instance creation' }
PCRE2CompilerBackend class >> isAbstract [

	^ self = PCRE2CompilerBackend
]

{ #category : 'backends' }
PCRE2CompilerBackend >> codeUnitWidth [

	^ compiler codeUnitWidth
]

{ #category : 'accessing' }
PCRE2CompilerBackend >> compiler [

	^ compiler
]

{ #category : 'accessing' }
PCRE2CompilerBackend >> compiler: aCompiler [

	compiler := aCompiler
]

{ #category : 'compiling' }
PCRE2CompilerBackend >> prepareForCompile [

	^ self
]

{ #category : 'accessing' }
PCRE2CompilerBackend >> requiresSessionRestore [

	^ false
]

{ #category : 'accessing' }
PCRE2CompilerBackend >> supportsJIT [

	^ false
]
