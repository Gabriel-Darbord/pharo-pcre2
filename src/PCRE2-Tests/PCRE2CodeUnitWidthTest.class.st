"
Parametrized tests for PCRE2 behavior that should be identical across the 8-, 16-, and 32-bit code-unit APIs.

Keep width-specific byte layout tests in the concrete UTF input test classes; this class is for shared contracts where only the compiler, library, and input conversion hook vary.
"
Class {
	#name : 'PCRE2CodeUnitWidthTest',
	#superclass : 'ParametrizedTestCase',
	#instVars : [
		'compilerClass',
		'libraryClass',
		'inputSelector',
		'codeUnitWidth',
		'isSupported'
	],
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'building suites' }
PCRE2CodeUnitWidthTest class >> testParameters [

	^ ParametrizedTestMatrix new
		  addCase: {
				  (#codeUnitWidth -> 8).
				  (#compilerClass -> PCRE2UTF8Compiler).
				  (#libraryClass -> LibPCRE2UTF8).
				  (#inputSelector -> #asPCRE2UTF8Input).
				  (#isSupported -> true) };
		  addCase: {
				  (#codeUnitWidth -> 16).
				  (#compilerClass -> PCRE2UTF16Compiler).
				  (#libraryClass -> LibPCRE2UTF16).
				  (#inputSelector -> #asPCRE2UTF16Input).
				  (#isSupported -> [ LibPCRE2UTF8 supports16BitCodeUnitWidth ]) };
		  addCase: {
				  (#codeUnitWidth -> 32).
				  (#compilerClass -> PCRE2UTF32Compiler).
				  (#libraryClass -> LibPCRE2UTF32).
				  (#inputSelector -> #asPCRE2UTF32Input).
				  (#isSupported -> [ LibPCRE2UTF8 supports32BitCodeUnitWidth ]) };
		  yourself
]

{ #category : 'accessing' }
PCRE2CodeUnitWidthTest >> codeUnitWidth: anInteger [

	codeUnitWidth := anInteger
]

{ #category : 'accessing' }
PCRE2CodeUnitWidthTest >> compilerClass: aClass [

	compilerClass := aClass
]

{ #category : 'accessing' }
PCRE2CodeUnitWidthTest >> inputSelector: aSymbol [

	inputSelector := aSymbol
]

{ #category : 'accessing' }
PCRE2CodeUnitWidthTest >> isSupported: aBoolean [

	isSupported := aBoolean
]

{ #category : 'accessing' }
PCRE2CodeUnitWidthTest >> libraryClass: aClass [

	libraryClass := aClass
]

{ #category : 'private' }
PCRE2CodeUnitWidthTest >> preparedInputFor: aString [

	^ aString perform: inputSelector
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testCompilerAcceptsPreparedPatternInput [

	| bytes prepared regex |
	isSupported ifFalse: [ ^ self ].

	prepared := self preparedInputFor: 'é+'.
	regex := compilerClass new compile: prepared.

	self assert: regex codeUnitWidth equals: codeUnitWidth.
	self assert: regex pattern equals: 'é+'.
	self assert: (regex matches: 'éé').
	self deny: (regex matches: 'ee').

	bytes := prepared bytes.
	regex := compilerClass new compile: bytes.

	self assert: regex codeUnitWidth equals: codeUnitWidth.
	self assert: regex pattern equals: 'é+'.
	self assert: (regex matches: 'éé').
	self deny: (regex matches: 'ee')
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testLibraryCanConvertPreparedGlobBytes [

	| patternBytes regex |
	isSupported ifFalse: [ ^ self ].
	LibPCRE2UTF8 supportsPatternConversion ifFalse: [ ^ self ].

	patternBytes := (self preparedInputFor: '*é') bytes.
	regex := compilerClass new compile:
		         (libraryClass convertGlob: patternBytes).

	self assert: regex codeUnitWidth equals: codeUnitWidth.
	self assert: (regex matches: 'café').
	self deny: (regex matches: 'cafe')
]
