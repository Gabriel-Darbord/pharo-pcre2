"
Experimental Pharo implementation of PCRE2 compilation. Parses patterns into executable Pharo nodes, with no C library calls. Unsupported syntax and options signal PCRE2UnsupportedFeature.
"
Class {
	#name : 'PCRE2CompilerPharoBackend',
	#superclass : 'PCRE2CompilerBackend',
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'testing' }
PCRE2CompilerPharoBackend class >> isAvailable [

	^ true
]

{ #category : 'compiling' }
PCRE2CompilerPharoBackend >> compileBasicInput: input [

	PCRE2UnsupportedFeature signal: 'The Pharo backend does not produce C handles'
]

{ #category : 'backends' }
PCRE2CompilerPharoBackend >> compileContextClass [

	compiler codeUnitWidth = 8 ifTrue: [ ^ PCRE2UTF8CompileContext ].
	^ compiler codeUnitWidth = 16
		  ifTrue: [ PCRE2UTF16CompileContext ]
		  ifFalse: [ PCRE2UTF32CompileContext ]
]

{ #category : 'compiling' }
PCRE2CompilerPharoBackend >> compilePreparedInput: input [

	| parser tree flags allowed context implementation |
	flags := compiler options.
	allowed := PCRE2 caseless | PCRE2 dotAll | PCRE2 multiline | PCRE2 ungreedy | PCRE2 extended | PCRE2 utf | PCRE2 ucp
	           | PCRE2 anchored | PCRE2 endAnchored | PCRE2 noAutoCapture | PCRE2 dupNames | PCRE2 literal | PCRE2 dollarEndOnly
	           | PCRE2 noStartOptimize | PCRE2 useOffsetLimit | PCRE2 noAutoPossess | PCRE2 noDotstarAnchor | PCRE2 matchUnsetBackref
	           | PCRE2 extendedMore | PCRE2 altCircumflex | PCRE2 autoCallout | PCRE2 neverUTF | PCRE2 neverUCP
	           | PCRE2 neverBackslashC | PCRE2 firstLine | PCRE2 noUTFCheck | PCRE2 altBSUX.
	(flags bitAnd: allowed bitInvert) ~= 0 ifTrue: [
		PCRE2UnsupportedFeature signal: 'Compile options are not yet implemented by the Pharo backend' ].
	parser := PCRE2PatternParser new codeUnitWidth: compiler codeUnitWidth.
	context := compiler existingContext.
	context ifNotNil: [
			context backend startOptimizationEnabled ifFalse: [ flags := flags bitOr: PCRE2 noStartOptimize ].
			(context options bitAnd:
				 (PCRE2 extraBadEscapeIsLiteral | PCRE2 extraAltBsux | PCRE2 extraEscapedCrIsLf | PCRE2 extraAllowSurrogateEscapes
				  | PCRE2 extraAsciiBsd | PCRE2 extraAsciiBss | PCRE2 extraAsciiBsw | PCRE2 extraAsciiPosix | PCRE2 extraAsciiDigit
				  | PCRE2 extraCaselessRestrict | PCRE2 extraMatchLine | PCRE2 extraMatchWord) bitInvert) ~= 0 ifTrue: [
				PCRE2UnsupportedFeature signal: 'Extra compile options are not yet implemented by the Pharo backend' ].
			parser extraOptions: context options.
			context maxPatternLength ifNotNil: [ :length |
					input size > length ifTrue: [
						PCRE2CompileError signal: 'pattern string is longer than the limit set by the application' in: input at: 0 ] ].
			parser
				nestLimit: context parensNestLimit;
				lookbehindLimit: context maxVarLookbehind ].
	parser
		newline: (context ifNil: [ PCRE2 newlineLF ] ifNotNil: [ context newline ])
		bsr: (context ifNil: [ PCRE2 bsrUnicode ] ifNotNil: [ context bsr ]).
	tree := parser parse: input options: flags.
	implementation := PCRE2MatcherPharoBackend new
		                  root: tree parser: parser;
		                  compileOptions: parser compiledOptions.
	context ifNotNil: [
			context maxPatternCompiledLength ifNotNil: [ :maximum |
					implementation compiledStorageSize > maximum ifTrue: [
						PCRE2CompileError signal: 'compiled pattern would be longer than the limit set by the application' in: input at: 0 ] ] ].
	^ implementation
]

{ #category : 'backends' }
PCRE2CompilerPharoBackend >> family [

	^ #pharo
]

{ #category : 'backends' }
PCRE2CompilerPharoBackend >> newCompileContext [

	^ self compileContextClass new backend: (PCRE2ContextPharoBackend new codeUnitWidth: compiler codeUnitWidth)
]

{ #category : 'compiling' }
PCRE2CompilerPharoBackend >> privateJITCompile: aMatcher [

	PCRE2UnsupportedFeature signal: 'The Pharo backend does not implement PCRE2 JIT'
]
