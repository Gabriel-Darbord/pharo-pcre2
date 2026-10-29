Class {
	#name : 'PCRE2MatcherPharoBackend',
	#superclass : 'Object',
	#instVars : [
		'matcher',
		'root',
		'captureCount',
		'names',
		'groups',
		'compileOptions',
		'newlineMode',
		'bsrMode',
		'maximumLookbehind',
		'calloutSites',
		'patternMatchOptions',
		'patternLimits',
		'dfaStates'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> autoRelease [

	^ self
]

{ #category : 'callouts' }
PCRE2MatcherPharoBackend >> calloutSitesDo: block [

	calloutSites do: block
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> codeUnitWidth [

	^ matcher codeUnitWidth
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> codeUnitsFor: character [

	| code |
	code := character asInteger.
	self codeUnitWidth = 32 ifTrue: [ ^ 1 ].
	self codeUnitWidth = 16 ifTrue: [
			^ code > 65535
				  ifTrue: [ 2 ]
				  ifFalse: [ 1 ] ].
	code < 128 ifTrue: [ ^ 1 ].
	code < 2048 ifTrue: [ ^ 2 ].
	^ code < 65536
		  ifTrue: [ 3 ]
		  ifFalse: [ 4 ]
]

{ #category : 'accessing' }
PCRE2MatcherPharoBackend >> compileOptions: anInteger [

	compileOptions := anInteger
]

{ #category : 'diagnostics' }
PCRE2MatcherPharoBackend >> compiledStorageSize [

	| seen |
	seen := IdentitySet new.
	^ self sizeInMemory + (PCRE2CompiledPatternSize of: root seen: seen) + (PCRE2CompiledPatternSize of: groups seen: seen)
	  + (PCRE2CompiledPatternSize of: names seen: seen)
]

{ #category : 'substitution' }
PCRE2MatcherPharoBackend >> conditionalValue: reference match: match options: options [

	| number known |
	number := (reference isNotEmpty and: [ reference allSatisfy: #isDigit ]) ifTrue: [ reference asInteger ].
	known := number ifNil: [ match namedGroups includes: reference ] ifNotNil: [ number < match ovectorCount ].
	(known not and: [ (options bitAnd: PCRE2 substituteUnknownUnset) = 0 ]) ifTrue: [ PCRE2MatchError signal: 'unknown substring' ].
	^ known ifTrue: [ number ifNil: [ match groupNamed: reference ] ifNotNil: [ match groupAt: number ] ]
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> copyWithCharacterTables [

	^ self copy
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> depthLimit [

	^ matcher context depthLimit min: (patternLimits at: #depth ifAbsent: [ matcher context depthLimit ])
]

{ #category : 'DFA matching' }
PCRE2MatcherPharoBackend >> dfaMatch: bytes from: start to: length matchData: data workspace: workspace size: workspaceSize [

	| decoded text mapping initial engine state matches lastIndex options allowed minimum candidate continuation |
	options := matcher options.
	(workspaceSize < 20 or: [ workspace size < (workspaceSize * 4) ]) ifTrue: [
		PCRE2MatchError signal: (PCRE2 translateErrorCode: -43) ].
	continuation := (options bitAnd: PCRE2 dfaRestart) ~= 0
		                ifTrue: [ self restartDFAFrom: workspace ]
		                ifFalse: [
				                dfaStates ifNotNil: [ dfaStates removeKey: workspace ifAbsent: [ ] ].
				                nil ].
	allowed := PCRE2 anchored | PCRE2 endAnchored | PCRE2 notBOL | PCRE2 notEOL | PCRE2 notEmpty | PCRE2 notEmptyAtStart
	           | PCRE2 dfaShortest | PCRE2 dfaRestart | PCRE2 noUTFCheck | PCRE2 partialSoft | PCRE2 partialHard
	           | PCRE2 copyMatchedSubject.
	(options bitAnd: allowed bitInvert) ~= 0 ifTrue: [
		PCRE2UnsupportedFeature signal: 'These DFA options are not yet implemented by the Pharo backend' ].
	decoded := self textAndOffsetsFor: bytes length: length.
	text := decoded first.
	mapping := decoded second.
	initial := start.
	(start between: 0 and: text size) ifFalse: [ PCRE2MatchError signal: 'bad offset value' ].
	((options bitAnd: PCRE2 noUTFCheck) = 0 and: [ (text isBoundary: start) not ]) ifTrue: [
		PCRE2MatchError signal: 'bad UTF offset' ].
	engine := PCRE2DFAMatcher new
		          subject: text
		          root: root
		          groups: groups
		          names: names
		          limit: self matchLimit;
		          depthLimit: self depthLimit;
		          initialPosition: initial;
		          matchOptions: (options bitOr: ((compileOptions bitAnd: PCRE2 endAnchored) bitOr: patternMatchOptions));
		          calloutBlock: matcher context backend calloutBlock mapping: mapping;
		          shortest: (options bitAnd: PCRE2 dfaShortest) ~= 0;
		          autoPossessEnabled: (compileOptions bitAnd: PCRE2 noAutoPossess) = 0;
		          workspaceLimit: workspaceSize;
		          allowEmptyPartial: maximumLookbehind > 0.
	lastIndex := (continuation isNotNil or: [ ((options bitOr: compileOptions) bitAnd: PCRE2 anchored) ~= 0 ])
		             ifTrue: [ initial ]
		             ifFalse: [ text size ].
	minimum := (root lengthBoundsUsing: groups names: names visited: IdentitySet new) first.
	(compileOptions bitAnd: PCRE2 firstLine) ~= 0 ifTrue: [ lastIndex := lastIndex min: (self firstLineEndIn: text) ].
	candidate := initial.
	[ candidate <= lastIndex ] whileTrue: [
			(continuation isNotNil or: [
					 (compileOptions bitAnd: PCRE2 noStartOptimize) ~= 0 or: [
						 (options bitAnd: PCRE2 partialSoft | PCRE2 partialHard) ~= 0 or: [ text size - candidate >= minimum ] ] ]) ifTrue: [
					state := PCRE2MatchState new
						         position: candidate;
						         captures: (Array new: captureCount + 1 * 2 withAll: PCRE2 unsetOffset).
					state captures at: 1 put: candidate.
					state push: root.
					engine beginMatchAt: candidate.
					matches := continuation ifNil: [ engine allMatches: state ] ifNotNil: [
							           continuation do: [ :continued | continued captures at: 1 put: initial ].
							           engine allMatchesFrom: continuation ].
					engine abortedCode ifNotNil: [ :code | ^ code ].
					(engine hardPartialFound and: [ engine partialState isNotNil ]) ifTrue: [
							self rememberDFA: engine in: workspace.
							^ self storePartial: engine partialState mapping: mapping into: data ].
					matches ifNotEmpty: [
							(options bitAnd: PCRE2 dfaShortest) ~= 0 ifTrue: [ matches := { matches last } ].
							1 to: (matches size min: data getCount) do: [ :index |
									data offsets
										at: index * 2 - 1 put: (mapping at: candidate + 1);
										at: index * 2 put: (mapping at: (matches at: index) position + 1) ].
							data startIndex: (mapping at: candidate + 1).
							^ matches size > data getCount
								  ifTrue: [ 0 ]
								  ifFalse: [ matches size ] ] ].
			engine partialState ifNotNil: [ :partial |
					self rememberDFA: engine in: workspace.
					^ self storePartial: partial mapping: mapping into: data ].
			candidate := text nextOffsetFrom: candidate ].
	engine partialState ifNotNil: [ :partial |
			self rememberDFA: engine in: workspace.
			^ self storePartial: partial mapping: mapping into: data ].
	^ PCRE2 errorNoMatch
]

{ #category : 'substitution' }
PCRE2MatcherPharoBackend >> expand: expression match: match options: options [

	^ PCRE2ReplacementExpander new
		  expand: expression
		  backend: self
		  match: match
		  options: options
]

{ #category : 'backends' }
PCRE2MatcherPharoBackend >> family [

	^ #pharo
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> ffiLibraryName [

	PCRE2UnsupportedFeature signal: 'The Pharo backend does not use a C library'
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> finalize [

	^ self
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> firstLineEndIn: text [

	| convention offset |
	convention := PCRE2NewlineConvention new mode: newlineMode.
	offset := 0.
	[ offset < text size ] whileTrue: [
			(convention lengthAt: offset + 1 in: text) > 0 ifTrue: [ ^ offset ].
			offset := text nextOffsetFrom: offset ].
	^ text size
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> free [

	^ self
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> heapLimit [

	^ matcher context heapLimit min: (patternLimits at: #heap ifAbsent: [ matcher context heapLimit ])
]

{ #category : 'diagnostics' }
PCRE2MatcherPharoBackend >> info: option [

	option = PCRE2 infoSize ifTrue: [ ^ self compiledStorageSize ].
	option = PCRE2 infoFrameSize ifTrue: [ ^ PCRE2MatchState new sizeInMemory ].
	option = PCRE2 infoNewline ifTrue: [ ^ newlineMode ].
	option = PCRE2 infoBSR ifTrue: [ ^ bsrMode ].
	option = PCRE2 infoArgOptions ifTrue: [ ^ compileOptions ].
	option = PCRE2 infoMaxLookbehind ifTrue: [ ^ self maximumLookbehind ].
	option = PCRE2 infoCaptureCount ifTrue: [ ^ captureCount ].
	option = PCRE2 infoNameCount ifTrue: [ ^ names size ].
	option = PCRE2 infoAllOptions ifTrue: [ ^ compileOptions ].
	option = PCRE2 infoJITSize ifTrue: [ ^ 0 ].
	PCRE2UnsupportedFeature signal: 'This pattern diagnostic is specific to the FFI backend'
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> isNull [

	^ false
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> match: bytes from: start to: length options: matchOptions matchData: matchData [

	| decoded text mapping initial engine state result anchored lastIndex converted rc allowed offsetLimit candidate startPredicate required |
	allowed := PCRE2 anchored | PCRE2 endAnchored | PCRE2 notBOL | PCRE2 notEOL | PCRE2 notEmpty | PCRE2 notEmptyAtStart
	           | PCRE2 noJIT | PCRE2 noUTFCheck | PCRE2 copyMatchedSubject | PCRE2 partialSoft | PCRE2 partialHard.
	(matchOptions bitAnd: allowed bitInvert) ~= 0 ifTrue: [
		PCRE2UnsupportedFeature signal: 'Match options are not yet implemented by the Pharo backend' ].
	decoded := self textAndOffsetsFor: bytes length: length.
	text := decoded first.
	mapping := decoded second.
	initial := start.
	(start between: 0 and: text size) ifFalse: [ PCRE2MatchError signal: 'bad offset value' ].
	((matchOptions bitAnd: PCRE2 noUTFCheck) = 0 and: [ (text isBoundary: start) not ]) ifTrue: [
		PCRE2MatchError signal: 'bad UTF offset' ].
	((compileOptions bitAnd: PCRE2 noStartOptimize) = 0 and: [ (matchOptions bitAnd: PCRE2 partialSoft | PCRE2 partialHard) = 0 ])
		ifTrue: [
				required := root requiredNode.
				(required isNotNil and: [ (text anySatisfy: required predicate) not ]) ifTrue: [ ^ PCRE2 errorNoMatch ] ].
	engine := PCRE2BacktrackingMatcher new
		          subject: text
		          root: root
		          groups: groups
		          names: names
		          limit: self matchLimit;
		          depthLimit: self depthLimit;
		          heapLimit: self heapLimit;
		          initialPosition: initial;
		          matchOptions: (matchOptions bitOr: ((compileOptions bitAnd: PCRE2 endAnchored) bitOr: patternMatchOptions)).
	engine calloutBlock: matcher context backend calloutBlock mapping: mapping.
	anchored := ((matchOptions bitOr: compileOptions) bitAnd: PCRE2 anchored) ~= 0.
	offsetLimit := matcher context offsetLimit.
	offsetLimit ifNotNil: [
			(compileOptions bitAnd: PCRE2 useOffsetLimit) = 0 ifTrue: [
				PCRE2MatchError signal: 'offset limit is not enabled for this pattern' ] ].
	lastIndex := anchored
		             ifTrue: [ initial ]
		             ifFalse: [ text size ].
	offsetLimit ifNotNil: [ lastIndex := lastIndex min: offsetLimit ].
	startPredicate := ((compileOptions bitAnd: PCRE2 noStartOptimize) = 0 and: [
		                   root firstLiteral isNotNil and: [ (matchOptions bitAnd: PCRE2 partialSoft | PCRE2 partialHard) = 0 ] ])
		                  ifTrue: [ root startPredicate ].
	(compileOptions bitAnd: PCRE2 firstLine) ~= 0 ifTrue: [ lastIndex := lastIndex min: (self firstLineEndIn: text) ].
	candidate := initial.
	[ candidate <= lastIndex ] whileTrue: [
			(startPredicate isNil or: [
				 root minimumLength = 0 or: [ candidate < text size and: [ startPredicate value: (text at: candidate + 1) ] ] ]) ifTrue: [
					state := PCRE2MatchState new
						         position: candidate;
						         captures: (Array new: captureCount + 1 * 2 withAll: PCRE2 unsetOffset).
					state captures at: 1 put: candidate.
					state push: root.
					engine beginMatchAt: candidate.
					result := engine run: state.
					engine abortedCode ifNotNil: [ :code | ^ code ].
					result ifNotNil: [
							result captures at: 2 put: result position.
							converted := result captures collect: [ :offset |
									             offset = PCRE2 unsetOffset
										             ifTrue: [ offset ]
										             ifFalse: [ mapping at: offset + 1 ] ].
							rc := 1.
							1 to: captureCount do: [ :index | (converted at: index * 2 + 2) ~= PCRE2 unsetOffset ifTrue: [ rc := index + 1 ] ].
							1 to: (converted size min: matchData offsets size) do: [ :index | matchData offsets at: index put: (converted at: index) ].
							matchData
								startIndex: (mapping at: candidate + 1);
								mark: result mark.
							^ rc > matchData getCount
								  ifTrue: [ 0 ]
								  ifFalse: [ rc ] ].
					engine hardPartialFound ifTrue: [ ^ self storePartial: engine partialState mapping: mapping into: matchData ].
					engine committed ifTrue: [ ^ PCRE2 errorNoMatch ] ].
			candidate := (text nextOffsetFrom: candidate) max: (engine skipPosition ifNil: [ 0 ]) ].
	engine partialState ifNotNil: [ :partial | ^ self storePartial: partial mapping: mapping into: matchData ].
	matchData mark: engine lastMark.
	^ PCRE2 errorNoMatch
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> matchLimit [

	^ matcher context matchLimit min: (patternLimits at: #match ifAbsent: [ matcher context matchLimit ])
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> matcher: aMatcher [

	matcher := aMatcher
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> maximumLookbehind [

	^ maximumLookbehind ifNil: [ 0 ]
]

{ #category : 'backends' }
PCRE2MatcherPharoBackend >> newMatchBackend [

	^ self newMatchBackendWithOvectorSize: captureCount + 1
]

{ #category : 'backends' }
PCRE2MatcherPharoBackend >> newMatchBackendWithOvectorSize: size [

	^ PCRE2MatchPharoBackend new
		  codeUnitWidth: matcher codeUnitWidth;
		  offsets: (Array new: size * 2 withAll: PCRE2 unsetOffset)
]

{ #category : 'backends' }
PCRE2MatcherPharoBackend >> newMatchContext [

	| contextClass |
	contextClass := matcher codeUnitWidth = 8
		                ifTrue: [ PCRE2UTF8MatchContext ]
		                ifFalse: [
				                matcher codeUnitWidth = 16
					                ifTrue: [ PCRE2UTF16MatchContext ]
					                ifFalse: [ PCRE2UTF32MatchContext ] ].
	^ contextClass new backend: (PCRE2ContextPharoBackend new codeUnitWidth: matcher codeUnitWidth)
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> prepareForMatch [

	^ self
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> readNamedGroups [

	| result |
	result := Array new: captureCount.
	names keysAndValuesDo: [ :index :name | result at: index put: name ].
	^ result
]

{ #category : 'compiling' }
PCRE2MatcherPharoBackend >> recompiledBy: compiler pattern: pattern [

	^ compiler backend compilePreparedInput: (compiler preparedPatternFor: pattern)
]

{ #category : 'DFA matching' }
PCRE2MatcherPharoBackend >> rememberDFA: engine in: workspace [

	dfaStates ifNil: [ dfaStates := WeakIdentityKeyDictionary new ].
	dfaStates at: workspace put: engine restartStates.
	workspace uint32AtOffset: 0 put: 16r50435232.
	workspace uint32AtOffset: 4 put: engine restartStates size
]

{ #category : 'substitution' }
PCRE2MatcherPharoBackend >> replacementValue: name match: match options: substituteOptions [

	| value number known input |
	name isEmpty ifTrue: [ PCRE2MatchError signal: 'empty replacement reference' ].
	input := match input.
	name = '&' ifTrue: [ ^ match groupAt: 0 ].
	name = '_' ifTrue: [ ^ input readFrom: 1 to: input size ].
	name = (Character value: 96) asString ifTrue: [ ^ input readFrom: 1 to: (match startOffsetAt: 1) ].
	name = '''' ifTrue: [ ^ input readFrom: (match endOffsetAt: 1) + 1 to: input size ].
	name = '+' ifTrue: [
			value := match count > 1 ifTrue: [ match groupAt: match count - 1 ].
			value ifNotNil: [ ^ value ] ].
	name = '*MARK' ifTrue: [ ^ match mark ifNil: [ '' ] ].
	(name includes: $:) ifTrue: [ PCRE2UnsupportedFeature signal: 'Conditional replacements require extended substitution support' ].
	number := (name allSatisfy: #isDigit) ifTrue: [ name asInteger ].
	known := number ifNil: [ match namedGroups includes: name ] ifNotNil: [ number < match ovectorCount ].
	(known not and: [ (substituteOptions bitAnd: PCRE2 substituteUnknownUnset) = 0 ]) ifTrue: [
		PCRE2MatchError signal: 'unknown substring' ].
	value := known ifTrue: [ number ifNil: [ match groupNamed: name ] ifNotNil: [ match groupAt: number ] ].
	value ifNotNil: [ ^ value ].
	(substituteOptions bitAnd: PCRE2 substituteUnsetEmpty) ~= 0 ifTrue: [ ^ '' ].
	PCRE2MatchError signal: 'requested value is not set'
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> requiresSessionRestore [

	^ false
]

{ #category : 'DFA matching' }
PCRE2MatcherPharoBackend >> restartDFAFrom: workspace [

	| states |
	dfaStates ifNil: [ PCRE2MatchError signal: (PCRE2 translateErrorCode: -38) ].
	states := dfaStates removeKey: workspace ifAbsent: [ PCRE2MatchError signal: (PCRE2 translateErrorCode: -38) ].
	((workspace uint32AtOffset: 0) = 16r50435232 and: [ (workspace uint32AtOffset: 4) = states size ]) ifFalse: [
		PCRE2MatchError signal: (PCRE2 translateErrorCode: -38) ].
	^ states
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> root: aNode parser: parser [

	root := aNode.
	patternLimits := parser patternLimits.
	patternMatchOptions := parser patternMatchOptions.
	calloutSites := parser calloutSites.
	maximumLookbehind := parser maximumLookbehind.
	newlineMode := parser newlineMode.
	bsrMode := parser bsrMode.
	captureCount := parser captureCount.
	names := parser names.
	groups := parser groups
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> serialize [

	PCRE2UnsupportedFeature signal: 'C bytecode serialization is specific to the FFI backend'
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> storePartial: state mapping: mapping into: data [

	data offsets atAllPut: PCRE2 unsetOffset.
	data offsets
		at: 1 put: (mapping at: state captures first + 1);
		at: 2 put: mapping last.
	data
		startIndex: (mapping at: state captures first + 1);
		mark: state mark.
	^ PCRE2 errorPartial
]

{ #category : 'substitution' }
PCRE2MatcherPharoBackend >> substituteBytes: subject replacement: replacement options: flags matchData: data [

	| allowed matchFlags input text replacementInput expression matches replacementOnly lastEnd count stopped callback outputOffset |
	matchFlags := PCRE2 anchored | PCRE2 endAnchored | PCRE2 notBOL | PCRE2 notEOL | PCRE2 notEmpty | PCRE2 notEmptyAtStart
	              | PCRE2 noJIT.
	allowed := matchFlags | PCRE2 substituteGlobal | PCRE2 substituteLiteral | PCRE2 substituteUnsetEmpty
	           | PCRE2 substituteUnknownUnset | PCRE2 substituteReplacementOnly | PCRE2 substituteOverflowLength
	           | PCRE2 substituteExtended | PCRE2 substituteMatched.
	(flags bitAnd: allowed bitInvert) ~= 0 ifTrue: [
		PCRE2UnsupportedFeature signal: 'These substitution options are not yet implemented by the Pharo backend' ].
	input := matcher preparedInputFor: subject.
	text := input readFrom: 1 to: input size.
	text isString ifFalse: [ text := text asString ].
	replacementInput := matcher preparedInputFor: replacement.
	expression := replacementInput readFrom: 1 to: replacementInput size.
	expression isString ifFalse: [ expression := expression asString ].
	matches := self substitutionMatches: input options: flags matchData: data.
	replacementOnly := (flags bitAnd: PCRE2 substituteReplacementOnly) ~= 0.
	callback := matcher context backend substituteCalloutBlock.
	lastEnd := 0.
	count := 0.
	stopped := false.
	outputOffset := 0.
	^ String streamContents: [ :stream |
			  matches do: [ :match |
					  stopped ifFalse: [
							  | start end inserted response gap |
							  start := input characterCountUpToCodeUnitOffset: (match startOffsetAt: 1).
							  end := input characterCountUpToCodeUnitOffset: (match endOffsetAt: 1).
							  start < lastEnd ifTrue: [ PCRE2MatchError signal: 'invalid substitution match offsets' ].
							  replacementOnly ifFalse: [
									  gap := text copyFrom: lastEnd + 1 to: start.
									  stream nextPutAll: gap.
									  outputOffset := outputOffset + (matcher preparedInputFor: gap) size ].
							  inserted := (flags bitAnd: PCRE2 substituteLiteral) ~= 0
								              ifTrue: [ expression ]
								              ifFalse: [ self expand: expression match: match options: flags ].
							  count := count + 1.
							  response := 0.
							  callback ifNotNil: [
									  response := callback value: (PCRE2SubstitutionCalloutEvent new
											               match: match
											               replacement: inserted
											               count: count
											               outputStart: outputOffset
											               length: (matcher preparedInputFor: inserted) size).
									  response isInteger ifFalse: [ response := 0 ] ].
							  response = 0
								  ifTrue: [
										  stream nextPutAll: inserted.
										  outputOffset := outputOffset + (matcher preparedInputFor: inserted) size.
										  lastEnd := end ]
								  ifFalse: [
										  response < 0
											  ifTrue: [
													  stopped := true.
													  lastEnd := start ]
											  ifFalse: [
													  replacementOnly ifFalse: [
															  inserted := text copyFrom: start + 1 to: end.
															  stream nextPutAll: inserted.
															  outputOffset := outputOffset + (matcher preparedInputFor: inserted) size ].
													  lastEnd := end ] ] ] ].
			  replacementOnly ifFalse: [ stream nextPutAll: (text copyFrom: lastEnd + 1 to: text size) ] ]
]

{ #category : 'substitution' }
PCRE2MatcherPharoBackend >> substitutionMatches: input options: flags matchData: data [

	| temporary matches first count start next rc extra |
	temporary := matcher copy.
	temporary options: (flags bitAnd:
			 PCRE2 anchored | PCRE2 endAnchored | PCRE2 notBOL | PCRE2 notEOL | PCRE2 notEmpty | PCRE2 notEmptyAtStart | PCRE2 noJIT).
	(flags bitAnd: PCRE2 substituteMatched) = 0 ifTrue: [
			^ (flags bitAnd: PCRE2 substituteGlobal) ~= 0
				  ifTrue: [ temporary findAllMatches: input ]
				  ifFalse: [ (temporary findMatch: input) ifNil: [ #(  ) ] ifNotNil: [ :match | { match } ] ] ].
	data ifNil: [ PCRE2MatchError signal: 'match data is required' ].
	first := matcher matchClass new
		         backend: data copy;
		         input: input;
		         namedGroups: matcher namedGroups.
	count := 1.
	1 to: data getCount - 1 do: [ :index | (data offsets at: index * 2 + 2) ~= PCRE2 unsetOffset ifTrue: [ count := index + 1 ] ].
	first
		resultCode: count;
		count: count.
	(flags bitAnd: PCRE2 substituteGlobal) = 0 ifTrue: [ ^ { first } ].
	matches := OrderedCollection with: first.
	start := first endOffsetAt: 1.
	extra := (first startOffsetAt: 1) = start
		         ifTrue: [ PCRE2 notEmptyAtStart ]
		         ifFalse: [ 0 ].
	[ start <= input size ] whileTrue: [
			next := temporary newMatchData.
			rc := temporary
				      matchBytes: input bytes
				      from: start + 1
				      to: input size
				      options: temporary options | extra
				      into: next.
			rc = PCRE2 errorNoMatch
				ifTrue: [
						extra = 0 ifTrue: [ ^ matches ].
						start := input nextMatchStartOffsetAfter: start.
						extra := 0 ]
				ifFalse: [
						next input: input.
						matches add: next.
						start := next endOffsetAt: 1.
						extra := (next startOffsetAt: 1) = start
							         ifTrue: [ PCRE2 notEmptyAtStart ]
							         ifFalse: [ 0 ] ] ].
	^ matches
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> textAndOffsetsFor: bytes length: length [

	| input subject utf effectiveLength |
	effectiveLength := length = PCRE2 zeroTerminated
		                   ifTrue: [ self zeroTerminatedLength: bytes ]
		                   ifFalse: [ length ].
	(effectiveLength < 0 or: [ effectiveLength > (bytes size // matcher codeUnitByteSize) ]) ifTrue: [
		PCRE2MatchError signal: 'bad subject length' ].
	input := matcher preparedInputFor: (bytes copyFrom: 1 to: effectiveLength * matcher codeUnitByteSize).
	utf := (compileOptions bitAnd: PCRE2 utf) ~= 0.
	utf ifTrue: [ PCRE2CodeUnitText validateUTF: input bytes width: self codeUnitWidth ].
	subject := PCRE2SubjectText new bytes: input bytes width: self codeUnitWidth utf: utf.
	^ {
		  subject.
		  (0 to: subject size) }
]

{ #category : 'substitution' }
PCRE2MatcherPharoBackend >> transformCase: text mode: mode [

	| block event answer unicode |
	block := matcher context backend substituteCaseCalloutBlock.
	block ifNotNil: [
			event := PCRE2SubstitutionCaseCalloutEvent new
				         inputText: text
				         length: (matcher preparedInputFor: text) size
				         capacity: (matcher preparedInputFor: text) size
				         caseType: (mode = #upper
						          ifTrue: [ PCRE2 substituteCaseUpper ]
						          ifFalse: [ PCRE2 substituteCaseLower ])
				         codeUnitWidth: self codeUnitWidth.
			answer := block value: event.
			answer ifNil: [ PCRE2MatchError signal: (PCRE2 translateErrorCode: PCRE2 errorReplaceCase) ].
			^ answer isString
				  ifTrue: [ answer ]
				  ifFalse: [ event defaultTransformedText ] ].
	unicode := (compileOptions bitAnd: PCRE2 utf | PCRE2 ucp) ~= 0.
	^ text collect: [ :character | PCRE2UnicodeData case: character upper: mode = #upper unicode: unicode ]
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> zeroTerminatedLength: bytes [

	| width |
	width := matcher codeUnitByteSize.
	1 to: bytes size - width + 1 by: width do: [ :index |
		((index to: index + width - 1) allSatisfy: [ :offset | (bytes at: offset) asInteger = 0 ]) ifTrue: [ ^ index - 1 // width ] ].
	^ bytes size // width
]
