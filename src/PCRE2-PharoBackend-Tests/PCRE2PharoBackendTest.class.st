"
Focused conformance and ownership tests for the Pharo implementation. Upstream PCRE2 remains an external development oracle.
"
Class {
	#name : 'PCRE2PharoBackendTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-PharoBackend-Tests',
	#package : 'PCRE2-PharoBackend-Tests'
}

{ #category : 'private' }
PCRE2PharoBackendTest >> compile: pattern [

	^ PCRE2Compiler new
		  backend: PCRE2CompilerPharoBackend;
		  compile: pattern
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testAnchorsAndWordBoundaries [

	self assert: ((self compile: '\bcat\b') find: 'the cat sat') equals: 'cat'.
	self deny: ((self compile: '\bcat\b') search: 'scatter').
	self assert: ((self compile: '\Acat\z') matches: 'cat').
	self deny: ((self compile: '\Acat\z') search: 'cat!')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testAtomicGroups [

	self deny: ((self compile: '(?>a+)a') search: 'aaa').
	self assert: ((self compile: '(?:a+)a') find: 'aaa') equals: 'aaa'
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testBackreferences [

	self assert: ((self compile: '(\w+)\s+\1') find: 'hello hello') equals: 'hello hello'.
	self assert: ((self compile: '(?<word>\w+)\s+\k<word>') find: 'hello hello') equals: 'hello hello'
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testBoundedRepetition [

	self assert: ((self compile: 'a{2,4}') find: 'aaaaa') equals: 'aaaa'.
	self assert: ((self compile: 'a{2,4}?') find: 'aaaaa') equals: 'aa'.
	self deny: ((self compile: '^a{2,4}$') matches: 'a')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testCapturedResultsRemainIndependent [

	| matcher first second |
	matcher := self compile: '(?<word>\w+)'.
	first := matcher findMatch: 'one'.
	second := matcher findMatch: 'two'.
	self assert: (first groupNamed: 'word') equals: 'one'.
	self assert: (second groupNamed: 'word') equals: 'two'.
	self deny: first backend identicalTo: second backend
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testCaselessLetterProperties [

	| compiler |
	compiler := PCRE2Compiler new
		            backend: PCRE2CompilerPharoBackend;
		            addOptions: PCRE2 caseless.
	self assert: ((compiler compile: '\p{Lu}') matches: 'a').
	self assert: ((compiler compile: '\p{Ll}') matches: 'A')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testCharacterClasses [

	self assert: ((self compile: '[a-z\d]+') find: 'ABCabc123!') equals: 'abc123'.
	self assert: ((self compile: '[^a-c]+') find: 'abXYZ') equals: 'XYZ'.
	self assert: ((self compile: '[\x{41}-\x{5a}]+') find: 'aABC') equals: 'ABC'
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testCommentsDoNotBecomeQuantifiedAtoms [

	self assert: ((self compile: '^a(?#comment){3}c') matches: 'aaac').
	self deny: ((self compile: '^a(?#comment){3}c') matches: 'ac')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testCompileContextLimits [

	| compiler |
	compiler := PCRE2Compiler new backend: PCRE2CompilerPharoBackend.
	compiler context parensNestLimit: 2.
	self should: [ compiler compile: '(((a)))' ] raise: PCRE2CompileError.
	compiler context maxPatternLength: 3.
	self should: [ compiler compile: 'abcd' ] raise: PCRE2CompileError
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testCompileOptionsAreCapturedByTheCompiledPattern [

	| compiler matcher |
	compiler := PCRE2Compiler new backend: PCRE2CompilerPharoBackend.
	matcher := compiler compile: '.'.
	compiler options: PCRE2 anchored.
	self assert: (matcher find: '😀') equals: '😀'
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testCompiledObjectsCannotBeRelabelled [

	| matcher match |
	matcher := self compile: 'a'.
	match := matcher findMatch: 'a'.
	self should: [ matcher backend: matcher backend copy ] raise: PCRE2Error.
	self should: [ match backend: match backend copy ] raise: PCRE2Error.
	self assert: (matcher matches: 'a').
	self assert: match readMatch equals: 'a'
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testContextAndMatchDataWidthsAreChecked [

	| compiler matcher wrong |
	compiler := PCRE2UTF16Compiler new backend: PCRE2CompilerPharoBackend.
	matcher := self compile: 'a'.
	self should: [ matcher context: compiler context ] raise: PCRE2Error.
	wrong := (compiler compile: 'a') newMatchData.
	self
		should: [
				matcher
					matchBytes: #[ 97 ]
					from: 1
					to: 1
					into: wrong ]
		raise: PCRE2Error
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testContextCopyDoesNotShareMutableSettings [

	| context copy |
	context := (PCRE2Compiler new backend: PCRE2CompilerPharoBackend) context.
	context parensNestLimit: 20.
	copy := context copy.
	copy parensNestLimit: 10.
	self assert: context parensNestLimit equals: 20.
	self assert: copy parensNestLimit equals: 10
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testContextsKeepThePublicWidthSpecificAPI [

	| compiler matcher |
	compiler := PCRE2UTF16Compiler new backend: PCRE2CompilerPharoBackend.
	self assert: compiler context class equals: PCRE2UTF16CompileContext.
	self assert: compiler context backend class equals: PCRE2ContextPharoBackend.
	matcher := compiler compile: 'a'.
	self assert: matcher context class equals: PCRE2UTF16MatchContext.
	self assert: matcher context backend class equals: PCRE2ContextPharoBackend
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testDefaultChangesOnlyAffectNewCompilers [

	| original compiler matcher |
	original := PCRE2Compiler defaultBackend.
	compiler := PCRE2Compiler new.
	[
		PCRE2Compiler defaultBackend: PCRE2CompilerPharoBackend.
		matcher := '\d+' asPerlCompatibleRegex.
		self assert: matcher backend class equals: PCRE2MatcherPharoBackend.
		self assert: (compiler backend isKindOf: original).
		self assert: (matcher matches: '42') ] ensure: [ PCRE2Compiler defaultBackend: original ]
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testDepthAndUnsignedWorkLimits [

	| matcher |
	matcher := self compile: '(a(b(c)))'.
	matcher context depthLimit: 2.
	self should: [ matcher search: 'abc' ] raise: PCRE2MatchError.
	self should: [ matcher context matchLimit: -1 ] raise: PCRE2Error
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testEmptyMatchesTerminateAtCharacterBoundaries [

	self assert: ((self compile: 'a*') findAll: 'é') asArray equals: #( '' '' ).
	self assert: ((self compile: '(?:|a)') findAll: 'a') asArray equals: #( '' 'a' '' )
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testExtendedCharacterClassWhitespace [

	self deny: ((self compile: '<(?xx:[a b])>') search: '< >').
	self assert: ((self compile: '<(?xx:[a b])>') matches: '<a>')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testGreedyLazyAndPossessiveRepetition [

	self assert: ((self compile: 'a+') find: 'aaa') equals: 'aaa'.
	self assert: ((self compile: 'a+?') find: 'aaa') equals: 'a'.
	self deny: ((self compile: 'a++a') search: 'aaa').
	self assert: ((self compile: '(a|ab)+c') find: 'ababc') equals: 'ababc'
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testInlineOptions [

	self assert: ((self compile: '(?i:ab)c') find: 'ABc') equals: 'ABc'.
	self deny: ((self compile: '(?i:ab)c') search: 'ABC').
	self assert: ((self compile: '(?i)abc') matches: 'ABC')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testLookaheadCapturesAndRollback [

	| match |
	match := (self compile: '(?=(a+))a') findMatch: 'aaa'.
	self assert: (match groupAt: 1) equals: 'aaa'.
	self assert: ((self compile: 'a(?!b)') find: 'abac') equals: 'a'.
	self assert: ((self compile: '(a)b|a(c)') findWithGroups: 'ac') equals: #( 'ac' '' 'c' )
]

{ #category : 'matching' }
PCRE2PharoBackendTest >> testLookbehindCaptures [

	| match |
	match := (self compile: '(?<=(a{1,3}))b') findMatch: 'aaab'.
	self assert: (match groupAt: 1) equals: 'aaa'.
	self assert: match offsets equals: #( 3 4 0 3 )
]

{ #category : 'matching' }
PCRE2PharoBackendTest >> testLookbehindUsesSubjectBeforeSearchStart [

	self assert: ((self compile: '(?<=ab)c') find: 'zabc') equals: 'c'.
	self assert: ((self compile: '(?<!ab)c') find: 'abcxc') equals: 'c'.
	self assert: ((self compile: '(?<=a{1,3})b') find: 'aaab') equals: 'b'
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testMatchLimit [

	| matcher |
	matcher := self compile: '(a|aa)+b'.
	matcher context matchLimit: 100.
	self should: [ matcher search: 'aaaaaaaaaaaaaaa' ] raise: PCRE2MatchError
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testMatchingAndEnumeration [

	| matcher |
	matcher := self compile: '\d+'.
	self assert: (matcher matches: '123').
	self assert: (matcher matchesPrefix: '123abc').
	self assert: (matcher search: 'abc123').
	self assert: (matcher findAll: 'a1 b22 c333') asArray equals: #( '1' '22' '333' )
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testModernQuantifierSyntaxAndLiteralBraces [

	self assert: ((self compile: 'a{,3}B') find: 'aaaaB') equals: 'aaaB'.
	self assert: ((self compile: 'a{ 1 , 2 }') find: 'aaa') equals: 'aa'.
	self assert: ((self compile: 'X{1234') find: 'X{123456') equals: 'X{1234'
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testNamedCaptures [

	| match |
	match := (self compile: '(?<key>\w+)=(?<value>\d+)') findMatch: 'size=42'.
	self assert: (match groupNamed: 'key') equals: 'size'.
	self assert: (match groupNamed: 'value') equals: '42'.
	self assert: match offsets equals: #( 0 7 0 4 5 7 )
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testNativeMatchersDoNotEnterFFIRestoration [

	| matcher manager |
	matcher := self compile: 'a'.
	self deny: matcher backend requiresSessionRestore.
	self deny: matcher context backend requiresSessionRestore
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testOffsetLimitsUseCodeUnits [

	| compiler matcher |
	compiler := PCRE2Compiler new
		            backend: PCRE2CompilerPharoBackend;
		            addOptions: PCRE2 useOffsetLimit.
	matcher := compiler compile: 'B'.
	matcher context offsetLimit: 6.
	self assert: (matcher substituteAll: 'ABC ABC ABC' with: '!') equals: 'A!C A!C ABC'
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testOpenCaptureBackreferenceUsesPreviousIteration [

	| match |
	match := (self compile: '^(a\1?){4}$') findMatch: 'aaaaaaa'.
	self assert: match offsets equals: #( 0 7 6 7 )
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testProperties [

	self assert: ((self compile: '\p{L}+') find: '123café') equals: 'café'.
	self deny: ((self compile: '\d+') search: '٣').
	self assert: ((PCRE2Compiler new
			  backend: PCRE2CompilerPharoBackend;
			  addOptions: PCRE2 ucp;
			  compile: '\d+') search: '٣')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testQuotedQuantifierAppliesToLastCharacter [

	self assert: ((self compile: '\Qab*\E{2,}') find: 'ab***') equals: 'ab***'
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testRelativeAndOctalReferences [

	self assert: ((self compile: '(a.)\g{-1}Z') matches: 'ababZ').
	self assert: ((self compile: '\123') matches: 'S').
	self should: [ self compile: '(a)\g{2}' ] raise: PCRE2CompileError
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testSingleExtendedOptionDoesNotEnableExtendedCharacterClasses [

	| compiler matcher |
	compiler := PCRE2Compiler new
		            backend: PCRE2CompilerPharoBackend;
		            addOptions: PCRE2 extended.
	matcher := compiler compile: '<(?x:[a b])>'.
	self assert: (matcher matches: '< >')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testSubroutineRestoresCallerCaptures [

	| match |
	match := (self compile: '(a(b)|(c))(?1)') findMatch: 'abc'.
	self assert: match offsets equals: #( 0 3 0 2 1 2 ).
	match := (self compile: '^((.)(?1)\2|.)$') findMatch: 'abcdcba'.
	self assert: match offsets equals: #( 0 7 0 7 0 1 )
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testSubstitutionAndLiteralReplacement [

	| matcher |
	matcher := self compile: '(?<word>\w+)'.
	self assert: (matcher substituteAll: 'one two' with: '<${word}>') equals: '<one> <two>'.
	self assert: (matcher substitute: 'one two' with: '$$-$0-$<word>') equals: '$-one-one two'.
	self assert: (matcher substituteAll: 'one two' withLiteral: '$0') equals: '$0 $0'
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testSubstitutionEmptyMatchesAndUnicode [

	self assert: ((self compile: 'a*') substituteAll: 'é' with: '-') equals: '-é-'.
	self assert: ((self compile: 'é') substituteAll: 'café café' with: 'e') equals: 'cafe cafe'.
	self assert: ((self compile: '\d+') substituteAllReplacementsOnly: 'a1 b22' with: '<$0>') equals: '<1><22>'
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testSubstitutionUnsetAndUnknownCaptures [

	| matcher |
	matcher := self compile: '(a)?b'.
	self should: [ matcher substitute: 'b' with: '$1' ] raise: PCRE2MatchError.
	self assert: (matcher substitute: 'b' withUnsetCapturesEmpty: '$1!') equals: '!'.
	self should: [ matcher substitute: 'b' with: '$missing' ] raise: PCRE2MatchError.
	self assert: (matcher substitute: 'b' withUnknownCapturesEmpty: '$missing!') equals: '!'
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testSyntaxErrors [

	self should: [ self compile: '(' ] raise: PCRE2CompileError.
	self should: [ self compile: '[z-a]' ] raise: PCRE2CompileError.
	self should: [ self compile: 'a{4,2}' ] raise: PCRE2CompileError
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testUnicodeRangesForAllWidths [

	{
		PCRE2UTF8Compiler.
		PCRE2UTF16Compiler.
		PCRE2UTF32Compiler } with: #( 2 1 1 ) do: [ :class :start |
			| matcher match |
			matcher := class new
				           backend: PCRE2CompilerPharoBackend;
				           compile: '😀'.
			match := matcher findMatch: 'é😀'.
			self assert: (match offsetsAt: 1) first equals: start.
			self assert: (matcher matchingRangesIn: 'é😀') asArray equals: { (2 to: 2) } ]
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testUnicodeWordIncludesCombiningMarksAndNumbers [

	| compiler matcher |
	compiler := PCRE2Compiler new
		            backend: PCRE2CompilerPharoBackend;
		            addOptions: PCRE2 ucp.
	matcher := compiler compile: '\w+'.
	self assert: (matcher matches: 'e' , (Character value: 16r301) asString).
	self assert: (matcher matches: (Character value: 16r2167) asString).
	self assert: ((self compile: '\p{N}') matches: (Character value: 16rB2) asString).
	self deny: ((self compile: '\p{Z}') matches: Character tab asString)
]

{ #category : 'matching' }
PCRE2PharoBackendTest >> testUnsupportedFeaturesAreExplicit [

	self should: [ self compile: '(?C1)a' ] raise: PCRE2UnsupportedFeature.
	self should: [ (self compile: 'a') dfaMatches: 'a' ] raise: PCRE2UnsupportedFeature.
	self should: [ (self compile: 'a') compileJIT ] raise: PCRE2UnsupportedFeature
]
