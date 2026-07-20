"
Parametrized tests for PCRE2 behavior that should hold across the 8-, 16-, and 32-bit code-unit APIs.

This class covers shared library, compiler, character-table, matcher, conversion, JIT, callout, substitution, trace, serialization, and prepared-input contracts while still asserting the concrete width-specific classes. Keep byte-order, BOM, invalid-size, and UTF-16 supplementary-code-unit edge cases in the concrete UTF input/matcher test classes, where the byte layout itself is the behavior under test.
"
Class {
	#name : 'PCRE2CodeUnitWidthTest',
	#superclass : 'ParametrizedTestCase',
	#instVars : [
		'compilerClass',
		'libraryClass',
		'inputSelector',
		'inputClass',
		'codeUnitWidth',
		'isSupported',
		'matcherClass',
		'matchClass',
		'compileContextClass',
		'matchContextClass',
		'convertContextClass',
		'jitStackClass',
		'characterTablesClass'
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
				  (#inputClass -> PCRE2UTF8Input).
				  (#matcherClass -> PCRE2UTF8Matcher).
				  (#matchClass -> PCRE2UTF8Match).
				  (#compileContextClass -> PCRE2UTF8CompileContext).
				  (#matchContextClass -> PCRE2UTF8MatchContext).
				  (#convertContextClass -> PCRE2UTF8ConvertContext).
				  (#jitStackClass -> PCRE2UTF8JITStack).
				  (#characterTablesClass -> PCRE2UTF8CharacterTables).
				  (#isSupported -> true) };
		  addCase: {
				  (#codeUnitWidth -> 16).
				  (#compilerClass -> PCRE2UTF16Compiler).
				  (#libraryClass -> LibPCRE2UTF16).
				  (#inputSelector -> #asPCRE2UTF16Input).
				  (#inputClass -> PCRE2UTF16Input).
				  (#matcherClass -> PCRE2UTF16Matcher).
				  (#matchClass -> PCRE2UTF16Match).
				  (#compileContextClass -> PCRE2UTF16CompileContext).
				  (#matchContextClass -> PCRE2UTF16MatchContext).
				  (#convertContextClass -> PCRE2UTF16ConvertContext).
				  (#jitStackClass -> PCRE2UTF16JITStack).
				  (#characterTablesClass -> PCRE2UTF16CharacterTables).
				  (#isSupported -> [ LibPCRE2 supports16BitCodeUnitWidth ]) };
		  addCase: {
				  (#codeUnitWidth -> 32).
				  (#compilerClass -> PCRE2UTF32Compiler).
				  (#libraryClass -> LibPCRE2UTF32).
				  (#inputSelector -> #asPCRE2UTF32Input).
				  (#inputClass -> PCRE2UTF32Input).
				  (#matcherClass -> PCRE2UTF32Matcher).
				  (#matchClass -> PCRE2UTF32Match).
				  (#compileContextClass -> PCRE2UTF32CompileContext).
				  (#matchContextClass -> PCRE2UTF32MatchContext).
				  (#convertContextClass -> PCRE2UTF32ConvertContext).
				  (#jitStackClass -> PCRE2UTF32JITStack).
				  (#characterTablesClass -> PCRE2UTF32CharacterTables).
				  (#isSupported -> [ LibPCRE2 supports32BitCodeUnitWidth ]) };
		  yourself
]

{ #category : 'private' }
PCRE2CodeUnitWidthTest >> byteBackedCafeOffsets [

	codeUnitWidth = 8 ifTrue: [ ^ #( 2 7 ) ].
	^ #( 2 6 )
]

{ #category : 'accessing' }
PCRE2CodeUnitWidthTest >> characterTablesClass: aClass [

	characterTablesClass := aClass
]

{ #category : 'accessing' }
PCRE2CodeUnitWidthTest >> codeUnitWidth: anInteger [

	codeUnitWidth := anInteger
]

{ #category : 'accessing' }
PCRE2CodeUnitWidthTest >> compileContextClass: aClass [

	compileContextClass := aClass
]

{ #category : 'private' }
PCRE2CodeUnitWidthTest >> compiler [

	^ compilerClass new
]

{ #category : 'accessing' }
PCRE2CodeUnitWidthTest >> compilerClass: aClass [

	compilerClass := aClass
]

{ #category : 'accessing' }
PCRE2CodeUnitWidthTest >> convertContextClass: aClass [

	convertContextClass := aClass
]

{ #category : 'private' }
PCRE2CodeUnitWidthTest >> dejaCalloutStringLength [

	codeUnitWidth = 8 ifTrue: [ ^ 6 ].
	^ 4
]

{ #category : 'private' }
PCRE2CodeUnitWidthTest >> emojiString [

	^ String with: (Character value: 16r1F600)
]

{ #category : 'accessing' }
PCRE2CodeUnitWidthTest >> inputClass: aClass [

	inputClass := aClass
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
PCRE2CodeUnitWidthTest >> jitStackClass: aClass [

	jitStackClass := aClass
]

{ #category : 'private' }
PCRE2CodeUnitWidthTest >> leadingEcByteSize [

	codeUnitWidth = 8 ifTrue: [ ^ 3 ].
	^ 2 * (codeUnitWidth // 8)
]

{ #category : 'accessing' }
PCRE2CodeUnitWidthTest >> libraryClass: aClass [

	libraryClass := aClass
]

{ #category : 'accessing' }
PCRE2CodeUnitWidthTest >> matchClass: aClass [

	matchClass := aClass
]

{ #category : 'accessing' }
PCRE2CodeUnitWidthTest >> matchContextClass: aClass [

	matchContextClass := aClass
]

{ #category : 'accessing' }
PCRE2CodeUnitWidthTest >> matcherClass: aClass [

	matcherClass := aClass
]

{ #category : 'private' }
PCRE2CodeUnitWidthTest >> nativeBytesInputFor: aString [

	^ (self preparedInputFor: aString) bytes perform: inputSelector
]

{ #category : 'private' }
PCRE2CodeUnitWidthTest >> preparedInputFor: aString [

	^ aString perform: inputSelector
]

{ #category : 'private' }
PCRE2CodeUnitWidthTest >> regexFor: aString [

	^ self compiler compile: aString
]

{ #category : 'private' }
PCRE2CodeUnitWidthTest >> skipUnlessSupported [

	isSupported ifFalse: [ ^ true ].
	^ false
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testByteBackedInputMatchesAndReportsCharacterRanges [

	| input match ranges regex subject |
	self skipUnlessSupported ifTrue: [ ^ self ].

	subject := '1 café 2'.
	input := self nativeBytesInputFor: subject.
	regex := self regexFor: '\p{L}+'.
	match := regex findMatch: input.
	ranges := regex matchingRangesIn: input.

	self assert: match readMatch equals: 'café'.
	self assert: match offsets equals: self byteBackedCafeOffsets.
	self assert: ranges asArray equals: { (3 to: 6) }
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testCalloutSitesDoEnumeratesInPatternOrder [

	| regex visited |
	self skipUnlessSupported ifTrue: [ ^ self ].

	regex := self regexFor: '(?C2)a(?C3)b'.
	visited := OrderedCollection new.

	regex calloutSitesDo: [ :site | visited add: site number ].

	self assert: visited asArray equals: #( 2 3 )
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testCalloutSitesDoNotAffectMatching [

	| regex |
	self skipUnlessSupported ifTrue: [ ^ self ].

	regex := self regexFor: '(?C1)a(?C"déjà")b'.

	self assert: regex calloutSites size equals: 2.
	self assert: (regex matches: 'ab').
	self deny: (regex matches: 'ac')
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testCalloutSitesExposeNumberedAndStringCallouts [

	| first regex second sites |
	self skipUnlessSupported ifTrue: [ ^ self ].

	regex := self regexFor: '(?C1)a(?C"déjà")b'.
	sites := regex calloutSites.
	first := sites first.
	second := sites second.

	self assert: sites size equals: 2.
	self assert: first number equals: 1.
	self deny: first hasString.
	self assert: second number equals: 0.
	self assert: second hasString.
	self assert: second string equals: 'déjà'.
	self assert: second stringLength equals: self dejaCalloutStringLength.
	self assert: second patternPosition > first patternPosition
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testCapturesAndNamedGroupsReadFromInput [

	| match regex |
	self skipUnlessSupported ifTrue: [ ^ self ].

	regex := self regexFor: '(?<word>\p{L}+)-(\d+)'.
	match := regex findMatch: 'café-42'.

	self assert: match class equals: matchClass.
	self assert: match readMatches equals: #( 'café-42' 'café' '42' ).
	self assert: (match groupNamed: 'word') equals: 'café'
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testCharacterTablesAndCopyWithTables [

	| compiler copy regex |
	self skipUnlessSupported ifTrue: [ ^ self ].

	compiler := self compiler.
	compiler context useCharacterTablesFromCurrentLocale.
	regex := compiler compile: '\w+'.
	regex options: PCRE2 notEmpty.
	copy := regex copyWithCharacterTables.

	self assert: regex class equals: matcherClass.
	self deny: copy identicalTo: regex.
	self assert: copy class equals: matcherClass.
	self assert: copy options equals: regex options.
	self assert: (regex matches: 'abc').
	self assert: (copy matches: 'abc')
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testCompileAndMatchContextsUseNativeAPI [

	| crCompiler crRegex lfCompiler lfRegex limitRegex subject |
	self skipUnlessSupported ifTrue: [ ^ self ].

	crCompiler := self compiler.
	self assert: crCompiler context class equals: compileContextClass.
	crCompiler options: (PCRE2 utf bitOr: PCRE2 multiline).
	crCompiler context useNewlineCR.
	crRegex := crCompiler compile: '^b$'.
	self assert: crRegex context class equals: matchContextClass.

	lfCompiler := self compiler.
	lfCompiler options: (PCRE2 utf bitOr: PCRE2 multiline).
	lfCompiler context useNewlineLF.
	lfRegex := lfCompiler compile: '^b$'.

	subject := 'a' , String cr , 'b'.
	self assert: (crRegex find: subject) equals: 'b'.
	self assert: (lfRegex find: subject) isNil.
	self assert: (crRegex info: PCRE2 infoNewline) equals: PCRE2 newlineCR.
	self assert: (lfRegex info: PCRE2 infoNewline) equals: PCRE2 newlineLF.

	limitRegex := self regexFor: '(a+)+'.
	limitRegex addOptions: PCRE2 noJIT.
	limitRegex context matchLimit: 1.
	self should: [ limitRegex matches: 'aa' ] raise: PCRE2MatchError
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testCompileErrorFromNativeBytePatternDecodesPattern [

	| patternInput |
	self skipUnlessSupported ifTrue: [ ^ self ].

	patternInput := self nativeBytesInputFor: '(a'.
	self should: [ self compiler compile: patternInput ] raise: PCRE2CompileError withExceptionDo: [ :error |
			self assert: error pattern equals: '(a'.
			self assert: error offset isInteger.
			self assert: (error messageText includesSubstring: '(*ERROR)') ]
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testCompilePatternFromNativeEndianBytes [

	| patternInput regex |
	self skipUnlessSupported ifTrue: [ ^ self ].

	patternInput := self nativeBytesInputFor: 'a+'.
	regex := self compiler compile: patternInput.

	self assert: regex class equals: matcherClass.
	self assert: regex pattern equals: 'a+'.
	self assert: (regex matches: 'aaa').
	self deny: (regex matches: 'bbb')
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testCompileReturnsWidthSpecificMatcher [

	| regex |
	self skipUnlessSupported ifTrue: [ ^ self ].

	regex := self regexFor: '\p{L}+'.

	self assert: regex class equals: matcherClass.
	self assert: regex codeUnitWidth equals: codeUnitWidth
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testCompilerAcceptsPreparedPatternInput [

	| bytes prepared regex |
	self skipUnlessSupported ifTrue: [ ^ self ].

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
PCRE2CodeUnitWidthTest >> testConcreteLibraryWidth [

	self skipUnlessSupported ifTrue: [ ^ self ].

	self assert: libraryClass codeUnitWidth equals: codeUnitWidth.
	self assert: libraryClass supportsCodeUnitWidth
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testConcreteWidthClassesAreNotAbstract [

	self skipUnlessSupported ifTrue: [ ^ self ].

	{
		characterTablesClass.
		compileContextClass.
		compilerClass.
		convertContextClass.
		inputClass.
		jitStackClass.
		matchClass.
		matchContextClass.
		matcherClass } do: [ :each | self deny: each isAbstract ]
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testConvertContextIsWidthSpecific [

	self skipUnlessSupported ifTrue: [ ^ self ].
	LibPCRE2 supportsPatternConversion ifFalse: [ ^ self ].

	self assert: libraryClass newConvertContext class equals: convertContextClass
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testDFAMatchReturnsAllAlternatives [

	| match regex subject |
	self skipUnlessSupported ifTrue: [ ^ self ].

	subject := 'the caterpillar catchment'.
	regex := self regexFor: 'cat(er(pillar)?)?'.
	match := regex dfaMatch: subject workspaceSize: 40 ovectorSize: 3.

	self assert: match class equals: matchClass.
	self assert: match count equals: 3.
	self assert: match readMatches equals: #( 'caterpillar' 'cater' 'cat' ).
	self assert: (regex dfaMatches: subject workspaceSize: 40 ovectorSize: 3) equals: #( 'caterpillar' 'cater' 'cat' )
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testFindAllAndSplitReuseHighLevelFlow [

	| regex |
	self skipUnlessSupported ifTrue: [ ^ self ].

	regex := self regexFor: '\p{L}+'.
	self assert: (regex findAll: 'aa 123 éé') asArray equals: #( 'aa' 'éé' ).
	self assert: ((self regexFor: ',') split: 'a,b,c') asArray equals: #( 'a' 'b' 'c' )
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testFindAllHandlesEmptyGlobalMatches [

	| regex |
	self skipUnlessSupported ifTrue: [ ^ self ].

	regex := self regexFor: 'a*?'.
	self assert: (regex findAll: 'aaa') asArray equals: #( '' 'a' '' 'a' '' 'a' '' )
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testFindMatchReadsUnicodeText [

	| match regex |
	self skipUnlessSupported ifTrue: [ ^ self ].

	regex := self regexFor: '\p{L}+'.
	match := regex findMatch: 'café 123'.

	self assert: match class equals: matchClass.
	self assert: match readMatch equals: 'café'.
	self assert: match offsets equals: self unicodeWordOffsets
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testInputDecodesLeadingByteSlice [

	| input |
	self skipUnlessSupported ifTrue: [ ^ self ].

	input := self preparedInputFor: 'éclair'.

	self assert: (input decodeBytes: (input bytes copyFrom: 1 to: self leadingEcByteSize)) equals: 'éc'
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testJITStackCanBeAssignedToMatchContext [

	| regex stack |
	self skipUnlessSupported ifTrue: [ ^ self ].
	LibPCRE2 supportsJIT ifFalse: [ ^ self ].

	stack := jitStackClass default.
	regex := self regexFor: 'a+'.
	regex compileJIT.
	regex context jitStack: stack.

	self assert: regex context jitStack identicalTo: stack.
	self assert: (regex find: 'baaa') equals: 'aaa'.

	regex context clearJITStack.
	self assert: regex context jitStack isNil.
	self assert: (regex find: 'baaa') equals: 'aaa'
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testLibraryCanConvertGlobAndMatch [

	| regex |
	self skipUnlessSupported ifTrue: [ ^ self ].
	LibPCRE2 supportsPatternConversion ifFalse: [ ^ self ].

	regex := self compiler compile: (libraryClass convertGlob: '*é').

	self assert: regex class equals: matcherClass.
	self assert: (regex matches: 'café').
	self deny: (regex matches: 'cafe')
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testLibraryCanConvertPreparedGlobBytes [

	| patternBytes regex |
	self skipUnlessSupported ifTrue: [ ^ self ].
	LibPCRE2 supportsPatternConversion ifFalse: [ ^ self ].

	patternBytes := (self preparedInputFor: '*é') bytes.
	regex := compilerClass new compile: (libraryClass convertGlob: patternBytes).

	self assert: regex codeUnitWidth equals: codeUnitWidth.
	self assert: (regex matches: 'café').
	self deny: (regex matches: 'cafe')
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testLibraryCanUseConvertContext [

	| context regex |
	self skipUnlessSupported ifTrue: [ ^ self ].
	LibPCRE2 supportsPatternConversion ifFalse: [ ^ self ].

	context := libraryClass newConvertContext.
	context globEscape: $!.
	regex := self compiler compile: (libraryClass convertGlob: 'file!*.st' context: context).

	self assert: regex class equals: matcherClass.
	self assert: (regex matches: 'file*.st').
	self deny: (regex matches: 'fileABC.st')
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testMark [

	| regex |
	self skipUnlessSupported ifTrue: [ ^ self ].

	regex := self regexFor: ''.
	self assert: (regex findMatch: '') mark equals: nil.

	regex := self regexFor: '(*MARK:bye)((*MARK:café)A|D)C'.
	self assert: (regex findMatch: 'AC') mark equals: 'café'.
	self assert: (regex findMatch: 'DC') mark equals: 'bye'
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testMatchDataDiagnosticsUseNativeAPI [

	| heapframesSize match |
	self skipUnlessSupported ifTrue: [ ^ self ].

	match := (self regexFor: '(a)(b)') findMatch: 'zab'.
	heapframesSize := match heapframesSize.

	self assert: match class equals: matchClass.
	self assert: match matchDataSize isInteger.
	self assert: match matchDataSize > 0.
	libraryClass supportsMatchDataHeapframesSize
		ifTrue: [
				self assert: heapframesSize isInteger.
				self assert: heapframesSize >= 0 ]
		ifFalse: [ self assert: heapframesSize isNil ]
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testMatcherSerializationConvenienceRoundTrip [

	| bytes regex |
	self skipUnlessSupported ifTrue: [ ^ self ].

	regex := self regexFor: 'é+'.
	bytes := regex serialize.

	regex finalize.
	self assert: regex isNull.
	regex restoreFrom: bytes.

	self deny: regex isNull.
	self assert: regex class equals: matcherClass.
	self assert: (regex matches: 'éé')
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testMatchingRangesUseCharacterOffsets [

	| ranges regex |
	self skipUnlessSupported ifTrue: [ ^ self ].

	regex := self regexFor: '\p{L}+'.
	ranges := regex matchingRangesIn: '1 café 2'.

	self assert: ranges asArray equals: { (3 to: 6) }
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testNativeEndianBytesCanCreateReusableInput [

	| input subject |
	self skipUnlessSupported ifTrue: [ ^ self ].

	subject := 'café'.
	input := self nativeBytesInputFor: subject.

	self assert: input class equals: inputClass.
	self assert: input bytes size equals: input size * (codeUnitWidth // 8).
	self assert: (input readFrom: 1 to: input size) equals: subject.
	self assert: (input characterCountUpToCodeUnitOffset: input size) equals: subject size
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testNewCharacterTables [

	| tables |
	self skipUnlessSupported ifTrue: [ ^ self ].

	tables := libraryClass newCharacterTables.

	self deny: tables isNull.
	self assert: tables class equals: characterTablesClass.
	self assert: tables codeUnitWidth equals: codeUnitWidth
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testRuntimeCalloutDecodesPayloadsAndMarks [

	| event events regex |
	self skipUnlessSupported ifTrue: [ ^ self ].

	regex := self regexFor: '(*MARK:café)(?C"cœur")x'.
	regex addOptions: PCRE2 noJIT.
	events := OrderedCollection new.

	self assert: (regex matches: 'x' calloutsDo: [ :each |
				 events add: each.
				 0 ]).
	event := events first.
	self assert: event string equals: 'cœur'.
	self assert: event mark equals: 'café'
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testStringCanCreateReusableInput [

	| input subject |
	self skipUnlessSupported ifTrue: [ ^ self ].

	subject := 'café'.
	input := self preparedInputFor: subject.

	self assert: input class equals: inputClass.
	self assert: input bytes size equals: input size * (codeUnitWidth // 8).
	self assert: (input readFrom: 1 to: input size) equals: subject.
	self assert: (input characterCountUpToCodeUnitOffset: input size) equals: subject size
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testSubstituteCalloutDecodesText [

	| events regex result |
	self skipUnlessSupported ifTrue: [ ^ self ].
	LibPCRE2 supportsSubstitutionCallouts ifFalse: [ ^ self ].

	regex := self regexFor: 'é'.
	events := OrderedCollection new.
	result := regex substituteAll: 'café café' with: 'e$0' calloutsDo: [ :event |
			          events add: event.
			          PCRE2 substituteCalloutAccept ].

	self assert: result equals: 'cafeé cafeé'.
	self assert: events size equals: 2.
	self assert: events first matchedText equals: 'é'.
	self assert: events first replacementText equals: 'eé'.
	self assert: events second matchedText equals: 'é'.
	self assert: events second replacementText equals: 'eé'
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testSubstituteCaseCalloutDecodesText [

	| events regex result |
	self skipUnlessSupported ifTrue: [ ^ self ].
	LibPCRE2 supportsSubstitutionCaseCallouts ifFalse: [ ^ self ].

	regex := self regexFor: '(\p{L}+)'.
	events := OrderedCollection new.
	result := regex
		          substituteAll: 'café thé'
		          with: '\U$0'
		          options: PCRE2 substituteExtended
		          caseCallout: [ :event |
				          events add: event.
				          event inputText , '!' ].

	self assert: result equals: 'café! thé!'.
	self assert: events size equals: 2.
	self assert: events first inputText equals: 'café'.
	self assert: events first caseName equals: #uppercase.
	self assert: events first codeUnitWidth equals: codeUnitWidth
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testSubstitutionAndCopyReuseHighLevelFlow [

	| input match regex replacement |
	self skipUnlessSupported ifTrue: [ ^ self ].

	regex := self regexFor: 'é'.
	self assert: (regex substituteAll: 'café café' with: 'e') equals: 'cafe cafe'.

	input := self preparedInputFor: 'café café'.
	replacement := self preparedInputFor: 'e'.
	self assert: (regex substituteAll: input with: replacement) equals: 'cafe cafe'.

	regex := self regexFor: '(\p{L}+)'.
	input := self preparedInputFor: 'one two'.
	match := regex findMatch: input.
	self assert: (regex substituteUsingMatch: match with: '[$0]') equals: '[one] two'.

	regex := self regexFor: '\d+'.
	self assert: (regex copy: 'a12b3' translatingMatchesUsing: [ :each | '[' , each , ']' ]) equals: 'a[12]b[3]'
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testTraceMatchDecodesCalloutEvents [

	| event trace |
	self skipUnlessSupported ifTrue: [ ^ self ].

	trace := (self regexFor: '(?C"cœur")é') traceMatch: 'é'.
	event := trace events detect: [ :each | each hasString ].

	self assert: trace isMatch.
	self assert: trace matchedString equals: 'é'.
	self assert: event string equals: 'cœur'.
	self assert: (trace subjectCharacterPositionAtEvent: event) equals: 1
]

{ #category : 'tests' }
PCRE2CodeUnitWidthTest >> testTraceMatchTranslatesPatternRanges [

	| emoji event trace |
	self skipUnlessSupported ifTrue: [ ^ self ].

	emoji := self emojiString.
	trace := (self regexFor: emoji , '(?C2)a') traceMatch: emoji , 'a'.
	event := trace events detect: [ :each | each number = 2 ].

	self assert: (trace patternCharacterRangeForEvent: event) equals: (7 to: 7).
	self assert: (trace subjectCharacterPositionAtEvent: event) equals: 2
]

{ #category : 'private' }
PCRE2CodeUnitWidthTest >> unicodeWordOffsets [

	codeUnitWidth = 8 ifTrue: [ ^ #( 0 5 ) ].
	^ #( 0 4 )
]
