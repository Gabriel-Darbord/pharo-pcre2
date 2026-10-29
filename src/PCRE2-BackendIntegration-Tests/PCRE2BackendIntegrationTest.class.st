"
Checks coexistence of the FFI and Pharo backends. Loaded only when both implementations are available.
"
Class {
	#name : 'PCRE2BackendIntegrationTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-BackendIntegration-Tests',
	#package : 'PCRE2-BackendIntegration-Tests'
}

{ #category : 'tests' }
PCRE2BackendIntegrationTest >> testByteOrderMarkInReplacementAndCalloutStrings [

	| text |
	text := (Character value: 16rFEFF) asString.
	{
		PCRE2CompilerFFIBackend.
		PCRE2CompilerPharoBackend } do: [ :backend |
			| compiler matcher events |
			compiler := PCRE2Compiler new backend: backend.
			matcher := compiler compile: 'a'.
			self assert: (matcher substitute: 'a' with: text) equals: text.
			matcher := compiler compile: '(?C"' , text , '")a'.
			self assert: matcher calloutSites first string equals: text.
			events := OrderedCollection new.
			self assert: (matcher matches: 'a' calloutsDo: [ :event |
						 events add: event.
						 0 ]).
			self assert: events first string equals: text ]
]

{ #category : 'tests' }
PCRE2BackendIntegrationTest >> testByteOrderMarkIsRegexData [

	| text input |
	text := (Character value: 16rFEFF) asString.
	input := text asPCRE2UTF8Input.
	self assert: (input readFrom: 1 to: input size) equals: text.
	self assert: (input decodeBytes: input bytes) equals: text.
	self assert: (input nextMatchStartOffsetAfter: 0) equals: 3.
	{
		PCRE2CompilerFFIBackend.
		PCRE2CompilerPharoBackend } do: [ :backend |
			| matcher match |
			matcher := PCRE2Compiler new
				           backend: backend;
				           compile: text.
			match := matcher findMatch: 'a' , text , 'b'.
			self assert: match readMatch equals: text.
			self assert: (matcher matchingRangesIn: 'a' , text , 'b') asArray equals: { (2 to: 2) } ]
]

{ #category : 'tests' }
PCRE2BackendIntegrationTest >> testContextRolesAreChecked [

	| compiler matcher |
	compiler := PCRE2Compiler new.
	matcher := compiler compile: 'a'.
	self should: [ matcher context: compiler context ] raise: PCRE2Error.
	self should: [ compiler context: matcher context ] raise: PCRE2Error
]

{ #category : 'tests' }
PCRE2BackendIntegrationTest >> testCrossBackendContextsAndMatchDataAreRejected [

	| ffi pharo data |
	ffi := PCRE2Compiler new
		       backend: PCRE2CompilerFFIBackend;
		       compile: 'a'.
	pharo := PCRE2Compiler new
		         backend: PCRE2CompilerPharoBackend;
		         compile: 'a'.
	self should: [ ffi context: pharo context ] raise: PCRE2Error.
	self should: [ pharo context: ffi context ] raise: PCRE2Error.
	data := pharo newMatchData.
	self
		should: [
				ffi
					matchBytes: #[ 97 ]
					from: 1
					to: 1
					into: data ]
		raise: PCRE2Error.
	data := ffi newMatchData.
	self
		should: [
				pharo
					matchBytes: #[ 97 ]
					from: 1
					to: 1
					into: data ]
		raise: PCRE2Error
]

{ #category : 'tests' }
PCRE2BackendIntegrationTest >> testDFAWorkspaceReuseInvalidatesOffsetsAndResumesRepetition [

	{
		PCRE2CompilerFFIBackend.
		PCRE2CompilerPharoBackend } do: [ :backend |
			| matcher workspace data rc |
			matcher := PCRE2UTF8Compiler new
				           backend: backend;
				           compile: 'a+b+c'.
			workspace := ByteArray new: 400.
			data := matcher newMatchData.
			matcher options: PCRE2 partialHard.
			rc := matcher
				      dfaMatch: 'a'
				      from: 0
				      to: 1
				      matchData: data
				      workspace: workspace
				      size: 100.
			self assert: rc equals: PCRE2 errorPartial.
			self assert: (data offsets first: 2) equals: #( 0 1 ).
			matcher options: PCRE2 dfaRestart.
			rc := matcher
				      dfaMatch: 'bbc'
				      from: 0
				      to: 3
				      matchData: data
				      workspace: workspace
				      size: 100.
			self assert: rc equals: 1.
			self assert: (data offsets first: 2) equals: #( 0 3 ) ]
]

{ #category : 'tests' }
PCRE2BackendIntegrationTest >> testFFIContextRestoreDoesNotFollowTheGlobalDefault [

	| original context |
	original := PCRE2Compiler defaultBackend.
	context := (PCRE2Compiler new backend: PCRE2CompilerFFIBackend) context.
	context newline: PCRE2 newlineCR.
	context free.
	context getHandle beNull.
	[
		PCRE2Compiler defaultBackend: PCRE2CompilerPharoBackend.
		context restoreAfterStartup.
		self deny: context isNull.
		self assert: context newline equals: PCRE2 newlineCR ] ensure: [ PCRE2Compiler defaultBackend: original ]
]

{ #category : 'tests' }
PCRE2BackendIntegrationTest >> testMalformedUTFPatternsReportCompileErrors [

	{
		{
			PCRE2UTF8Compiler.
			#[ 97 255 ].
			1.
			-23 }.
		{
			PCRE2UTF16Compiler.
			#[  ].
			1.
			-24 }.
		{
			PCRE2UTF32Compiler.
			#[  ].
			1.
			-28 } } do: [ :entry |
			| bytes |
			bytes := entry first = PCRE2UTF8Compiler
				         ifTrue: [ entry second ]
				         ifFalse: [
						         entry first = PCRE2UTF16Compiler
							         ifTrue: [
									         (ByteArray new: 4)
										         uint16AtOffset: 0 put: 97;
										         uint16AtOffset: 2 put: 16rD800;
										         yourself ]
							         ifFalse: [
									         (ByteArray new: 8)
										         uint32AtOffset: 0 put: 97;
										         uint32AtOffset: 4 put: 16r110000;
										         yourself ] ].
			{
				PCRE2CompilerFFIBackend.
				PCRE2CompilerPharoBackend } do: [ :backend |
					self
						should: [
								entry first new
									backend: backend;
									compile: bytes ]
						raise: PCRE2CompileError
						withExceptionDo: [ :error |
								self assert: error offset equals: entry third.
								self assert: error errorMessage equals: (PCRE2 translateErrorCode: entry fourth).
								self assert: (error messageText includesSubstring: '(*ERROR)') ] ] ]
]

{ #category : 'tests' }
PCRE2BackendIntegrationTest >> testPartialCodeUnitCapturesDoNotReadBeyondTheirUTF8Slice [

	| input |
	input := 'é' asPCRE2UTF8Input.
	self should: [ input readFrom: 1 to: 1 ] raise: ZnCharacterEncodingError.
	self assert: (input readFrom: 1 to: 2) equals: 'é'.
	{
		PCRE2CompilerFFIBackend.
		PCRE2CompilerPharoBackend } do: [ :backend |
			| match |
			match := (PCRE2Compiler new
				          backend: backend;
				          compile: '\C') findMatch: 'é'.
			self assert: match offsets equals: #( 0 1 ).
			self should: [ match readMatch ] raise: ZnCharacterEncodingError ]
]

{ #category : 'tests' }
PCRE2BackendIntegrationTest >> testRawCodeUnitMatchingWithoutUTF [

	{
		PCRE2UTF8Compiler.
		PCRE2UTF16Compiler.
		PCRE2UTF32Compiler } do: [ :compilerClass |
			{
				PCRE2CompilerFFIBackend.
				PCRE2CompilerPharoBackend } do: [ :backend |
					| compiler matcher input match |
					compiler := compilerClass new
						            backend: backend;
						            options: 0.
					matcher := compiler compile: '.'.
					input := matcher preparedInputFor: '😀'.
					match := matcher matchBytes: input bytes from: 1 to: input size.
					self assert: match offsets equals: #( 0 1 ).
					matcher := compiler compile: 'é'.
					input := matcher preparedInputFor: 'é'.
					match := matcher matchBytes: input bytes from: 1 to: input size.
					self assert: match offsets equals: {
							0.
							input size } ] ]
]

{ #category : 'tests' }
PCRE2BackendIntegrationTest >> testRawPatternsSurviveRecompilationAndTracing [

	{
		PCRE2UTF8Compiler.
		PCRE2UTF16Compiler.
		PCRE2UTF32Compiler } do: [ :compilerClass |
			{
				PCRE2CompilerFFIBackend.
				PCRE2CompilerPharoBackend } do: [ :backend |
					| compiler bytes matcher width |
					compiler := compilerClass new
						            backend: backend;
						            options: 0.
					width := compiler codeUnitWidth.
					bytes := ByteArray new: width // 8.
					width = 8
						ifTrue: [ bytes at: 1 put: 255 ]
						ifFalse: [
								width = 16
									ifTrue: [ bytes uint16AtOffset: 0 put: 16rD800 ]
									ifFalse: [ bytes uint32AtOffset: 0 put: 16rFFFFFFFF ] ].
					matcher := compiler compile: bytes.
					self assert: (matcher matchBytes: bytes from: 1 to: 1) offsets equals: #( 0 1 ).
					matcher recompile.
					self assert: (matcher matchBytes: bytes from: 1 to: 1) offsets equals: #( 0 1 ).
					self assert: (matcher traceMatcher matchBytes: bytes from: 1 to: 1) offsets equals: #( 0 1 ) ] ]
]

{ #category : 'tests' }
PCRE2BackendIntegrationTest >> testTemporaryCompilersPreserveTheSelectedBackend [

	| original matcher trace |
	original := PCRE2Compiler defaultBackend.
	matcher := PCRE2Compiler new
		           backend: PCRE2CompilerFFIBackend;
		           compile: 'a'.
	[
		PCRE2Compiler defaultBackend: PCRE2CompilerPharoBackend.
		trace := matcher traceMatch: 'a'.
		self assert: trace match readMatch equals: 'a'.
		self assert: (matcher backend isKindOf: PCRE2MatcherFFIBackend) ] ensure: [ PCRE2Compiler defaultBackend: original ]
]
