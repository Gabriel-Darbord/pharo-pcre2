"
Tests for compiling PCRE2 patterns from Pharo strings.

The suite covers successful compilation, compile errors, and UTF-8 error reporting offsets.
"
Class {
	#name : 'PCRE2CompilerTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'asserting' }
PCRE2CompilerTest >> assertCompileErrorFrom: aBlock includes: expectedText [

	self
		should: aBlock
		raise: PCRE2CompileError
		withExceptionDo: [ :ex |
			self assert: (ex errorMessage includesSubstring: expectedText) ]
]

{ #category : 'asserting' }
PCRE2CompilerTest >> assertInvalidPattern: aString [

	| utf8 |
	utf8 := ZnUTF8Encoder default encodeString: aString.
	self
		should: [ aString asPerlCompatibleRegex ]
		raise: PCRE2CompileError
		withExceptionDo: [ :ex |
			self assert: ex errorMessage notEmpty.
			self assert: ex pattern equals: aString.
			self assert: ex offset >= 0.
			self assert: ex offset <= utf8 size.
			self assert: (ex description includesSubstring: '(*ERROR)') ]
]

{ #category : 'tests' }
PCRE2CompilerTest >> testCompileContextLimitsCompiledPatternLength [

	| compiler |
	compiler := PCRE2Compiler new.
	compiler context maxPatternCompiledLength: 1.

	self
		assertCompileErrorFrom: [ compiler compile: 'a' ]
		includes: 'compiled pattern would be longer'
]

{ #category : 'tests' }
PCRE2CompilerTest >> testCompileContextLimitsPatternLength [

	| compiler |
	compiler := PCRE2Compiler new.
	compiler context maxPatternLength: 3.

	self
		assertCompileErrorFrom: [ compiler compile: 'abcd' ]
		includes: 'pattern string is longer'
]

{ #category : 'tests' }
PCRE2CompilerTest >> testCompileContextNewlineAffectsMultilineMatching [

	| crCompiler lfCompiler crRegex lfRegex subject |
	crCompiler := PCRE2Compiler new.
	crCompiler options: (PCRE2 utf bitOr: PCRE2 multiline).
	crCompiler context useNewlineCR.
	crRegex := crCompiler compile: '^b$'.

	lfCompiler := PCRE2Compiler new.
	lfCompiler options: (PCRE2 utf bitOr: PCRE2 multiline).
	lfCompiler context useNewlineLF.
	lfRegex := lfCompiler compile: '^b$'.

	subject := 'a' , String cr , 'b'.
	self assert: (crRegex find: subject) equals: 'b'.
	self assert: (lfRegex find: subject) isNil.
	self
		assert: (crRegex info: PCRE2 infoNewline)
		equals: PCRE2 newlineCR.
	self
		assert: (lfRegex info: PCRE2 infoNewline)
		equals: PCRE2 newlineLF
]

{ #category : 'tests' }
PCRE2CompilerTest >> testCompileContextOptimizationDirectivesAndValidation [

	| context matcher |
	context := PCRE2Compiler new context.
	context
		useNoOptimization;
		disableAutoPossessification;
		disableDotstarAnchoring;
		disableStartOptimization.

	self assert: context optimizationDirectives equals: {
			PCRE2 optimizationNone.
			PCRE2 optimizeAutoPossessOff.
			PCRE2 optimizeDotstarAnchorOff.
			PCRE2 optimizeStartOff }.

	matcher := PCRE2Compiler new
		           context: context;
		           compile: 'a+'.
	self assert: (matcher matches: 'aaa').
	self
		should: [ context optimize: 999 ]
		raise: PCRE2Error
		withExceptionDo: [ :ex |
		self assert: (ex messageText includesSubstring: 'bad option') ]
]

{ #category : 'tests' }
PCRE2CompilerTest >> testCompileContextOptionsBSRAndCopy [

	| compiler context copy |
	compiler := PCRE2Compiler new.
	context := compiler context.

	context options: 0.
	context addOptions: PCRE2 extraBadEscapeIsLiteral.
	self assert:
		(context options bitAnd: PCRE2 extraBadEscapeIsLiteral) ~~ 0.
	context removeOptions: PCRE2 extraBadEscapeIsLiteral.
	self assert:
		(context options bitAnd: PCRE2 extraBadEscapeIsLiteral) = 0.

	context useBSRAnyCRLF.
	self assert: context bsr equals: PCRE2 bsrAnyCRLF.
	context useBSRUnicode.
	self assert: context bsr equals: PCRE2 bsrUnicode.

	context
		options: PCRE2 extraAltBsux;
		useNewlineCRLF;
		maxPatternLength: 64;
		maxPatternCompiledLength: 4096;
		maxVarLookbehind: 300;
		parensNestLimit: 12;
		disableStartOptimization.
	copy := context copy.
	self deny: copy identicalTo: context.
	self assert: copy options equals: context options.
	self assert: copy bsr equals: context bsr.
	self assert: copy newline equals: context newline.
	self assert: copy maxPatternLength equals: context maxPatternLength.
	self
		assert: copy maxPatternCompiledLength
		equals: context maxPatternCompiledLength.
	self assert: copy maxVarLookbehind equals: context maxVarLookbehind.
	self assert: copy parensNestLimit equals: context parensNestLimit.
	self
		assert: copy optimizationDirectives
		equals: context optimizationDirectives
]

{ #category : 'tests' }
PCRE2CompilerTest >> testCompileContextParensNestLimit [

	| compiler |
	compiler := PCRE2Compiler new.
	compiler context parensNestLimit: 1.

	self
		assertCompileErrorFrom: [ compiler compile: '((a))' ]
		includes: 'parentheses are too deeply nested'
]

{ #category : 'tests' }
PCRE2CompilerTest >> testCompileContextVariableLookbehindLimit [

	| compiler matcher |
	self
		assertCompileErrorFrom: [
		PCRE2Compiler new compile: '(?<=a{0,300})b' ]
		includes: 'lookbehind'.

	compiler := PCRE2Compiler new.
	compiler context maxVarLookbehind: 300.
	matcher := compiler compile: '(?<=a{0,300})b'.
	self assert: (matcher find: 'aaab') equals: 'b'.
	self assert: (matcher info: PCRE2 infoMaxLookbehind) equals: 300
]

{ #category : 'tests' }
PCRE2CompilerTest >> testErrorCode [
	"PCRE2 minor versions may report slightly different diagnostic offsets, so keep this test focused on binding-level error handling."

	#( '*' '(' '(??)' 'λ*φ(*)α' ) do: [ :pattern |
		self assertInvalidPattern: pattern ]
]

{ #category : 'tests' }
PCRE2CompilerTest >> testSharedDefaultCompiler [

	self assert: '' asPerlCompatibleRegex compiler identicalTo: '' asPerlCompatibleRegex compiler
]
