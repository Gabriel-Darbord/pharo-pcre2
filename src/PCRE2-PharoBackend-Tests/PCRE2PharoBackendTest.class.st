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
PCRE2PharoBackendTest >> assertCompiling: pattern options: compileOptions signals: errorCode at: offset [

	[
		self compile: pattern options: compileOptions.
		self fail ]
		on: PCRE2CompileError
		do: [ :error |
				self assert: error errorMessage equals: (PCRE2 translateErrorCode: errorCode).
				self assert: error offset equals: offset ]
]

{ #category : 'private' }
PCRE2PharoBackendTest >> compile: pattern [

	^ PCRE2Compiler new
		  backend: PCRE2CompilerPharoBackend;
		  compile: pattern
]

{ #category : 'private' }
PCRE2PharoBackendTest >> compile: pattern options: compileOptions [

	^ PCRE2Compiler new
		  backend: PCRE2CompilerPharoBackend;
		  options: compileOptions;
		  compile: pattern
]

{ #category : 'private' }
PCRE2PharoBackendTest >> matchInvalidUTF: pattern in: bytes [
	"The offsets of the first match over possibly malformed subject bytes, or nil."

	| matcher data rc |
	matcher := self compile: pattern options: PCRE2 matchInvalidUTF.
	data := matcher newMatchData.
	rc := matcher
		      matchBytes: bytes
		      from: 1
		      to: bytes size
		      into: data.
	^ rc > 0 ifTrue: [ (data offsets first: rc * 2) asArray ]
]

{ #category : 'private' }
PCRE2PharoBackendTest >> partialMatch: pattern in: bytes options: matchOptions [
	"The result code and the first two offsets of one match attempt under partial matching."

	^ self
		  partialMatch: pattern
		  in: bytes
		  options: matchOptions
		  compiled: 0
]

{ #category : 'private' }
PCRE2PharoBackendTest >> partialMatch: pattern in: bytes options: matchOptions compiled: compileOptions [
	"The result code and the first two offsets of one match attempt under partial matching, or no offsets when there was no match at all."

	| matcher data rc |
	matcher := self compile: pattern options: compileOptions.
	data := matcher newMatchData.
	rc := matcher
		      matchBytes: bytes
		      from: 1
		      to: bytes size
		      options: matchOptions
		      into: data.
	^ {
		  rc.
		  (data offsets size >= 2
			   ifTrue: [ (data offsets first: 2) asArray ]
			   ifFalse: [ #(  ) ]) }
]

{ #category : 'private' }
PCRE2PharoBackendTest >> startPositionsOf: pattern in: subject [
	"Where a match was attempted, as a callout at the head of the pattern saw it."

	| matcher starts |
	starts := OrderedCollection new.
	matcher := self compile: pattern.
	matcher context calloutBlock: [ :event |
			starts add: event startMatch.
			0 ].
	matcher matches: subject.
	^ starts asArray
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testAcceptClosesCapturesAndReturnsFromSubroutines [

	| match |
	match := (self compile: '(a(*ACCEPT)b)c') findMatch: 'a'.
	self assert: (match groupAt: 1) equals: 'a'.
	self assert: ((self compile: '(?(DEFINE)(?<x>a(*ACCEPT)b))(?&x)c') matches: 'ac')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testAlternativeVerbNamesAndAcceptanceConstraints [

	| compiler matcher |
	compiler := PCRE2UTF8Compiler new
		            backend: PCRE2CompilerPharoBackend;
		            options: PCRE2 utf | PCRE2 altVerbNames.
	matcher := compiler compile: '(*MARK:A\Q)x\EB)x'.
	self assert: (matcher findMatch: 'x') mark equals: 'A)xB'.
	self should: [ compiler compile: '(*MARK:a\zb)x' ] raise: PCRE2CompileError.
	compiler options: PCRE2 utf.
	matcher := compiler compile: 'a*(*ACCEPT)b'.
	matcher options: PCRE2 notEmptyAtStart.
	self assert: (matcher findMatch: 'bbb') offsets equals: #( 1 1 ).
	compiler addOptions: PCRE2 extended.
	matcher := compiler compile: '^ (?(DEFINE) (..(*ACCEPT)|...) ) (?1)$'.
	self deny: (matcher matches: 'abc').
	self assert: ((compiler compile: 'a(*ACCEPT)??bc') matches: 'abc')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testAnchoredStartOptimizationStillAppliesUnderPartialMatching [
	"PCRE2 checks the first code unit at the one anchored start whether or not partial matching is on, so a subject with no room for it answers no match at all."

	self
		assert: (self
				 partialMatch: '\bWORD\b'
				 in: #[  ]
				 options: PCRE2 partialSoft
				 compiled: PCRE2 anchored)
		equals: {
				PCRE2 errorNoMatch.
				#(  ) }.
	self assert: (self partialMatch: '\bWORD\b' in: #[  ] options: PCRE2 partialSoft) equals: {
			PCRE2 errorPartial.
			#( 0 0 ) }
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
PCRE2PharoBackendTest >> testAutomaticCallouts [

	| compiler matcher events |
	compiler := PCRE2Compiler new
		            backend: PCRE2CompilerPharoBackend;
		            addOptions: PCRE2 autoCallout.
	matcher := compiler compile: 'ab'.
	events := OrderedCollection new.
	self assert: (matcher calloutSites collect: #patternPosition) equals: #( 0 1 2 ).
	self assert: (matcher matches: 'ab' calloutsDo: [ :event |
				 events add: event.
				 0 ]).
	self assert: events size equals: 3
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testBackreferences [

	self assert: ((self compile: '(\w+)\s+\1') find: 'hello hello') equals: 'hello hello'.
	self assert: ((self compile: '(?<word>\w+)\s+\k<word>') find: 'hello hello') equals: 'hello hello'
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testBacktrackingVerbScopes [

	self deny: ((self compile: 'a+(*COMMIT)b') search: 'aacaab').
	self assert: ((self compile: 'a(*PRUNE)b|ac') find: 'acab') equals: 'ab'.
	self assert: ((self compile: 'a(*THEN)b|ac') find: 'ac') equals: 'ac'.
	self assert: ((self compile: '(?>a(*COMMIT))b|ac') find: 'ac') equals: 'ac'.
	self deny: ((self compile: 'a(?=b(*COMMIT)c)[^d]|abd') search: 'abd').
	self deny: ((self compile: '(?x)^.*? (?>a(*THEN)b) c') search: 'aabc')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testBoundedRepetition [

	self assert: ((self compile: 'a{2,4}') find: 'aaaaa') equals: 'aaaa'.
	self assert: ((self compile: 'a{2,4}?') find: 'aaaaa') equals: 'aa'.
	self deny: ((self compile: '^a{2,4}$') matches: 'a')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testBranchResetNumberingAndNames [

	| match |
	match := (self compile: '(?|(?<x>a)|(b)(c))(d)') findMatch: 'bcd'.
	self assert: (match groupAt: 1) equals: 'b'.
	self assert: (match groupAt: 2) equals: 'c'.
	self assert: (match groupAt: 3) equals: 'd'.
	self assert: ((self compile: '(?|(?<x>a)|(?<x>b))\k<x>') matches: 'bb').
	self should: [ self compile: '(?|(?<x>a)|(?<y>b))' ] raise: PCRE2CompileError
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testCalloutCaptureMetadataAfterAssertionsAndSubroutines [

	| events matcher |
	events := OrderedCollection new.
	matcher := self compile: '(a)(b)(?1)(?C1)'.
	self assert: (matcher matches: 'aba' calloutsDo: [ :event |
				 events add: event.
				 0 ]).
	self assert: events first captureLast equals: 2.
	self assert: (events first offsets first: 2) equals: {
			PCRE2 unsetOffset.
			PCRE2 unsetOffset }.
	events removeAll.
	matcher := self compile: '(?=(a))(?C1)a'.
	self assert: (matcher matches: 'a' calloutsDo: [ :event |
				 events add: event.
				 0 ]).
	self assert: events first captureLast equals: 1
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testCalloutMetadataCallbacksAndBacktracking [

	| matcher events |
	matcher := self compile: '(?C1)(a(?C2)b|a(?C3)c)'.
	events := OrderedCollection new.
	self assert: (matcher matches: 'ac' calloutsDo: [ :event |
				 events add: event.
				 0 ]).
	self assert: (events collect: #number as: Array) equals: #( 1 2 3 ).
	self assert: events first isStartMatch.
	self assert: events last isBacktrack.
	self should: [ matcher matches: 'ac' calloutsDo: [ :event | PCRE2 errorCallout ] ] raise: PCRE2MatchError.
	self assert: (matcher matches: 'ac')
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
PCRE2PharoBackendTest >> testCharacterClassesAgreeAboveAndBelowTheirTable [
	"A class answers from a table for the codes that fit in one byte and from its predicate above them, so the two have to agree about every character, including the one on each side of the join."

	| join high |
	join := String with: (Character value: 16rFF) with: (Character value: 16r100).
	high := String with: (Character value: 16rC9).
	self assert: ((self compile: '[\x{ff}\x{100}]+' options: PCRE2 utf) find: join , 'b') equals: join.
	self
		assert: ((self compile: '[^\x{100}]+' options: PCRE2 utf) find: (String with: (Character value: 16r100)) , 'ab')
		equals: 'ab'.
	self assert: ((self compile: '[^a-z]+' options: PCRE2 utf) find: 'abc' , high) equals: high.
	self assert: ((self compile: '[a-z]+' options: PCRE2 caseless) find: 'XYZ') equals: 'XYZ'
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testCodeUnitEscapeAndFullRaw32BitValues [

	| compiler matcher match bytes |
	compiler := PCRE2UTF8Compiler new backend: PCRE2CompilerPharoBackend.
	match := (compiler compile: '\C\C') findMatch: 'é'.
	self assert: match offsets equals: #( 0 2 ).
	match := (compiler compile: '(\C)(\C)') findMatch: 'é'.
	self assert: match offsets equals: #( 0 2 0 1 1 2 ).
	self should: [ compiler compile: '(?<=\C)a' ] raise: PCRE2CompileError.
	compiler := PCRE2UTF32Compiler new
		            backend: PCRE2CompilerPharoBackend;
		            options: 0.
	bytes := ByteArray new: 4.
	bytes uint32AtOffset: 0 put: 16rFFFFFFFF.
	match := (compiler compile: '\x{FFFFFFFF}') matchBytes: bytes from: 1 to: 1.
	self assert: match offsets equals: #( 0 1 )
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testCommentsDoNotBecomeQuantifiedAtoms [

	self assert: ((self compile: '^a(?#comment){3}c') matches: 'aaac').
	self deny: ((self compile: '^a(?#comment){3}c') matches: 'ac')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testCommitStartOptimization [

	| compiler |
	self assert: ((self compile: '(*COMMIT)ABC') find: 'DEFABC') equals: 'ABC'.
	self deny: ((self compile: '(*COMMIT)(A|P)(B|P)(C|P)') search: 'DEFABC').
	compiler := PCRE2Compiler new
		            backend: PCRE2CompilerPharoBackend;
		            addOptions: PCRE2 noStartOptimize.
	self deny: ((compiler compile: '(*COMMIT)ABC') search: 'DEFABC')
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
PCRE2PharoBackendTest >> testCompileDiagnosticLocations [

	#( #( '(?<2>a)' 144 4 ) #( '(?<bad-name>a)' 142 6 ) #( '\k<missing>' 115 3 ) #( '(?(+10))' 115 4 ) #( 'x(?<=a+)' 125 1 )
	   #( 'a{4,2}' 104 5 ) #( 'a{65536}' 105 7 ) #( '(?(VERSION<10)a|b)' 179 11 ) ) do: [ :example |
			[
				self compile: example first.
				self fail ]
				on: PCRE2CompileError
				do: [ :error |
						self assert: error errorMessage equals: (PCRE2 translateErrorCode: example second).
						self assert: error offset equals: example third ] ].
	{
		(PCRE2UTF8Compiler -> 4).
		(PCRE2UTF16Compiler -> 2).
		(PCRE2UTF32Compiler -> 1) } do: [ :example |
			[
				example key new
					backend: PCRE2CompilerPharoBackend;
					options: PCRE2 utf;
					compile: '😀(?<=a+)'.
				self fail ]
				on: PCRE2CompileError
				do: [ :error | self assert: error offset equals: example value ] ]
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testCompileDiagnosticsUsePCRE2Messages [
	"A rejected pattern reports the message and offset PCRE2 gives it, not a message of our own."

	#( #( '[abcd' 106 5 ) #( 'a[]b' 106 4 ) #( '(abc' 114 4 ) #( '(?i' 114 3 ) #( '(?# abc' 118 7 ) #( '[:x:]' 112 5 )
	   #( '[.x.]' 113 5 ) #( '[[.ch.]]' 113 7 ) #( '[a-[.xxx.]]+' 150 10 ) #( '[A-\BP-\RV-\X]' 107 5 ) #( '[\K]' 107 3 )
	   #( '(?+-a)' 129 4 ) #( '(?P''abc''x)(?P<xyz>y)' 141 4 ) #( '(?P<x>eks)(?P<x>eccs)' 143 16 )
	   #( '(?|(?<a>A)|(?<b>B))' 165 16 ) #( '(?R-:(?<)' 158 3 ) #( '(*XYZ)' 160 5 ) #( '(*LIMIT_MATCH=)abc' 160 14 )
	   #( '^A\x{' 178 5 ) #( 'a\800000b' 161 8 ) #( '(a(?<=b(?1)))' 125 2 ) #( '(?<!a{65535}a{5})x' 187 0 )
	   #( '12345(?<=\d{1,256})X' 200 5 ) #( '(?(DEFINE)a|b)' 154 3 ) #( '\p{Any' 146 6 ) #( '\p{Foo}' 147 7 ) #( '(?[( ' 106 5 )
	   #( '(?[(' 114 4 ) ) do: [ :example |
			self
				assertCompiling: example first
				options: 0
				signals: example second
				at: example third ].
	#( #( '[a[B]' 212 5 ) #( '[a--[a]' 212 7 ) #( '[a--[a]--' 212 9 ) #( '[a[]' 106 4 ) #( '[a--[a' 106 6 ) #( '[a[b]c[d' 106 8 )
	   #( '[a[:alpha:]' 106 11 ) ) do: [ :example |
			self
				assertCompiling: example first
				options: PCRE2 altExtendedClass
				signals: example second
				at: example third ].
	self
		assertCompiling: '(*MARK:a\zb)z'
		options: PCRE2 altVerbNames
		signals: 140
		at: 10
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
PCRE2PharoBackendTest >> testConditionalCalloutPrefixesAndEmptyQuotes [

	| matcher count |
	count := 0.
	matcher := self compile: '(?(?C1)(?=a)aa|bb)'.
	matcher context calloutBlock: [ :event |
			count := count + 1.
			0 ].
	self assert: (matcher matches: 'aa').
	self assert: (matcher matches: 'bb').
	self assert: count equals: 2.
	self assert: ((self compile: '()\Q\E*]') matches: ']')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testConditionalCapturesAndAssertions [

	self assert: ((self compile: '^(a)?(?(1)b|c)$') matches: 'ab').
	self assert: ((self compile: '^(a)?(?(1)b|c)$') matches: 'c').
	self deny: ((self compile: '^(a)?(?(1)b|c)$') matches: 'ac').
	self assert: ((self compile: '^(?(?=(a))\1b|c)$') matches: 'ab').
	self assert: ((self compile: '(?(?<=a)b|c)') find: 'ab') equals: 'b'
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testConditionalDefinitionsAndRecursion [

	self assert: ((self compile: '(?(DEFINE)(?<word>[a-z]+))^(?&word)$') matches: 'abc').
	self assert: ((self compile: '^(?<pair>a(?(R&pair)b|c)(?&pair)?d)$') matches: 'acabdd').
	self should: [ self compile: '(?(8)a|b)' ] raise: PCRE2CompileError
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
PCRE2PharoBackendTest >> testControlOctalAndAlternativeUnicodeEscapes [

	| compiler |
	self assert:
		((self compile: '\cA\c?\o{ 101 }') matches: (String with: (Character value: 1) with: (Character value: 127) with: $A)).
	compiler := PCRE2UTF8Compiler new
		            backend: PCRE2CompilerPharoBackend;
		            options: PCRE2 utf | PCRE2 altBSUX.
	self assert: ((compiler compile: '\u0061\x62\U') matches: 'abU').
	self assert: ((compiler compile: '\u{61}') matches: ('u' repeat: 61)).
	self assert: ((compiler compile: '\x{2}') matches: 'xx').
	self assert: ((compiler compile: '\x1') matches: 'x1').
	compiler options: PCRE2 utf.
	compiler context options: PCRE2 extraEscapedCrIsLf.
	self assert: ((compiler compile: '\r') matches: String lf).
	compiler context options: PCRE2 extraAllowSurrogateEscapes.
	self deny: ((compiler compile: '\x{D800}') matches: 'a')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testDFAAlternativesAndPossession [

	| compiler matcher |
	compiler := PCRE2Compiler new
		            backend: PCRE2CompilerPharoBackend;
		            addOptions: PCRE2 noAutoPossess.
	matcher := compiler compile: 'a+'.
	self assert: (matcher dfaMatches: 'aaa') equals: #( 'aaa' 'aa' 'a' ).
	self assert: ((self compile: 'a+') dfaMatches: 'aaa') equals: #( 'aaa' ).
	self assert: ((self compile: '(?>a|ab)c') dfaMatches: 'abc') equals: #( 'abc' ).
	self assert: ((self compile: 'cat(er(pillar)?)?') dfaMatches: 'caterpillar') equals: #( 'caterpillar' 'cater' 'cat' ).
	self should: [ (self compile: '(a)\1') dfaMatches: 'aa' ] raise: PCRE2MatchError
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testDFARestartRetainsOnlyThePartialAttempt [

	| matcher workspace data rc |
	matcher := self compile: '^\d?\d(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\d\d$'.
	workspace := ByteArray new: 400.
	data := matcher newMatchData.
	matcher options: PCRE2 partialSoft.
	rc := matcher
		      dfaMatch: '23ja'
		      from: 0
		      to: 4
		      matchData: data
		      workspace: workspace
		      size: 100.
	self assert: rc equals: PCRE2 errorPartial.
	matcher options: PCRE2 dfaRestart.
	rc := matcher
		      dfaMatch: 'n05'
		      from: 0
		      to: 3
		      matchData: data
		      workspace: workspace
		      size: 100.
	self assert: rc equals: 1.
	self assert: (data offsets first: 2) equals: #( 0 3 ).
	self
		should: [
				matcher
					dfaMatch: 'n05'
					from: 0
					to: 3
					matchData: data
					workspace: (ByteArray new: 400)
					size: 100 ]
		raise: PCRE2MatchError
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testDFASoftPartialKeepsTheFirstCandidate [

	| matcher match |
	matcher := self compile: 'abc|b'.
	matcher options: PCRE2 partialSoft.
	match := matcher dfaMatch: 'ab'.
	self assert: match resultCode equals: PCRE2 errorPartial.
	self assert: match offsets equals: #( 0 2 )
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testDefaultChangesOnlyAffectNewCompilers [

	| original compiler |
	original := PCRE2Compiler defaultBackend.
	compiler := PCRE2Compiler new.
	PCRE2Compiler withDefaultBackend: PCRE2CompilerPharoBackend do: [
			| matcher |
			matcher := '\d+' asPerlCompatibleRegex.
			self assert: matcher backend class equals: PCRE2MatcherPharoBackend.
			self assert: (compiler backend isKindOf: original).
			self assert: (matcher matches: '42') ]
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
PCRE2PharoBackendTest >> testEmptyClassesAndLineOptionPrecedence [

	| compiler |
	compiler := PCRE2UTF8Compiler new
		            backend: PCRE2CompilerPharoBackend;
		            options: PCRE2 utf | PCRE2 allowEmptyClass.
	self deny: ((compiler compile: '[]') search: 'a').
	self assert: ((compiler compile: '[^]') matches: 'a').
	compiler context options: PCRE2 extraMatchLine | PCRE2 extraMatchWord.
	self assert: ((compiler compile: '!') matches: '!')
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
PCRE2PharoBackendTest >> testExtendedClassSetOperations [

	self assert: ((self compile: '(?[\d - [2]])+') find: '123') equals: '1'.
	self assert: ((self compile: '(?[[AC] ^ [BC]])+') find: 'BABC') equals: 'BAB'.
	self assert: ((self compile: '(?[\d + \n & [\n\t]])+') find: '1' , Character lf asString) equals: '1' , Character lf asString.
	self assert: ((self compile: '(?[ ( [ ^ z ] ) ])') search: 'j').
	self deny: ((self compile: '(?[ ( [ ^ z ] ) ])') search: 'z')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testExtendedSubstitutionsAndCallbacks [

	| matcher events result |
	matcher := self compile: '(a)?b'.
	self
		assert: (matcher substitute: 'b ab' with: '${1:-x}' options: PCRE2 substituteExtended | PCRE2 substituteGlobal)
		equals: 'x a'.
	self
		assert: (matcher substitute: 'b ab' with: '${1:+\U:\L}HeLLo' options: PCRE2 substituteExtended | PCRE2 substituteGlobal)
		equals: 'hello HELLO'.
	matcher := self compile: '(\w+)'.
	self
		assert: (matcher substitute: 'heLLo WORLD' with: '\u\L$0' options: PCRE2 substituteExtended | PCRE2 substituteGlobal)
		equals: 'Hello World'.
	events := OrderedCollection new.
	result := matcher substituteAll: 'one two' with: '[$0]' calloutsDo: [ :event |
			          events add: event.
			          event substitutionCount = 1
				          ifTrue: [ PCRE2 substituteCalloutRejectAndContinue ]
				          ifFalse: [ PCRE2 substituteCalloutAccept ] ].
	self assert: result equals: 'one [two]'.
	self assert: events size equals: 2.
	self
		assert: (matcher
				 substitute: 'one'
				 with: '\U$0'
				 options: PCRE2 substituteExtended | PCRE2 substituteGlobal
				 caseCallout: [ :event | event inputText reversed ])
		equals: 'eno'
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testExtendedWhitespaceAndScopedSingleX [

	| compiler |
	compiler := PCRE2UTF8Compiler new
		            backend: PCRE2CompilerPharoBackend;
		            options: PCRE2 utf | PCRE2 extended | PCRE2 extendedMore.
	self assert: ((compiler compile: 'a' , (String with: (Character value: 11)) , 'b') matches: 'ab').
	self assert: ((compiler compile: '<(?x:[a b])>') matches: '< >').
	self deny: ((compiler compile: 'A(*MARK:A)A+(*SKIP:)(B|Z) | AC') search: 'AAAC')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testExtraEscapeOptionsAndOptimizationDirectives [

	| compiler |
	compiler := PCRE2Compiler new backend: PCRE2CompilerPharoBackend.
	compiler context addOptions: PCRE2 extraBadEscapeIsLiteral.
	self assert: ((compiler compile: '\y') matches: 'y').
	compiler context options: PCRE2 extraAltBsux.
	self assert: ((compiler compile: '\u{1234}') matches: (Character value: 16r1234) asString).
	compiler context
		useNoOptimization;
		disableStartOptimization.
	self deny: ((compiler compile: '(*COMMIT)abc') search: 'xyzabc')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testFailedConditionalAssertionRetainsCaptures [

	| match |
	match := (self compile: '^(?(?!(a))def|abc)') findMatch: 'abc'.
	self assert: (match groupAt: 1) equals: 'a'.
	self assert: ((self compile: '(?(*pla:foo).{6}|a..)') find: 'foobar') equals: 'foobar'
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testGreedyLazyAndPossessiveRepetition [

	self assert: ((self compile: 'a+') find: 'aaa') equals: 'aaa'.
	self assert: ((self compile: 'a+?') find: 'aaa') equals: 'a'.
	self deny: ((self compile: 'a++a') search: 'aaa').
	self assert: ((self compile: '(a|ab)+c') find: 'ababc') equals: 'ababc'
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testGreedyRunsOfOneCharacterAreCountedThenGivenBack [
	"A greedy repetition of a single character is counted off in one step and then given back a character at a time, which has to leave exactly the match that taking them one at a time would."

	| match |
	match := (self compile: '(a+)(a+)') findMatch: 'aaaa'.
	self assert: (match groupAt: 1) equals: 'aaa'.
	self assert: (match groupAt: 2) equals: 'a'.
	self assert: ((self compile: 'a{2,4}b') find: 'aaaaab') equals: 'aaaab'.
	self deny: ((self compile: 'a{2,4}b') search: 'ab').
	self assert: ((self compile: '(.*)b') find: 'abcb') equals: 'abcb'.
	self assert: ((self compile: 'a+?b') find: 'aaab') equals: 'aaab'.
	"Giving a character back steps over a whole character, not one code unit of it."
	match := (self compile: '(é+)é' options: PCRE2 utf) findMatch: 'ééé'.
	self assert: (match groupAt: 1) equals: 'éé'.
	"And a run that stops because the subject does still says so."
	self assert: (self partialMatch: 'a+b' in: #[ 97 97 97 ] options: PCRE2 partialSoft) equals: {
			PCRE2 errorPartial.
			#( 0 3 ) }
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testHeapBudgetAndMatchStorageDiagnostics [

	| matcher match size |
	matcher := self compile: 'a+'.
	matcher context heapLimit: 0.
	self should: [ matcher matches: 'aa' ] raise: PCRE2MatchError.
	matcher context heapLimit: 100.
	match := matcher findMatch: 'aa'.
	size := match matchDataSize.
	self assert: size > 0.
	match prepareForShutdown.
	self assert: match matchDataSize equals: size.
	self assert: match heapframesSize equals: 0
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testInlineOptionReset [

	self assert: ((self compile: '(?i)A(?^)B(?^x:C D)(?^i)e f') matches: 'aBCDe f').
	self deny: ((self compile: '(?i)A(?^)B') matches: 'ab')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testInlineOptions [

	self assert: ((self compile: '(?i:ab)c') find: 'ABc') equals: 'ABc'.
	self deny: ((self compile: '(?i:ab)c') search: 'ABC').
	self assert: ((self compile: '(?i)abc') matches: 'ABC')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testInvalidUTFImpliesUTFAndIsRefusedByDFAMatching [
	"PCRE2_MATCH_INVALID_UTF forces UTF mode, and only the ordinary matching function honours it."

	| matcher data |
	matcher := self compile: '.' options: PCRE2 matchInvalidUTF.
	data := matcher newMatchData.
	self
		assert: (matcher
				 matchBytes: #[ 195 169 ]
				 from: 1
				 to: 2
				 into: data)
		equals: 1.
	self assert: (data offsets first: 2) equals: #( 0 2 ).
	self
		assert: (matcher
				 dfaMatch: #[ 195 169 ]
				 from: 0
				 to: 2
				 matchData: data
				 workspace: (ByteArray new: 400)
				 size: 100)
		equals: PCRE2 errorDFAInvalidUTF
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testInvalidUTFStartOffsetMovesToTheNextCharacter [
	"A start offset inside an invalid sequence is skipped, rather than reported as a bad offset."

	| matcher data |
	matcher := self compile: 'a' options: PCRE2 matchInvalidUTF.
	data := matcher newMatchData.
	1 to: 3 do: [ :start |
			self
				assert: (matcher
						 matchBytes: #[ 128 128 97 ]
						 from: start
						 to: 3
						 into: data)
				equals: 1.
			self assert: (data offsets first: 2) equals: #( 2 3 ) ]
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testInvalidUTFSubjectWithoutTheOptionIsAMatchError [
	"Without PCRE2_MATCH_INVALID_UTF a malformed subject is still reported as the UTF error it is."

	| matcher data |
	matcher := self compile: 'b' options: PCRE2 utf.
	data := matcher newMatchData.
	self
		should: [
				matcher
					matchBytes: #[ 97 255 98 ]
					from: 1
					to: 3
					into: data ]
		raise: PCRE2MatchError
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testInvalidUTFSubjectsAreMatchedFragmentByFragment [
	"An invalid sequence matches nothing at all, not even a negated class, and no match crosses it."

	| word |
	self assert: (self matchInvalidUTF: 'b' in: #[ 97 255 98 ]) equals: #( 2 3 ).
	self assert: (self matchInvalidUTF: '.' in: #[ 97 255 98 ]) equals: #( 0 1 ).
	self assert: (self matchInvalidUTF: '[^x]+' in: #[ 97 255 98 ]) equals: #( 0 1 ).
	self assert: (self matchInvalidUTF: '\p{Any}+' in: #[ 97 255 98 ]) equals: #( 0 1 ).
	self assert: (self matchInvalidUTF: 'a.b' in: #[ 97 255 98 ]) isNil.
	self assert: (self matchInvalidUTF: '(?<=a)b' in: #[ 97 255 98 ]) isNil.
	self assert: (self matchInvalidUTF: '(?<!a)b' in: #[ 97 255 98 ]) equals: #( 2 3 ).
	word := #[ 87 79 82 68 255 87 79 82 68 ].
	self assert: (self matchInvalidUTF: '\bWORD\b' in: word) equals: #( 0 4 ).
	self assert: (self matchInvalidUTF: '^WORD' in: word) equals: #( 0 4 ).
	self assert: (self matchInvalidUTF: 'WORD\z' in: word) equals: #( 5 9 ).
	self assert: (self matchInvalidUTF: '^WORD$' in: word) isNil
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testLookaheadCapturesAndRollback [

	| match |
	match := (self compile: '(?=(a+))a') findMatch: 'aaa'.
	self assert: (match groupAt: 1) equals: 'aaa'.
	self assert: ((self compile: 'a(?!b)') find: 'abac') equals: 'a'.
	self assert: ((self compile: '(a)b|a(c)') findWithGroups: 'ac') equals: #( 'ac' '' 'c' )
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testLookbehindAndExtendedClassValidation [

	| compiler |
	#( '(?<=a{65535}a)b' '(a(?<=b(?1)))' '(?|([ab]))(?<=\1)' '(?=a\Kb)' '^\g{0}' ) do: [ :pattern |
		self should: [ self compile: pattern ] raise: PCRE2CompileError ].
	compiler := PCRE2UTF8Compiler new
		            backend: PCRE2CompilerPharoBackend;
		            options: PCRE2 utf | PCRE2 altExtendedClass.
	self should: [ compiler compile: ('[' repeat: 16) , 'a' , (']' repeat: 16) ] raise: PCRE2CompileError.
	self should: [ compiler compile: '[\d-z]' ] raise: PCRE2CompileError.
	self should: [ compiler compile: '[\Q' ] raise: PCRE2CompileError.
	compiler options: PCRE2 utf | PCRE2 literal | PCRE2 extended.
	self should: [ compiler compile: 'a' ] raise: PCRE2CompileError
]

{ #category : 'matching' }
PCRE2PharoBackendTest >> testLookbehindCaptures [

	| match |
	match := (self compile: '(?<=(a{1,3}))b') findMatch: 'aaab'.
	self assert: (match groupAt: 1) equals: 'aaa'.
	self assert: match offsets equals: #( 3 4 0 3 )
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testLookbehindSubroutinesAndDefinitions [

	self assert: ((self compile: '(a)(?<=b(?1))') find: 'ba') equals: 'a'.
	self assert: ((self compile: '(?<=b(?1))(a)') find: 'baa') equals: 'a'.
	self assert: ((self compile: '(?<=X(?(DEFINE)(.*))Y).') find: 'XYZ') equals: 'Z'.
	self assert: ((self compile: '(?<=a(*ACCEPT)b)c') find: 'xacd') equals: 'c'.
	self should: [ self compile: '(?<=a*)b' ] raise: PCRE2CompileError
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
	matcher := self compile: '(*NO_START_OPT)(a|aa)+b'.
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
PCRE2PharoBackendTest >> testNamedRecursionConditionsPreferCaptures [

	#( '(?<R>a)(?(R)b|c)' '(?<R0>a)(?(R0)b|c)' '(?<R12>a)(?(R12)b|c)' '(?<DEFINE>a)(?(''DEFINE'')b|c)' ) do: [ :pattern |
			self assert: ((self compile: pattern) matches: 'ab').
			self deny: ((self compile: pattern) matches: 'ac') ].
	self assert: ((self compile: '(?(R12)b|c)(?<R12>a)') matches: 'ca').
	self assert: ((self compile: '^(b(?1)?(?(R0)c|d))$') matches: 'bbcd')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testNamedSkipAndAtomicMarks [

	self assert: ((self compile: 'a(*MARK:X)(*SKIP:X)(*F)|(.)') find: 'abc') equals: 'b'.
	self assert: ((self compile: 'a(?>(*MARK:X))(*SKIP:X)(*F)|(.)') find: 'abc') equals: 'a'.
	self assert: ((self compile: 'a(*MARK:X)') findMatch: 'a') mark equals: 'X'
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testNewlineConventionsAndBSR [

	| compiler matcher |
	compiler := PCRE2Compiler new
		            backend: PCRE2CompilerPharoBackend;
		            addOptions: PCRE2 multiline.
	compiler context useNewlineCR.
	matcher := compiler compile: '^b$'.
	self assert: (matcher find: 'a' , String cr , 'b') equals: 'b'.
	self assert: (matcher info: PCRE2 infoNewline) equals: PCRE2 newlineCR.
	compiler context useNewlineCRLF.
	self assert: ((compiler compile: '^b$') find: 'a' , String crlf , 'b' , String crlf) equals: 'b'.
	compiler context useNewlineNul.
	self assert: ((compiler compile: '^b$') find: 'a' , Character null asString , 'b') equals: 'b'.
	self assert: ((self compile: '\R') matches: String crlf).
	compiler context bsr: PCRE2 bsrAnyCRLF.
	self deny: ((compiler compile: '\R') search: (Character value: 16r2028) asString)
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testNonAtomicAssertionsCanBacktrack [

	self assert: ((self compile: '^(?*(a+))\1a$') matches: 'aaa').
	self assert: ((self compile: '^(*napla:(a+))\1a$') matches: 'aaa').
	self deny: ((self compile: '^(?=(a+))\1a$') matches: 'aaa').
	self assert: ((self compile: '(?<*(a{1,3}))\1b') find: 'aaab') equals: 'ab'.
	self should: [ self compile: '(?(?*a)b|c)' ] raise: PCRE2CompileError
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testNonOctalClassEscapesAndQuantifiedNonNewline [

	self assert: ((self compile: '^[A\8B\9C]+$') matches: 'A8B9C').
	self deny: ((self compile: '^[A\8B\9C]+$') matches: 'A8B9C' , (String with: Character null)).
	self assert: ((self compile: '^\N{1,}') findMatch: 'abc' , String lf , 'def') offsets equals: #( 0 3 )
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
PCRE2PharoBackendTest >> testPackedUnicodePropertiesDecodeEverySection [
	"Guards the packed literal against a change to the generator or the reader that quietly shifts a section."

	| data |
	data := PCRE2UnicodeProperties data.
	self assert: PCRE2UnicodeProperties version equals: '17.0.0'.
	self assert: (data at: 'properties') size equals: 451.
	self assert: ((PCRE2UnicodeProperties rangesFor: 'sc:grek') first: 4) equals: #( 880 883 885 887 ).
	self assert: (PCRE2UnicodeProperties rangesFor: 'gc:lu') isNil.
	self assert: ((data at: 'aliases') at: 'bc:arabicletter') equals: 'al'.
	self assert: ((data at: 'allowedProperties') at: 'adlam').
	self assert: (data at: 'scriptMasks') size equals: 5646
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testPackedUnicodeTablesDecodeEverySection [
	"Guards the packed literal against a change to the generator or the reader that quietly shifts a section."

	| tables |
	tables := self class environment
		          at: #PCRE2PackedUnicodeTables
		          ifAbsent: [ ^ self skip: 'PCRE2-UnicodeCompat is loaded on Pharo 14 and older' ].
	self assert: tables version equals: '17.0.0'.
	self assert: (tables data at: 'categories') size equals: 29.
	self assert: (tables data at: 'categoryRuns') size equals: 3409 * 3.
	self assert: (tables generalCategoryOf: 16r20001) equals: #lo.
	self assert: (tables generalCategoryOf: 16rD7A4) equals: #cn.
	self assert: (tables fold: $K asInteger) equals: 107.
	self assert: (tables equivalents: $K asInteger) equals: #( 75 107 8490 ).
	self assert: (tables decimalValueOf: 118001) equals: 1.
	self assert: (tables decimalValueOf: $A asInteger) isNil
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testPartialMatchingAtEmptyBoundariesAndResetStarts [

	| match |
	self assert: ((self compile: 'a*') findHardPartialMatch: '') isPartial.
	match := (self compile: 'a\Kb') findPartialMatch: 'a'.
	self assert: match isPartial.
	self assert: (match offsets first: 2) equals: #( 0 1 ).
	match := (self compile: '(?<=(a))bc') findPartialMatch: 'a'.
	self assert: match isPartial.
	self assert: (match offsets first: 2) equals: #( 1 1 ).
	self assert: ((self compile: '^$') findHardPartialMatch: '') isPartial
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testPartialMatchingReportsALoneCarriageReturnUnderCRLF [
	"Under the CRLF convention a CR in the last position may yet become a line terminator, which PCRE2 counts as reaching the end."

	self assert: (self partialMatch: '(*CRLF)(?m)a$' in: #[ 97 13 ] options: PCRE2 partialSoft) equals: {
			PCRE2 errorPartial.
			#( 0 2 ) }.
	self assert: (self partialMatch: '(*CRLF)a\Z' in: #[ 97 13 ] options: PCRE2 partialSoft) equals: {
			PCRE2 errorPartial.
			#( 0 2 ) }.
	self assert: (self partialMatch: '(*CRLF)a\Z' in: #[ 97 13 10 ] options: PCRE2 partialHard) equals: {
			PCRE2 errorPartial.
			#( 0 3 ) }
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testPartialMatchingReportsAssertionsThatWantedMoreSubject [
	"A word boundary, and an assertion that held only because the subject ends where it does, are reasons PCRE2 answers a partial match rather than a match."

	self assert: (self partialMatch: '\bWORD\b' in: #[  ] options: PCRE2 partialSoft) equals: {
			PCRE2 errorPartial.
			#( 0 0 ) }.
	self assert: (self partialMatch: '\bWORD\b' in: #[ 87 79 82 68 ] options: PCRE2 partialHard) equals: {
			PCRE2 errorPartial.
			#( 0 4 ) }.
	self assert: (self partialMatch: 'a\b' in: #[ 97 ] options: PCRE2 partialHard) equals: {
			PCRE2 errorPartial.
			#( 0 1 ) }.
	self assert: (self partialMatch: 'a\b' in: #[ 97 ] options: PCRE2 partialSoft) equals: {
			1.
			#( 0 1 ) }.
	self assert: (self partialMatch: 'ab\z' in: #[ 97 98 ] options: PCRE2 partialHard) equals: {
			PCRE2 errorPartial.
			#( 0 2 ) }.
	self assert: (self partialMatch: 'b$' in: #[ 97 98 10 ] options: PCRE2 partialHard) equals: {
			PCRE2 errorPartial.
			#( 1 3 ) }.
	self assert: (self partialMatch: '(?m)b$' in: #[ 97 98 10 99 100 ] options: PCRE2 partialHard) equals: {
			1.
			#( 1 2 ) }
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testPatternNodeIsTheOnlyAbstractNode [

	self assert: PCRE2PatternNode isAbstract.
	PCRE2PatternNode allSubclasses do: [ :node |
			self deny: node isAbstract description: node name , ' is concrete'.
			self
				deny: (node lookupSelector: #executeIn:state:) == (PCRE2PatternNode >> #executeIn:state:)
				description: node name , ' executes itself' ]
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testPatternsThatCanOnlyStartALineAreTriedAtLineStarts [
	"A pattern every branch of which opens with a dot star outside dotall can only match at the start of the subject or just after a line terminator, so that is where PCRE2 tries it. The end of the subject counts, since a line can begin and end there."

	self assert: (self startPositionsOf: '(?C1).*(?!)' in: (String lf join: #( 'aqaa' 'bqbb' 'cqcc' ))) equals: #( 0 5 10 14 ).
	self assert: (self startPositionsOf: '(?C1)[abcq]*(?!)' in: 'abc') equals: #( 0 1 2 3 )
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testPharoContextAnswersThePublicProtocol [
	"A public context message the Pharo backend cannot honour reports that it is unsupported, never a doesNotUnderstand."

	| compiler regex copy |
	compiler := PCRE2Compiler new backend: PCRE2CompilerPharoBackend.
	regex := compiler compile: 'a'.
	{
		[ compiler context useCharacterTablesFromCurrentLocale ].
		[ compiler context characterTables: PCRE2CompilerPharoBackend ].
		[ compiler context clearCharacterTables ].
		[ compiler context privateCopy ].
		[ regex context privateCopy ].
		[ regex context jitStack: nil ].
		[ regex context clearJITStack ] } do: [ :probe |
			[ probe value ]
				on: Error
				do: [ :error | self deny: (error isKindOf: MessageNotUnderstood) ] ].
	self should: [ compiler context useCharacterTablesFromCurrentLocale ] raise: PCRE2UnsupportedFeature.
	copy := compiler context privateCopy.
	copy parensNestLimit: 7.
	self deny: compiler context parensNestLimit equals: 7
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testPharoMatchersDoNotEnterFFIRestoration [

	| matcher |
	matcher := self compile: 'a'.
	self deny: matcher backend requiresSessionRestore.
	self deny: matcher context backend requiresSessionRestore
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testPharoUnicodeTablesReadTheImageTables [

	self assert: (PCRE2PharoUnicodeTables generalCategoryOf: $A asInteger) equals: #lu.
	self assert: (PCRE2PharoUnicodeTables generalCategoryOf: $_ asInteger) equals: #pc.
	self assert: (PCRE2PharoUnicodeTables generalCategoryOf: 16r10FFFF) equals: #cn.
	self assert: (PCRE2PharoUnicodeTables fold: 16r212A) equals: 107.
	self assert: (PCRE2PharoUnicodeTables equivalents: $K asInteger) equals: #( 75 107 8490 ).
	self assert: (PCRE2PharoUnicodeTables equivalents: $1 asInteger) equals: #( 49 ).
	self assert: (PCRE2PharoUnicodeTables decimalValueOf: 16r0663) equals: 3.
	self assert: (PCRE2PharoUnicodeTables decimalValueOf: $A asInteger) isNil
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testPinnedUnicodePropertiesAndCaseFolding [

	self assert: PCRE2UnicodeProperties version equals: '17.0.0'.
	self assert: ((self compile: '\p{sc=Greek}+') find: 'aαβ') equals: 'αβ'.
	self assert: ((self compile: '\p{Lu}') search: 'A').
	self assert: ((self compile: '\p{Emoji}') search: '😀').
	self assert: ((self compile: '(?i)k') matches: 'K').
	self assert: ((self compile: '(?i)[A-Z]') matches: 'ſ').
	self assert: ((self compile: '(?i)(k)\1') matches: 'kK').
	self assert: ((self compile: '\p{Lu}') search: (Character value: 16r1C89) asString).
	self deny: ((self compile: '\P{Lu}') search: (Character value: 16r1C89) asString)
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
PCRE2PharoBackendTest >> testPythonOctalAndEscapeRestrictions [

	| compiler |
	compiler := PCRE2UTF8Compiler new backend: PCRE2CompilerPharoBackend.
	compiler context options: PCRE2 extraPythonOctal.
	self assert: ((compiler compile: '\141') matches: 'a').
	self should: [ compiler compile: '\12' ] raise: PCRE2CompileError.
	self should: [ compiler compile: '\400' ] raise: PCRE2CompileError.
	compiler context options: PCRE2 extraNoBs0.
	self should: [ compiler compile: '\0' ] raise: PCRE2CompileError.
	self assert: ((compiler compile: '\00') matches: (String with: Character null)).
	compiler context options: PCRE2 extraNeverCallout.
	self should: [ compiler compile: '(?C1)a' ] raise: PCRE2CompileError.
	compiler addOptions: PCRE2 autoCallout.
	self assert: ((compiler compile: 'a') matches: 'a')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testQuotedCharacterClasses [

	self assert: ((self compile: '^[\Qabc\E-z]+$') matches: 'ayz').
	self assert: ((self compile: '[\Qa-]\E]+') find: 'a-]') equals: 'a-]'.
	self assert: ((self compile: '^[\E\Qa\E-\Qz\E]+') matches: 'xyz')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testQuotedQuantifierAppliesToLastCharacter [

	self assert: ((self compile: '\Qab*\E{2,}') find: 'ab***') equals: 'ab***'
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testRecompileAndZeroTerminatedSubjects [

	| matcher match |
	matcher := self compile: 'a+'.
	matcher recompile.
	self assert: (matcher find: 'aa') equals: 'aa'.
	matcher := self compile: '.*'.
	match := matcher matchBytes: #[ 97 98 99 0 100 ] from: 1 to: PCRE2 zeroTerminated.
	self assert: match offsets equals: #( 0 3 )
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testReferenceValidationAndDuplicateNamedBackreferences [

	self assert: ((self compile: '(?J)(?:(?<x>a)|(?<x>b))\k<x>') matches: 'bb').
	self assert: ((self compile: '(?<λ>a)\k<λ>') matches: 'aa').
	#( '(?&missing)' '(?P=missing)' '(?8)' '(?<1>a)' '(?<bad name>a)' ) do: [ :pattern |
		self should: [ self compile: pattern ] raise: PCRE2CompileError ].
	self should: [ (self compile: '(?R)') search: 'a' ] raise: PCRE2MatchError
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testRelativeAndOctalReferences [

	self assert: ((self compile: '(a.)\g{-1}Z') matches: 'ababZ').
	self assert: ((self compile: '\123') matches: 'S').
	self should: [ self compile: '(a)\g{2}' ] raise: PCRE2CompileError
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testScanSubstringAssertions [

	| matcher match |
	matcher := self compile: '\b(\w++)(*scs:(1).+rh)'.
	match := matcher findMatch: 'a myrrh and thyme'.
	self assert: (match groupAt: 0) equals: 'myrrh'.
	matcher := self compile: '(?<word>abc)(*scs:(<word>)(a)(bc)$)\2'.
	match := matcher findMatch: 'abca'.
	self assert: match offsets equals: #( 0 4 0 3 0 1 1 3 ).
	self deny: ((self compile: '(a)(*scs:(1)b)') search: 'a').
	self assert: ((self compile: 'x(a)(*scs:(1)(?<=x)a\z)') matches: 'xa')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testScanSubstringsBacktrackAndRestoreTheirBounds [

	| match |
	match := (self compile: '([a-z]{2})[a-z](*scs:(1)(.*?))\2$') findMatch: 'abxab'.
	self assert: match offsets equals: #( 0 5 0 2 0 2 ).
	self assert: ((self compile: '(abc)(def)(*scs:(1)(*scs:(2)de)).+') matches: 'abcdefZ')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testScopedASCIIAndCaselessRestrictions [

	| compiler |
	compiler := PCRE2UTF8Compiler new
		            backend: PCRE2CompilerPharoBackend;
		            options: PCRE2 utf | PCRE2 ucp | PCRE2 caseless.
	self assert: ((compiler compile: '(?aD:\d)\d') matches: '1١').
	self deny: ((compiler compile: '(?aD:\d)\d') matches: '١1').
	self assert: ((compiler compile: '(?aP:[[:alpha:]])[[:alpha:]]') matches: 'aé').
	self deny: ((compiler compile: '(?aP:[[:alpha:]])[[:alpha:]]') matches: 'éa').
	self assert: ((compiler compile: '(?r:k)k') matches: 'kK').
	self deny: ((compiler compile: '(?r:k)k') matches: 'Kk').
	self assert: ((compiler compile: '(?r:(k)\1)') matches: 'KK').
	self deny: ((compiler compile: '(?r:(k)\1)') matches: 'kK').
	compiler context options: PCRE2 extraAsciiBsw | PCRE2 extraCaselessRestrict.
	self deny: ((compiler compile: '\w') matches: 'é').
	self deny: ((compiler compile: 'k') matches: 'K')
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
PCRE2PharoBackendTest >> testSoftAndHardPartialMatching [

	| matcher |
	matcher := self compile: 'ab+'.
	self deny: (matcher findSoftPartialMatch: 'ab') isPartial.
	self assert: (matcher findHardPartialMatch: 'ab') isPartial.
	self assert: ((self compile: 'éclair') findPartialMatch: 'éc') readMatch equals: 'éc'.
	self assert: ((self compile: 'abc') findPartialMatch: 'ax') isNil
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testStartDirectivesAndFirstLine [

	| compiler matcher |
	self assert: ((self compile: '(*CR)(?m)^b$') find: 'a' , String cr , 'b') equals: 'b'.
	self assert: ((self compile: '(*UCP)\w+') find: 'αβ') equals: 'αβ'.
	compiler := PCRE2Compiler new
		            backend: PCRE2CompilerPharoBackend;
		            options: 0.
	matcher := compiler compile: '(*UTF)é+'.
	self assert: (matcher matches: 'éé').
	self
		should: [
				compiler
					addOptions: PCRE2 neverUTF;
					compile: '(*UTF)a' ]
		raise: PCRE2CompileError.
	compiler := PCRE2Compiler new
		            backend: PCRE2CompilerPharoBackend;
		            addOptions: PCRE2 firstLine.
	self deny: ((compiler compile: 'b') search: 'a' , String lf , 'b').
	self should: [ (self compile: '(*LIMIT_MATCH=1)a+') matches: 'aa' ] raise: PCRE2MatchError
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
PCRE2PharoBackendTest >> testSubroutineRetainedCapturesAndVersionConditions [

	| match |
	match := (self compile: '^(?1(2))\2(?(DEFINE)(a(.)b(.)c))') findMatch: 'aXbYcX'.
	self assert: match offsets equals: {
			0.
			6.
			PCRE2 unsetOffset.
			PCRE2 unsetOffset.
			1.
			2 }.
	self assert: ((self compile: '(?(VERSION>=10.49)yes|no)') matches: 'yes').
	self assert: ((self compile: '(?(VERSION=10.0)yes|no)') matches: 'no').
	self assert: ((self compile: '(?<VERSION>a)(?(VERSION)b|c)') matches: 'ab')
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
PCRE2PharoBackendTest >> testTurkishCaseFoldingAndStartDirectives [

	| compiler |
	compiler := PCRE2UTF8Compiler new
		            backend: PCRE2CompilerPharoBackend;
		            options: PCRE2 utf | PCRE2 caseless.
	compiler context options: PCRE2 extraTurkishCasing.
	self assert: ((compiler compile: 'I') matches: 'ı').
	self assert: ((compiler compile: 'i') matches: 'İ').
	self deny: ((compiler compile: 'I') matches: 'i').
	self assert: ((compiler compile: '(I)\1') matches: 'Iı').
	self assert: ((compiler compile: '(?r:I)') matches: 'i').
	compiler context options: 0.
	self assert: ((compiler compile: '(*TURKISH_CASING)I') matches: 'ı').
	self deny: ((compiler compile: '(*CASELESS_RESTRICT)k') matches: 'K').
	compiler options: 0.
	self assert: ((compiler compile: '(*UTF8)é') matches: 'é').
	compiler context options: PCRE2 extraTurkishCasing.
	self should: [ compiler compile: 'I' ] raise: PCRE2CompileError
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testUTSExtendedClasses [

	| compiler |
	compiler := PCRE2UTF8Compiler new
		            backend: PCRE2CompilerPharoBackend;
		            options: PCRE2 utf | PCRE2 ucp | PCRE2 altExtendedClass.
	self assert: ((compiler compile: '[a-z&&[^aeiou]]+') matches: 'bcdf').
	self deny: ((compiler compile: '[a-z&&[^aeiou]]+') matches: 'abc').
	self assert: ((compiler compile: '[\p{L}&&[\p{Greek}||\p{Thai}]]') matches: 'λ').
	self deny: ((compiler compile: '[\p{L}&&[\p{Greek}||\p{Thai}]]') matches: 'a').
	self assert: ((compiler compile: '[[ab]~~[bc]]') matches: 'a').
	self deny: ((compiler compile: '[[ab]~~[bc]]') matches: 'b').
	self should: [ compiler compile: '[a&&b--c]' ] raise: PCRE2CompileError.
	self assert: ((compiler compile: '(?[[a[]])') matches: '[')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testUnicodePropertyNamesFollowPCRE2 [

	#( '\p{gc=Lu}' '\p{Letter}' '\p{Uppercase_Letter}' '\p{Other_Alphabetic}' ) do: [ :pattern |
		self should: [ self compile: pattern ] raise: PCRE2CompileError ].
	self assert: ((self compile: '\p{Bidi_Mirrored}') search: '(').
	self assert: ((self compile: '\p{InCB}') search: (Character value: 16r94D) asString).
	self assert: ((self compile: '\p{bc=L}') search: 'a').
	#( 'Inherited' 'scx=Inherited' ) do: [ :name |
		self assert: ((self compile: '\p{' , name , '}') search: (Character value: 768) asString) ].
	#( 'Common' 'scx=Common' ) do: [ :name |
		self assert: ((self compile: '\p{' , name , '}') search: (Character value: 183) asString) ]
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
PCRE2PharoBackendTest >> testUnicodeScriptRunsAndGraphemes [

	self assert: ((self compile: '(*sr:\S+)') find: 'abcαβ') equals: 'abc'.
	self assert: ((self compile: '(*sr:\S+)') matches: '漢あカ').
	self deny: ((self compile: '(*sr:\S+)') matches: '1٠').
	self assert: ((self compile: '^\X$') matches: 'e' , (Character value: 16r0301) asString).
	self assert: ((self compile: '^\X$') matches: '👩‍💻').
	self assert: ((self compile: '\X') findAll: '🇫🇷🇬🇧') asArray equals: #( '🇫🇷' '🇬🇧' ).
	self assert: ((self compile: '\p{bidi_class : AL}') search: 'ا').
	self assert: ((self compile: '\N{ U+1234 }') search: (Character value: 16r1234) asString)
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

{ #category : 'tests' }
PCRE2PharoBackendTest >> testUnsupportedFeaturesAreExplicit [

	self should: [ (self compile: 'a') compileJIT ] raise: PCRE2UnsupportedFeature
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testWholeWordAndWholeLineCompileOptions [

	| compiler |
	compiler := PCRE2UTF8Compiler new backend: PCRE2CompilerPharoBackend.
	compiler context options: PCRE2 extraMatchWord.
	self assert: ((compiler compile: 'cat|dog') search: 'a dog!').
	self deny: ((compiler compile: 'cat|dog') search: 'scat').
	compiler context options: PCRE2 extraMatchLine.
	self assert: ((compiler compile: 'cat|dog') search: 'cat').
	self deny: ((compiler compile: 'cat|dog') search: 'a cat').
	compiler addOptions: PCRE2 multiline.
	self assert: ((compiler compile: 'cat|dog') search: 'a' , String lf , 'dog' , String lf , 'b')
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testWideUTFValidation [

	| compiler matcher bytes |
	compiler := PCRE2UTF16Compiler new backend: PCRE2CompilerPharoBackend.
	matcher := compiler compile: '.'.
	bytes := ByteArray new: 2.
	bytes uint16AtOffset: 0 put: 16rD800.
	self should: [ matcher matchBytes: bytes from: 1 to: 1 ] raise: PCRE2MatchError.
	compiler := PCRE2UTF32Compiler new backend: PCRE2CompilerPharoBackend.
	matcher := compiler compile: '.'.
	bytes := ByteArray new: 4.
	bytes uint32AtOffset: 0 put: 16r110000.
	self should: [ matcher matchBytes: bytes from: 1 to: 1 ] raise: PCRE2MatchError
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testWrittenMatchingAgreesWithTheEngine [
	"A pattern whose shape allows it is matched by a method written for that pattern alone. It reads the subject one byte at a time, so a byte it cannot judge sends the whole match back to the engine, which answers the same thing more slowly."

	| accented |
	self assert: (self compile: '[a-z]+ing') backend generatedMethod isNotNil.
	self assert: ((self compile: '[a-z]+ing') find: 'the thing is testing now') equals: 'thing'.
	self assert: ((self compile: 'a{2,4}b') find: 'aaaaab') equals: 'aaaab'.
	self assert: ((self compile: '[0-9]++x') find: 'a123x') equals: '123x'.
	self assert: ((self compile: '[a-z]*9') find: 'abc9') equals: 'abc9'.
	self assert: ((self compile: 'a+?b') find: 'aaab') equals: 'aaab'.
	self assert: ((self compile: '(a)(b)') find: 'xaby') equals: 'ab'.
	self assert: ((self compile: 'foo|barbaz') find: 'xbarbazy') equals: 'barbaz'.
	self assert: ((self compile: '\bword\b') find: 'a word here') equals: 'word'.
	self assert: ((self compile: '(?>a+)b') find: 'aaab') equals: 'aaab'.
	self assert: ((self compile: '(?:ab){2,3}c') find: 'ababababc') equals: 'abababc'.
	self assert: ((self compile: '(ab|cd)+x') find: 'yabcdabx') equals: 'abcdabx'.
	self assert: ((self compile: '(\w+) \1') find: 'say the the end') equals: 'the the'.
	self assert: ((self compile: '(?<=\$)\d+') find: 'cost $42 now') equals: '42'.
	self assert: ((self compile: '(a)?(?(1)b|c)') find: 'xxc') equals: 'c'.
	accented := String with: (Character value: 233).
	self assert: ((self compile: '[a-z]+' options: PCRE2 utf) find: accented , 'abc') equals: 'abc'.
	self assert: ((self compile: '[a-z]+' options: PCRE2 utf) find: 'abc' , accented) equals: 'abc'.
	"Nothing is written for a shape it does not know, and the engine answers as before."
	self assert: (self compile: '(a)(?1)') backend generatedMethod isNil.
	self assert: (self compile: 'a(*ACCEPT)b') backend generatedMethod isNil.
	self assert: ((self compile: '(a)(?1)') find: 'xaay') equals: 'aa'
]

{ #category : 'tests' }
PCRE2PharoBackendTest >> testZeroWidthCaptureProgressAndEmptyCapturingRepeats [

	self assert: ((self compile: '\A(?:(?=(\1.|))){1,3}\1\z') matches: 'ab').
	self assert: ((self compile: '(?<word>\k<word>xxx|)+') find: 'xxx') equals: ''.
	self deny: ((self compile: '(a|)*\d') search: ('a' repeat: 60))
]
