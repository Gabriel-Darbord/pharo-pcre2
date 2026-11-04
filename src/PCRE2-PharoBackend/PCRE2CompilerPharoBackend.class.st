"
Pharo implementation of PCRE2 compilation, parsing patterns into executable nodes with no C library calls. An option bit PCRE2 does not define, or a facility only the C binding provides such as JIT or a C handle, signals PCRE2UnsupportedFeature.
"
Class {
	#name : 'PCRE2CompilerPharoBackend',
	#superclass : 'PCRE2CompilerBackend',
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'accessing' }
PCRE2CompilerPharoBackend class >> compatibleVersion [

	^ #( 10 49 )
]

{ #category : 'testing' }
PCRE2CompilerPharoBackend class >> isAvailable [

	^ true
]

{ #category : 'compiling' }
PCRE2CompilerPharoBackend >> compileBasicInput: input [

	PCRE2UnsupportedFeature signal: 'The Pharo backend does not produce C handles'
]

{ #category : 'accessing' }
PCRE2CompilerPharoBackend >> compileContextClass [

	^ compiler compileContextClass
]

{ #category : 'compiling' }
PCRE2CompilerPharoBackend >> compilePreparedInput: input [

	| parser tree flags allowed context implementation literalOptions |
	flags := compiler options.
	"PCRE2_MATCH_INVALID_UTF is about the subject, but it implies UTF for the pattern too."
	(flags bitAnd: PCRE2 matchInvalidUTF) ~= 0 ifTrue: [ flags := flags bitOr: PCRE2 utf ].
	allowed := PCRE2 caseless | PCRE2 dotAll | PCRE2 multiline | PCRE2 ungreedy | PCRE2 extended | PCRE2 utf | PCRE2 ucp
	           | PCRE2 anchored | PCRE2 endAnchored | PCRE2 noAutoCapture | PCRE2 dupNames | PCRE2 literal | PCRE2 dollarEndOnly
	           | PCRE2 noStartOptimize | PCRE2 useOffsetLimit | PCRE2 noAutoPossess | PCRE2 noDotstarAnchor | PCRE2 matchUnsetBackref
	           | PCRE2 extendedMore | PCRE2 altCircumflex | PCRE2 autoCallout | PCRE2 neverUTF | PCRE2 neverUCP
	           | PCRE2 neverBackslashC | PCRE2 firstLine | PCRE2 noUTFCheck | PCRE2 altBSUX | PCRE2 allowEmptyClass
	           | PCRE2 altExtendedClass | PCRE2 altVerbNames | PCRE2 matchInvalidUTF.
	(flags bitAnd: allowed bitInvert) ~= 0 ifTrue: [ PCRE2CompileError signal: (PCRE2 translateErrorCode: 117) in: input at: 0 ].
	literalOptions := PCRE2 anchored | PCRE2 autoCallout | PCRE2 caseless | PCRE2 endAnchored | PCRE2 firstLine | PCRE2 literal
	                  | PCRE2 matchInvalidUTF | PCRE2 noStartOptimize | PCRE2 noUTFCheck | PCRE2 useOffsetLimit | PCRE2 utf.
	((flags bitAnd: PCRE2 literal) ~= 0 and: [ (flags bitAnd: literalOptions bitInvert) ~= 0 ]) ifTrue: [
		PCRE2CompileError signal: (PCRE2 translateErrorCode: 192) in: input at: 0 ].
	parser := PCRE2PatternParser new codeUnitWidth: compiler codeUnitWidth.
	context := compiler existingContext.
	context ifNotNil: [
			(context options bitAnd: 16r1FFFF bitInvert) ~= 0 ifTrue: [
				PCRE2CompileError signal: (PCRE2 translateErrorCode: 117) in: input at: 0 ].
			((flags bitAnd: PCRE2 literal) ~= 0 and: [
					 (context options bitAnd:
						  (PCRE2 extraMatchLine | PCRE2 extraMatchWord | PCRE2 extraCaselessRestrict | PCRE2 extraTurkishCasing) bitInvert) ~= 0 ])
				ifTrue: [ PCRE2CompileError signal: (PCRE2 translateErrorCode: 192) in: input at: 0 ].
			context backend startOptimizationEnabled ifFalse: [ flags := flags bitOr: PCRE2 noStartOptimize ].
			(context options bitAnd:
				 (PCRE2 extraBadEscapeIsLiteral | PCRE2 extraAltBsux | PCRE2 extraEscapedCrIsLf | PCRE2 extraAllowSurrogateEscapes
				  | PCRE2 extraAsciiBsd | PCRE2 extraAsciiBss | PCRE2 extraAsciiBsw | PCRE2 extraAsciiPosix | PCRE2 extraAsciiDigit
				  | PCRE2 extraCaselessRestrict | PCRE2 extraMatchLine | PCRE2 extraMatchWord | PCRE2 extraPythonOctal | PCRE2 extraNoBs0
				  | PCRE2 extraNeverCallout | PCRE2 extraTurkishCasing | PCRE2 extraAllowLookaroundBsk) bitInvert) ~= 0 ifTrue: [
				PCRE2UnsupportedFeature signal: 'Unknown extra compile option bits' ].
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

{ #category : 'accessing' }
PCRE2CompilerPharoBackend >> family [

	^ #pharo
]

{ #category : 'instance creation' }
PCRE2CompilerPharoBackend >> newCompileContext [

	^ self compileContextClass new backend: (PCRE2ContextPharoBackend new codeUnitWidth: compiler codeUnitWidth)
]

{ #category : 'compiling' }
PCRE2CompilerPharoBackend >> privateJITCompile: aMatcher [

	PCRE2UnsupportedFeature signal: 'The Pharo backend does not implement PCRE2 JIT'
]
