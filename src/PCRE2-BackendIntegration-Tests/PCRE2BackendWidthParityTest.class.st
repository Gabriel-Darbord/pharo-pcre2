"
Backend agreement on what a code unit is: raw units outside any UTF encoding, and the diagnostics a malformed UTF pattern produces. Every test runs once per backend and code-unit width.

Behavior that does not depend on the width belongs in PCRE2BackendParityTest.
"
Class {
	#name : 'PCRE2BackendWidthParityTest',
	#superclass : 'ParametrizedTestCase',
	#instVars : [
		'backend',
		'compilerClass',
		'codeUnitWidth',
		'invalidPatternErrorCode'
	],
	#category : 'PCRE2-BackendIntegration-Tests',
	#package : 'PCRE2-BackendIntegration-Tests'
}

{ #category : 'building suites' }
PCRE2BackendWidthParityTest class >> testParameters [
	"The error codes are PCRE2_ERROR_UTF8_ERR1, PCRE2_ERROR_UTF16_ERR1 and PCRE2_ERROR_UTF32_ERR2, which the malformed pattern of each width produces."

	^ ParametrizedTestMatrix new
		  forSelector: #backend addOptions: {
				  PCRE2CompilerFFIBackend.
				  PCRE2CompilerPharoBackend };
		  addCase: {
				  (#codeUnitWidth -> 8).
				  (#compilerClass -> PCRE2UTF8Compiler).
				  (#invalidPatternErrorCode -> -23) };
		  addCase: {
				  (#codeUnitWidth -> 16).
				  (#compilerClass -> PCRE2UTF16Compiler).
				  (#invalidPatternErrorCode -> -24) };
		  addCase: {
				  (#codeUnitWidth -> 32).
				  (#compilerClass -> PCRE2UTF32Compiler).
				  (#invalidPatternErrorCode -> -28) };
		  yourself
]

{ #category : 'accessing' }
PCRE2BackendWidthParityTest >> backend: aBackendClass [

	backend := aBackendClass
]

{ #category : 'accessing' }
PCRE2BackendWidthParityTest >> codeUnitWidth: anInteger [

	codeUnitWidth := anInteger
]

{ #category : 'private' }
PCRE2BackendWidthParityTest >> compileRaw: pattern [
	"Compile without UTF validation, so a raw code unit stands for itself."

	^ compilerClass new
		  backend: backend;
		  options: 0;
		  compile: pattern
]

{ #category : 'private' }
PCRE2BackendWidthParityTest >> compileUTF: pattern [

	^ compilerClass new
		  backend: backend;
		  compile: pattern
]

{ #category : 'accessing' }
PCRE2BackendWidthParityTest >> compilerClass: aClass [

	compilerClass := aClass
]

{ #category : 'private' }
PCRE2BackendWidthParityTest >> invalidPatternBytes [
	"A pattern of one valid code unit followed by one the UTF encoding of this width forbids."

	codeUnitWidth = 8 ifTrue: [ ^ #[ 97 255 ] ].
	codeUnitWidth = 16 ifTrue: [
			^ (ByteArray new: 4)
				  uint16AtOffset: 0 put: 97;
				  uint16AtOffset: 2 put: 16rD800;
				  yourself ].
	^ (ByteArray new: 8)
		  uint32AtOffset: 0 put: 97;
		  uint32AtOffset: 4 put: 16r110000;
		  yourself
]

{ #category : 'accessing' }
PCRE2BackendWidthParityTest >> invalidPatternErrorCode: anInteger [

	invalidPatternErrorCode := anInteger
]

{ #category : 'private' }
PCRE2BackendWidthParityTest >> rawCodeUnitBytes [
	"One code unit whose value no UTF encoding of this width allows."

	codeUnitWidth = 8 ifTrue: [ ^ #[ 255 ] ].
	codeUnitWidth = 16 ifTrue: [
			^ (ByteArray new: 2)
				  uint16AtOffset: 0 put: 16rD800;
				  yourself ].
	^ (ByteArray new: 4)
		  uint32AtOffset: 0 put: 16rFFFFFFFF;
		  yourself
]

{ #category : 'tests' }
PCRE2BackendWidthParityTest >> testMalformedUTFPatternsReportCompileErrors [

	self should: [ self compileUTF: self invalidPatternBytes ] raise: PCRE2CompileError withExceptionDo: [ :error |
			self assert: error offset equals: 1.
			self assert: error errorMessage equals: (PCRE2 translateErrorCode: invalidPatternErrorCode).
			self assert: (error messageText includesSubstring: '(*ERROR)') ]
]

{ #category : 'tests' }
PCRE2BackendWidthParityTest >> testRawCodeUnitMatchingWithoutUTF [

	| matcher input |
	matcher := self compileRaw: '.'.
	input := matcher preparedInputFor: '😀'.
	self assert: (matcher matchBytes: input bytes from: 1 to: input size) offsets equals: #( 0 1 ).
	matcher := self compileRaw: 'é'.
	input := matcher preparedInputFor: 'é'.
	self assert: (matcher matchBytes: input bytes from: 1 to: input size) offsets equals: {
			0.
			input size }
]

{ #category : 'tests' }
PCRE2BackendWidthParityTest >> testRawPatternsSurviveRecompilationAndTracing [

	| bytes matcher |
	bytes := self rawCodeUnitBytes.
	matcher := self compileRaw: bytes.
	self assert: (matcher matchBytes: bytes from: 1 to: 1) offsets equals: #( 0 1 ).
	matcher recompile.
	self assert: (matcher matchBytes: bytes from: 1 to: 1) offsets equals: #( 0 1 ).
	self assert: (matcher traceMatcher matchBytes: bytes from: 1 to: 1) offsets equals: #( 0 1 )
]
