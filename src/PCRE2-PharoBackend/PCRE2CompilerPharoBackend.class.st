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

	| parser tree flags allowed context |
	flags := compiler options.
	allowed := PCRE2 caseless | PCRE2 dotAll | PCRE2 multiline | PCRE2 ungreedy | PCRE2 extended | PCRE2 utf | PCRE2 ucp
	           | PCRE2 anchored | PCRE2 endAnchored | PCRE2 noAutoCapture | PCRE2 dupNames | PCRE2 literal | PCRE2 dollarEndOnly
	           | PCRE2 noStartOptimize | PCRE2 useOffsetLimit | PCRE2 noAutoPossess | PCRE2 noDotstarAnchor | PCRE2 matchUnsetBackref.
	(flags bitAnd: allowed bitInvert) ~= 0 ifTrue: [
		PCRE2UnsupportedFeature signal: 'Compile options are not yet implemented by the Pharo backend' ].
	parser := PCRE2PatternParser new.
	context := compiler existingContext.
	context ifNotNil: [
			context newline = PCRE2 newlineLF ifFalse: [
				PCRE2UnsupportedFeature signal: 'Non-LF newline modes are not yet implemented by the Pharo backend' ].
			context maxPatternCompiledLength ifNotNil: [
				PCRE2UnsupportedFeature signal: 'Compiled byte-size limits are specific to the FFI backend' ].
			context maxPatternLength ifNotNil: [ :length |
				input size > length ifTrue: [ PCRE2CompileError signal: 'pattern is too long' in: input at: 0 ] ].
			parser
				nestLimit: context parensNestLimit;
				lookbehindLimit: context maxVarLookbehind ].
	tree := parser parse: input options: flags.
	^ PCRE2MatcherPharoBackend new
		  root: tree parser: parser;
		  compileOptions: flags
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
