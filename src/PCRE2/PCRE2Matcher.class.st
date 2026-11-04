"
A compiled regular expression, with methods for matching, capture queries, enumeration, splitting, and substitution. Its backend, fixed at compilation, owns the compiled state and any external resources.
"
Class {
	#name : 'PCRE2Matcher',
	#superclass : 'Object',
	#traits : 'PCRE2TWithOptions',
	#instVars : [
		'pattern',
		'context',
		'compiler',
		'isJIT',
		'options',
		'nameTable',
		'backend',
		'patternInput',
		'lastMatch',
		'lastStream'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'testing' }
PCRE2Matcher class >> isAbstract [

	^ self == PCRE2Matcher
]

{ #category : 'documentation' }
PCRE2Matcher >> allInfo [
	"Use `PCRE2 allInfoOnRegex:` for a human-readable format"

	^ (0 to: 26) collect: [ :i | self info: i ]
]

{ #category : 'external resource management' }
PCRE2Matcher >> autoRelease [

	backend autoRelease
]

{ #category : 'accessing' }
PCRE2Matcher >> backend [

	^ backend
]

{ #category : 'accessing' }
PCRE2Matcher >> backend: anImplementation [

	backend ifNotNil: [ PCRE2Error signal: 'Compile a new matcher to select a different backend' ].
	self initializeBackend: anImplementation
]

{ #category : 'documentation' }
PCRE2Matcher >> calloutSites [
	"Answer the static callout sites compiled into this pattern, without installing a callout or affecting matching."

	| sites |
	sites := OrderedCollection new.
	self calloutSitesDo: [ :site | sites add: site ].
	^ sites asArray
]

{ #category : 'callouts' }
PCRE2Matcher >> calloutSitesDo: aBlock [

	backend calloutSitesDo: aBlock
]

{ #category : 'private' }
PCRE2Matcher >> canUseJITForOptions: matchOptions [
	"Answer whether the pattern has JIT code for the requested matching mode. The jit_match() fast path does not fall back when that mode was not JIT-compiled."

	isJIT ifFalse: [ ^ false ].
	(matchOptions bitAnd: PCRE2 noJIT) ~~ 0 ifTrue: [ ^ false ].
	(matchOptions bitAnd: PCRE2 partialHard) ~~ 0 ifTrue: [ ^ (compiler optionsJIT bitAnd: PCRE2 jitPartialHard) ~~ 0 ].
	(matchOptions bitAnd: PCRE2 partialSoft) ~~ 0 ifTrue: [ ^ (compiler optionsJIT bitAnd: PCRE2 jitPartialSoft) ~~ 0 ].
	^ (compiler optionsJIT bitAnd: PCRE2 jitComplete) ~~ 0
]

{ #category : 'private' }
PCRE2Matcher >> codeUnitByteSize [

	^ self codeUnitWidth // 8
]

{ #category : 'documentation' }
PCRE2Matcher >> codeUnitWidth [

	self subclassResponsibility
]

{ #category : 'compiling' }
PCRE2Matcher >> compileJIT [
	"Request JIT compilation using the compiler options. Patterns are JIT-compiled by default when supported."

	compiler compileJIT: self
]

{ #category : 'compiling' }
PCRE2Matcher >> compileJIT: anInteger [
	"Request JIT (re-)compilation for this compiled pattern."

	| newCompiler |
	newCompiler := self compilerClass new backend: compiler backend class.
	compiler copyContextIfPresent ifNotNil: [ :contextCopy | newCompiler context: contextCopy ].
	newCompiler
		options: compiler options;
		optionsJIT: anInteger;
		compileJIT: self.
	compiler := newCompiler
]

{ #category : 'accessing' }
PCRE2Matcher >> compiler [

	^ compiler
]

{ #category : 'accessing' }
PCRE2Matcher >> compiler: aPCRE2Compiler [
	"Should only be used by the compiler that processed this pattern"

	compiler := aPCRE2Compiler
]

{ #category : 'private' }
PCRE2Matcher >> compilerClass [

	self subclassResponsibility
]

{ #category : 'accessing' }
PCRE2Matcher >> context [

	^ context ifNil: [ context := backend newMatchContext ]
]

{ #category : 'accessing' }
PCRE2Matcher >> context: aMatchContext [

	aMatchContext ifNotNil: [
			(aMatchContext isKindOf: PCRE2MatchContext) ifFalse: [ PCRE2Error signal: 'Expected a match context' ].
			(aMatchContext backend family = backend family and: [ aMatchContext backend codeUnitWidth = self codeUnitWidth ]) ifFalse: [
				PCRE2Error signal: 'Match context must use the same backend and code-unit width as the matcher' ] ].
	context := aMatchContext
]

{ #category : 'match enumeration' }
PCRE2Matcher >> copy: subject matchesDo: aBlock [
	"Copy the subject, evaluating aBlock for each match with the output stream, the raw subject bytes, and the 1-based byte bounds of the match."

	| bytesPerCodeUnit input lastByteIndex rs ws |
	input := self preparedInputFor: subject.
	bytesPerCodeUnit := self codeUnitByteSize.
	lastByteIndex := 0.
	rs := ReadStream on: input bytes.
	ws := WriteStream on: (String new: 100).
	self
		matchAll: input
		from: 1
		to: input size
		do: [ :match |
				| byteEnd byteStart startOffset |
				startOffset := match startOffsetAt: 1.
				byteStart := startOffset * bytesPerCodeUnit.
				byteEnd := (match endOffsetAt: 1) * bytesPerCodeUnit.
				rs position: lastByteIndex.
				[ rs position < byteStart ] whileTrue: [ ws nextPut: (input nextFromStream: rs) ].
				aBlock
					value: ws
					value: input bytes
					value: byteStart + 1
					value: byteEnd.
				lastByteIndex := byteEnd ].

	rs position: lastByteIndex.
	[ rs atEnd ] whileFalse: [ ws nextPut: (input nextFromStream: rs) ].
	^ ws contents
]

{ #category : 'match enumeration' }
PCRE2Matcher >> copy: subject replacingMatchesWith: aString [

	^ self copy: subject matchesDo: [ :ws :utfSubject :start :end | ws nextPutAll: aString ]
]

{ #category : 'match enumeration' }
PCRE2Matcher >> copy: subject translatingMatchesUsing: aBlock [
	"Copy the subject, replacing each match with aBlock's String answer for the matched substring."

	| input |
	input := self preparedInputFor: subject.
	^ self
		  copy: input
		  matchesDo: [ :ws :utfSubject :start :end |
		  ws nextPutAll: (aBlock value: (input decodeBytes: (utfSubject copyFrom: start to: end))) ]
]

{ #category : 'match enumeration' }
PCRE2Matcher >> copyStream: aStream to: aWriteStream replacingMatchesWith: aString [
	"Equivalent of RxMatcher >> #copyStream:to:replacingMatchesWith:, on what is left of the stream."

	aWriteStream nextPutAll: (self copy: aStream upToEnd replacingMatchesWith: aString)
]

{ #category : 'match enumeration' }
PCRE2Matcher >> copyStream: aStream to: aWriteStream translatingMatchesUsing: aBlock [
	"Equivalent of RxMatcher >> #copyStream:to:translatingMatchesUsing:, on what is left of the stream."

	aWriteStream nextPutAll: (self copy: aStream upToEnd translatingMatchesUsing: aBlock)
]

{ #category : 'copying' }
PCRE2Matcher >> copyWithCharacterTables [

	| copy |
	copy := self shallowCopy.
	copy initializeBackend: backend copyWithCharacterTables.
	copy
		initialize;
		options: self options.
	^ copy restoreJITIfNeeded
]

{ #category : 'error handling' }
PCRE2Matcher >> errorCode: errorCode [

	<debuggerCompleteToSender>
	PCRE2MatchError signal: (PCRE2 translateErrorCode: errorCode)
]

{ #category : 'accessing' }
PCRE2Matcher >> existingContext [

	^ context
]

{ #category : 'library path' }
PCRE2Matcher >> ffiLibraryName [

	^ backend ffiLibraryName
]

{ #category : 'finalization' }
PCRE2Matcher >> finalize [

	backend finalize
]

{ #category : 'matching' }
PCRE2Matcher >> find: subject [
	"Returns the first matching substring within the subject."

	^ (self findMatch: subject) ifNotNil: [ :match | match readMatch ]
]

{ #category : 'callouts' }
PCRE2Matcher >> find: subject calloutsDo: calloutBlock [
	"Answer the first matching substring while invoking calloutBlock for runtime PCRE2 callouts."

	^ self withCallout: calloutBlock do: [ :callbackMatcher | callbackMatcher find: subject ]
]

{ #category : 'match enumeration' }
PCRE2Matcher >> findAll: subject [
	"Returns all matching substrings within the subject."

	| input result |
	result := OrderedCollection new.
	input := self preparedInputFor: subject.
	self
		matchAll: input
		from: 1
		to: input size
		do: [ :match | result add: match readMatch ].
	^ result
]

{ #category : 'callouts' }
PCRE2Matcher >> findAll: subject calloutsDo: calloutBlock [
	"Answer all matching substrings while invoking calloutBlock for runtime PCRE2 callouts."

	^ self withCallout: calloutBlock do: [ :callbackMatcher | callbackMatcher findAll: subject ]
]

{ #category : 'match enumeration' }
PCRE2Matcher >> findAll: subject do: aBlock [
	"Iterate over all matching substrings within the subject."

	| input |
	input := self preparedInputFor: subject.
	self
		matchAll: input
		from: 1
		to: input size
		do: [ :match | aBlock value: match readMatch ]
]

{ #category : 'match enumeration' }
PCRE2Matcher >> findAllMatches: subject [
	"Answer all PCRE2Match objects within the subject."

	| input result |
	result := OrderedCollection new.
	input := self preparedInputFor: subject.
	self
		matchAll: input
		from: 1
		to: input size
		do: [ :match | result add: match ].
	^ result
]

{ #category : 'match enumeration' }
PCRE2Matcher >> findAllMatches: subject do: aBlock [
	"Evaluate aBlock with each PCRE2Match object within the subject."

	| input |
	input := self preparedInputFor: subject.
	self
		matchAll: input
		from: 1
		to: input size
		do: aBlock
]

{ #category : 'match enumeration' }
PCRE2Matcher >> findAllWithGroups: subject [
	"Returns all matching substrings and groups within the subject."

	| input result |
	result := OrderedCollection new.
	input := self preparedInputFor: subject.
	self
		matchAll: input
		from: 1
		to: input size
		do: [ :match | result add: match readMatches ].
	^ result
]

{ #category : 'matching' }
PCRE2Matcher >> findHardPartialMatch: subject [
	"Answer the first complete or hard-partial match in subject, or nil. Hard partial matching prefers a partial match when adding more subject could change a complete match."

	^ self findPartialMatch: subject option: PCRE2 partialHard
]

{ #category : 'matching' }
PCRE2Matcher >> findMatch: subject [
	"Returns standalone match data for the first matching substring, or nil."

	| input match |
	input := self preparedInputFor: subject.
	match := self matchBytes: input bytes from: 1 to: input size.
	match ifNotNil: [ match input: input ].
	^ match
]

{ #category : 'callouts' }
PCRE2Matcher >> findMatch: subject calloutsDo: calloutBlock [
	"Answer the first match while invoking calloutBlock for runtime PCRE2 callouts."

	^ self withCallout: calloutBlock do: [ :callbackMatcher | callbackMatcher findMatch: subject ]
]

{ #category : 'matching' }
PCRE2Matcher >> findPartialMatch: subject [
	"Answer the first complete or soft-partial match in subject, or nil. Soft partial matching prefers a complete match."

	^ self findPartialMatch: subject option: PCRE2 partialSoft
]

{ #category : 'matching' }
PCRE2Matcher >> findPartialMatch: subject option: partialOption [
	"Answer the first complete or partial match using partialOption, or nil."

	| input match matchOptions rc |
	matchOptions := self optionsWithPartialOption: partialOption.
	input := self preparedInputFor: subject.
	match := self newMatchData.
	rc := self
		      matchBytes: input bytes
		      from: 1
		      to: input size
		      options: matchOptions
		      into: match.
	rc == PCRE2 errorNoMatch ifTrue: [ ^ nil ].
	match input: input.
	^ match
]

{ #category : 'matching' }
PCRE2Matcher >> findSoftPartialMatch: subject [
	"Answer the first complete or soft-partial match in subject, or nil. Soft partial matching prefers a complete match."

	^ self findPartialMatch: subject option: PCRE2 partialSoft
]

{ #category : 'matching' }
PCRE2Matcher >> findWithGroups: subject [
	"Returns the first matching substring and groups within the subject."

	^ (self findMatch: subject) ifNil: [ #(  ) ] ifNotNil: [ :match | match readMatches ]
]

{ #category : 'external resource management' }
PCRE2Matcher >> free [

	backend free
]

{ #category : 'private' }
PCRE2Matcher >> getHandle [

	^ backend getHandle
]

{ #category : 'documentation' }
PCRE2Matcher >> info: option [

	^ backend info: option
]

{ #category : 'initialization' }
PCRE2Matcher >> initialize [

	options := 0
]

{ #category : 'private' }
PCRE2Matcher >> initializeBackend: anImplementation [

	backend := anImplementation.
	backend matcher: self
]

{ #category : 'testing' }
PCRE2Matcher >> isJIT [

	^ isJIT = true
]

{ #category : 'accessing' }
PCRE2Matcher >> isJIT: aBoolean [
	"Set whether the pattern is used as JIT-compiled. False forces match() over the jit_match() fast path, for its validity checks; true for a pattern that is not JIT-compiled makes matches fail."

	isJIT := aBoolean and: [ compiler optionsJIT ~~ 0 ]
]

{ #category : 'testing' }
PCRE2Matcher >> isNull [

	^ backend isNull
]

{ #category : 'private' }
PCRE2Matcher >> jitMatch: subject from: start to: end options: matchOptions matchData: matchData [

	^ backend
		  prepareForMatch;
		  jitMatch: subject
		  from: start
		  to: end
		  options: matchOptions
		  matchData: matchData backend
]

{ #category : 'accessing' }
PCRE2Matcher >> lastChar [
	"Equivalent of RxMatcher >> #lastChar: the character before the position of the last matched stream, or nil."

	^ lastStream ifNotNil: [ :aStream |
			  aStream position > 0 ifTrue: [
					  aStream
						  skip: -1;
						  next ] ]
]

{ #category : 'accessing' }
PCRE2Matcher >> lastResult [
	"Equivalent of RxMatcher >> #lastResult. Answers whether the last match attempt succeeded."

	^ lastMatch isNotNil
]

{ #category : 'querying' }
PCRE2Matcher >> mark [
	"Matchers no longer keep the last match. Query mark on the returned PCRE2Match."

	self error: 'PCRE2Matcher no longer keeps the last match; query mark on the returned PCRE2Match'
]

{ #category : 'private' }
PCRE2Matcher >> match: subject from: start to: end options: matchOptions matchData: matchData [

	matchData invalidateResult.
	^ backend
		  prepareForMatch;
		  match: subject
		  from: start
		  to: end
		  options: matchOptions
		  matchData: matchData backend
]

{ #category : 'match enumeration' }
PCRE2Matcher >> matchAll: input from: start to: end do: aBlock [
	"Match repeatedly over prepared input, evaluating aBlock with each match. An empty match advances by one character of the input."

	self
		matchAllBytes: input bytes
		from: start
		to: end
		advancingEmptyMatchesWith: [ :offset | input nextMatchStartOffsetAfter: offset ]
		do: [ :match |
				match input: input.
				aBlock cull: match ]
]

{ #category : 'prepared matching' }
PCRE2Matcher >> matchAllBytes: subject from: start to: end advancingEmptyMatchesWith: nextStartBlock do: aBlock [
	"Iterate like pcre2_next_match(), using nextStartBlock to advance after an empty match that has no consuming alternative."

	| extraOptions match offset retryingEmpty subjectEnd |
	offset := start - 1.
	subjectEnd := end.
	extraOptions := 0.
	retryingEmpty := false.
	[ offset <= subjectEnd ] whileTrue: [
			| rc |
			match := self newMatchData.
			rc := self
				      matchBytes: subject
				      from: offset + 1
				      to: subjectEnd
				      options: options | extraOptions
				      into: match.
			rc == PCRE2 errorNoMatch
				ifTrue: [
						retryingEmpty ifFalse: [ ^ self ].
						offset := nextStartBlock value: offset.
						extraOptions := 0.
						retryingEmpty := false ]
				ifFalse: [
						| endOffset offsets |
						offsets := match offsetsAt: 1.
						aBlock cull: match.
						endOffset := offsets second.
						offset := endOffset.
						retryingEmpty := offsets first = endOffset.
						extraOptions := retryingEmpty
							                ifTrue: [ PCRE2 notEmptyAtStart ]
							                ifFalse: [ 0 ] ] ]
]

{ #category : 'prepared matching' }
PCRE2Matcher >> matchAllBytes: subject from: start to: end do: aBlock [
	"Match repeatedly over raw code-unit storage, evaluating aBlock with each match. Empty matches retry with PCRE2_NOTEMPTY_ATSTART before advancing by one code unit."

	self
		matchAllBytes: subject
		from: start
		to: end
		advancingEmptyMatchesWith: [ :offset | offset + 1 ]
		do: [ :match |
				match subject: subject decoder: nil.
				aBlock cull: match ]
]

{ #category : 'prepared matching' }
PCRE2Matcher >> matchAllBytes: subject from: start to: end offsetsDo: aBlock [
	"Match repeatedly over an inclusive 1-based code-unit range, evaluating aBlock with the raw offsets of each match."

	self
		matchAllBytes: subject
		from: start
		to: end
		do: [ :match | aBlock value: match offsets ]
]

{ #category : 'prepared matching' }
PCRE2Matcher >> matchBytes: subject from: start to: end [
	"Match over an inclusive 1-based code-unit range of prepared storage; answer the match, or nil."

	| match rc |
	match := self newMatchData.
	rc := self
		      matchBytes: subject
		      from: start
		      to: end
		      into: match.
	rc == PCRE2 errorNoMatch ifTrue: [ ^ nil ].
	match subject: subject decoder: nil.
	^ match
]

{ #category : 'callouts' }
PCRE2Matcher >> matchBytes: subject from: start to: end calloutsDo: calloutBlock [
	"Run a byte-level match while invoking calloutBlock for runtime PCRE2 callouts."

	^ self withCallout: calloutBlock do: [ :callbackMatcher | callbackMatcher matchBytes: subject from: start to: end ]
]

{ #category : 'prepared matching' }
PCRE2Matcher >> matchBytes: subject from: start to: end into: aPCRE2Match [
	"Match over an inclusive 1-based code-unit range of prepared storage, into the given match data."

	^ self
		  matchBytes: subject
		  from: start
		  to: end
		  options: options
		  into: aPCRE2Match
]

{ #category : 'prepared matching' }
PCRE2Matcher >> matchBytes: subject from: start to: end options: matchOptions into: aPCRE2Match [
	"Match over an inclusive 1-based code-unit range of prepared storage with matchOptions, into the given match data."

	| rc |
	self validateUsableMatchData: aPCRE2Match.
	aPCRE2Match reset.
	aPCRE2Match namedGroups: self namedGroups.

	rc := (self canUseJITForOptions: matchOptions)
		      ifFalse: [
				      self
					      match: subject
					      from: start - 1
					      to: end
					      options: matchOptions
					      matchData: aPCRE2Match ]
		      ifTrue: [
				      self
					      jitMatch: subject
					      from: start - 1
					      to: end
					      options: matchOptions
					      matchData: aPCRE2Match ].

	^ self recordMatchResult: rc in: aPCRE2Match
]

{ #category : 'private' }
PCRE2Matcher >> matchClass [

	self subclassResponsibility
]

{ #category : 'private' }
PCRE2Matcher >> matchContextClass [

	^ self subclassResponsibility
]

{ #category : 'accessing' }
PCRE2Matcher >> matchData [
	"Matchers no longer own match data. Use findMatch: or matchBytes:from:to: and query the returned PCRE2Match."

	self error: 'PCRE2Matcher no longer keeps match data; query the PCRE2Match returned by a match operation'
]

{ #category : 'accessing' }
PCRE2Matcher >> matchData: aPCRE2Match [
	"Matchers no longer own match data. Reuse match data with matchBytes:from:to:into:."

	self error: 'PCRE2Matcher no longer accepts stored match data; pass it to a match operation instead'
]

{ #category : 'matching' }
PCRE2Matcher >> matches: subject [
	"Returns whether the regex fully matches the subject."

	| input match |
	input := self preparedInputFor: subject.
	match := self matchBytes: input bytes from: 1 to: input size.
	(match isNil or: [ match isPartial ]) ifTrue: [ ^ self rememberMatch: nil ].
	match input: input.
	match offsetsDo: [ :start :end | ^ self rememberMatch: ((start == 1 and: [ end == input size ]) ifTrue: [ match ]) ].
	^ self rememberMatch: nil
]

{ #category : 'callouts' }
PCRE2Matcher >> matches: subject calloutsDo: calloutBlock [
	"Answer whether the subject is fully matched while invoking calloutBlock for runtime PCRE2 callouts."

	^ self withCallout: calloutBlock do: [ :callbackMatcher | callbackMatcher matches: subject ]
]

{ #category : 'match enumeration' }
PCRE2Matcher >> matchesIn: subject [
	"Equivalent of RxMatcher >> #matchesIn:"

	^ self findAll: subject
]

{ #category : 'match enumeration' }
PCRE2Matcher >> matchesIn: subject collect: aBlock [
	"Equivalent of RxMatcher >> #matchesIn:collect:"

	| result |
	result := OrderedCollection new.
	self findAll: subject do: [ :match | result add: (aBlock value: match) ].
	^ result
]

{ #category : 'match enumeration' }
PCRE2Matcher >> matchesIn: subject do: aBlock [
	"Equivalent of RxMatcher >> #matchesIn:do:"

	self findAll: subject do: aBlock
]

{ #category : 'match enumeration' }
PCRE2Matcher >> matchesOnStream: aStream [
	"Equivalent of RxMatcher >> #matchesOnStream:."

	| result |
	result := OrderedCollection new.
	self matchesOnStream: aStream do: [ :match | result add: match ].
	^ result
]

{ #category : 'match enumeration' }
PCRE2Matcher >> matchesOnStream: aStream collect: aBlock [
	"Equivalent of RxMatcher >> #matchesOnStream:collect:."

	| result |
	result := OrderedCollection new.
	self matchesOnStream: aStream do: [ :match | result add: (aBlock value: match) ].
	^ result
]

{ #category : 'match enumeration' }
PCRE2Matcher >> matchesOnStream: aStream do: aBlock [
	"Equivalent of RxMatcher >> #matchesOnStream:do:. Leaves the stream at its end; the subexpression accessors report on each match while aBlock runs."

	lastStream := aStream.
	self findAllMatches: aStream upToEnd do: [ :match |
			self rememberMatch: match.
			aBlock value: match readMatch ]
]

{ #category : 'matching' }
PCRE2Matcher >> matchesPrefix: subject [
	"Returns whether the regex completely matches the start of the subject."

	| input match |
	input := self preparedInputFor: subject.
	match := self matchBytes: input bytes from: 1 to: input size.
	(match isNil or: [ match isPartial ]) ifTrue: [ ^ self rememberMatch: nil ].
	match input: input.
	match offsetsDo: [ :start :end | ^ self rememberMatch: (start == 1 ifTrue: [ match ]) ].
	^ self rememberMatch: nil
]

{ #category : 'callouts' }
PCRE2Matcher >> matchesPrefix: subject calloutsDo: calloutBlock [
	"Answer whether the subject prefix matches while invoking calloutBlock for runtime PCRE2 callouts."

	^ self withCallout: calloutBlock do: [ :callbackMatcher | callbackMatcher matchesPrefix: subject ]
]

{ #category : 'matching' }
PCRE2Matcher >> matchesStream: aStream [
	"Equivalent of RxMatcher >> #matchesStream:."

	^ (self matchesStreamPrefix: aStream) and: [ aStream atEnd ]
]

{ #category : 'matching' }
PCRE2Matcher >> matchesStreamPrefix: aStream [
	"Equivalent of RxMatcher >> #matchesStreamPrefix:. Leaves a positionable stream just after the match, or where it was when there is none."

	| start |
	lastStream := aStream.
	start := aStream position.
	(self matchesPrefix: aStream upToEnd) ifFalse: [
			aStream position: start.
			^ false ].
	aStream position: start + (self subEnd: 1) first.
	^ true
]

{ #category : 'match enumeration' }
PCRE2Matcher >> matchingRangesIn: subject [
	"Answer ranges of each match as 1-based Pharo character intervals."

	| input ranges |
	input := self preparedInputFor: subject.
	ranges := OrderedCollection new.
	self
		matchAll: input
		from: 1
		to: input size
		do: [ :match |
				| offsets |
				offsets := match offsetsAt: 1.
				ranges add: (input characterRangeFromStartOffset: offsets first endOffset: offsets second) ].
	^ ranges
]

{ #category : 'documentation' }
PCRE2Matcher >> namedGroups [
	"Answer a sparse Array mapping capture group numbers to their names; group 0, the whole match, is unnamed. With dupNames, a name can appear at several indexes."

	^ nameTable ifNil: [ nameTable := self readNamedGroups ]
]

{ #category : 'external resource management' }
PCRE2Matcher >> newMatchData [

	^ self matchClass new backend: backend newMatchBackend
]

{ #category : 'external resource management' }
PCRE2Matcher >> newMatchDataWithOvectorSize: size [

	^ self matchClass new backend: (backend newMatchBackendWithOvectorSize: size)
]

{ #category : 'private' }
PCRE2Matcher >> optionsWithPartialOption: partialOption [
	"Answer my match options with exactly the requested partial-matching mode."

	self validatePartialOption: partialOption.
	^ (options bitAnd: (PCRE2 partialSoft | PCRE2 partialHard) bitInvert) bitOr: partialOption
]

{ #category : 'accessing' }
PCRE2Matcher >> pattern [

	^ pattern
]

{ #category : 'accessing' }
PCRE2Matcher >> pattern: aString [
	"Must only be used by the compiler."

	pattern := aString.
	nameTable := nil
]

{ #category : 'private' }
PCRE2Matcher >> patternInput [

	^ patternInput ifNil: [ compiler preparedPatternFor: pattern ]
]

{ #category : 'private' }
PCRE2Matcher >> patternInput: anInput [

	patternInput := anInput
]

{ #category : 'copying' }
PCRE2Matcher >> postCopy [

	backend := backend copy matcher: self.
	self initialize.
	self restoreJITIfNeeded
]

{ #category : 'persistence' }
PCRE2Matcher >> prepareForShutdown [
	"PCRE2SessionManager restores the native handle. The rest survives the image save, and native-derived metadata such as namedGroups is recomputed when needed."

	^ self
]

{ #category : 'private' }
PCRE2Matcher >> preparedInputFor: aStringOrInput [

	self subclassResponsibility
]

{ #category : 'private' }
PCRE2Matcher >> rangeOfSubexpression: subIndex [
	"Answer the 1-based Pharo character range the subexpression last matched, or nil when it did not take part. Index 1 is the whole match, as in RxMatcher."

	| offsets |
	lastMatch ifNil: [ ^ nil ].
	(subIndex between: 1 and: lastMatch count) ifFalse: [ ^ nil ].
	offsets := lastMatch offsetsAt: subIndex.
	"unsetOffset is larger than a SmallInteger, so this comparison cannot be an identity test"
	offsets first = PCRE2 unsetOffset ifTrue: [ ^ nil ].
	^ lastMatch input characterRangeFromStartOffset: offsets first endOffset: offsets second
]

{ #category : 'private' }
PCRE2Matcher >> readNamedGroups [

	^ backend readNamedGroups
]

{ #category : 'persistence' }
PCRE2Matcher >> recompile [

	self initializeBackend: (backend recompiledBy: compiler pattern: self patternInput).
	self restoreJITIfNeeded
]

{ #category : 'private' }
PCRE2Matcher >> recordMatchResult: rc in: aPCRE2Match [

	aPCRE2Match resultCode: rc.
	rc > 0 ifTrue: [
			aPCRE2Match count: rc.
			^ rc ].

	rc == PCRE2 errorPartial ifTrue: [
			aPCRE2Match count: 1.
			^ rc ].

	aPCRE2Match count: 0.
	rc == PCRE2 errorNoMatch ifTrue: [ ^ rc ].

	rc == 0 ifTrue: [ PCRE2Error signal: 'Not enough memory in match structure to store results' ].

	self errorCode: rc
]

{ #category : 'private' }
PCRE2Matcher >> rememberMatch: aMatchOrNil [
	"Keep the match that the RxMatcher-compatible accessors report on, and answer whether there was one."

	lastMatch := aMatchOrNil.
	^ aMatchOrNil isNotNil
]

{ #category : 'persistence' }
PCRE2Matcher >> restoreFrom: bytes [

	backend restoreFrom: bytes
]

{ #category : 'persistence' }
PCRE2Matcher >> restoreJITIfNeeded [
	"Serialized and copied PCRE2 code has no JIT data. Rebuild it, keeping the pattern usable without JIT if that fails."

	self isJIT ifFalse: [ ^ self ].
	compiler compileJIT: self onError: [ :rc | self isJIT: false ]
]

{ #category : 'matching' }
PCRE2Matcher >> search: subject [
	"Returns whether the regex matches anywhere in the subject."

	^ self rememberMatch: (self findMatch: subject)
]

{ #category : 'callouts' }
PCRE2Matcher >> search: subject calloutsDo: calloutBlock [
	"Answer whether the subject contains a match while invoking calloutBlock for runtime PCRE2 callouts."

	^ self withCallout: calloutBlock do: [ :callbackMatcher | callbackMatcher search: subject ]
]

{ #category : 'matching' }
PCRE2Matcher >> searchStream: aStream [
	"Equivalent of RxMatcher >> #searchStream:. Leaves a positionable stream just after the match, or at its end when there is none."

	| start |
	lastStream := aStream.
	start := aStream position.
	(self search: aStream upToEnd) ifFalse: [ ^ false ].
	aStream position: start + (self subEnd: 1) first.
	^ true
]

{ #category : 'persistence' }
PCRE2Matcher >> serialize [

	^ backend serialize
]

{ #category : 'private' }
PCRE2Matcher >> setHandle: anAddress [

	backend setHandle: anAddress
]

{ #category : 'splitjoin' }
PCRE2Matcher >> split: subject indicesDo: aBlock [
	"Split subject on consuming matches, evaluating aBlock with each kept 1-based Pharo character range."

	| input lastEndCharacterCount lastEndOffset match nextStart subjectEnd |
	input := self preparedInputFor: subject.
	lastEndOffset := 0.
	lastEndCharacterCount := 0.
	nextStart := 1.
	subjectEnd := input characterCountUpToCodeUnitOffset: input size.
	[ nextStart <= (input size + 1) and: [ (match := self matchBytes: input bytes from: nextStart to: input size) isNotNil ] ]
		whileTrue: [
				| endCharacterCount endOffset offsets startCharacterCount startOffset |
				offsets := match offsetsAt: 1.
				startOffset := offsets first.
				endOffset := offsets second.
				[ startOffset < endOffset ] assertWithDescription: 'Regex cannot match null string'.
				startCharacterCount := input
					                       characterCountUpToCodeUnitOffset: startOffset
					                       fromCodeUnitOffset: lastEndOffset
					                       characterCount: lastEndCharacterCount.
				aBlock value: lastEndCharacterCount + 1 value: startCharacterCount.
				endCharacterCount := input
					                     characterCountUpToCodeUnitOffset: endOffset
					                     fromCodeUnitOffset: startOffset
					                     characterCount: startCharacterCount.
				lastEndOffset := endOffset.
				lastEndCharacterCount := endCharacterCount.
				nextStart := endOffset + 1 ].
	aBlock value: lastEndCharacterCount + 1 value: subjectEnd
]

{ #category : 'querying' }
PCRE2Matcher >> startIndex [
	"Matchers no longer keep the last match. Query startIndex on the returned PCRE2Match."

	self error: 'PCRE2Matcher no longer keeps the last match; query startIndex on the returned PCRE2Match'
]

{ #category : 'private' }
PCRE2Matcher >> stringOfSubexpression: subIndex [
	"Answer what the subexpression last matched, or nil when it did not take part. Index 1 is the whole match, as in RxMatcher."

	(self rangeOfSubexpression: subIndex) ifNil: [ ^ nil ].
	^ subIndex == 1
		  ifTrue: [ lastMatch readMatch ]
		  ifFalse: [ lastMatch groupAt: subIndex - 1 ]
]

{ #category : 'accessing' }
PCRE2Matcher >> subBeginning: subIndex [
	"Equivalent of RxMatcher >> #subBeginning:. The array holds at most one 0-based character position, since PCRE2 keeps only the last match of a subexpression."

	^ (self rangeOfSubexpression: subIndex) ifNil: [ #(  ) ] ifNotNil: [ :range | Array with: range first - 1 ]
]

{ #category : 'accessing' }
PCRE2Matcher >> subEnd: subIndex [
	"Equivalent of RxMatcher >> #subEnd:. The array holds the 0-based character position after the last match of the subexpression, or is empty when it did not take part."

	^ (self rangeOfSubexpression: subIndex) ifNil: [ #(  ) ] ifNotNil: [ :range | Array with: range last ]
]

{ #category : 'accessing' }
PCRE2Matcher >> subexpression: subIndex [
	"Equivalent of RxMatcher >> #subexpression:."

	^ self stringOfSubexpression: subIndex
]

{ #category : 'accessing' }
PCRE2Matcher >> subexpressionCount [
	"Equivalent of RxMatcher >> #subexpressionCount. The whole match counts as the first subexpression, as it does in Rx."

	^ (self info: PCRE2 infoCaptureCount) + 1
]

{ #category : 'accessing' }
PCRE2Matcher >> subexpressions: subIndex [
	"Equivalent of RxMatcher >> #subexpressions:. PCRE2 keeps only the last match of a subexpression, so the answer holds at most one string."

	^ (self stringOfSubexpression: subIndex) ifNil: [ #(  ) ] ifNotNil: [ :string | Array with: string ]
]

{ #category : 'testing' }
PCRE2Matcher >> supportsSubexpressions [
	"Equivalent of RxMatcher >> #supportsSubexpressions."

	^ true
]

{ #category : 'private' }
PCRE2Matcher >> temporaryMatcherAddingCompileOptions: compileOptions matchOptions: matchOptions [
	"Answer a matcher compiled from my source with additional options, leaving me unchanged."

	| sourceCompiler temporaryCompiler temporaryMatcher |
	sourceCompiler := compiler ifNil: [ self compilerClass new ].
	temporaryCompiler := self compilerClass new backend: sourceCompiler backend class.
	sourceCompiler copyContextIfPresent ifNotNil: [ :contextCopy | temporaryCompiler context: contextCopy ].
	temporaryCompiler
		options: (sourceCompiler options bitOr: compileOptions);
		optionsJIT: sourceCompiler optionsJIT.
	temporaryMatcher := temporaryCompiler compile: self patternInput.
	temporaryMatcher options: (options bitOr: matchOptions).
	context ifNotNil: [ temporaryMatcher context: context copy autoRelease ].
	^ temporaryMatcher
]

{ #category : 'private' }
PCRE2Matcher >> temporaryMatcherForCallout [
	"Answer a temporary matcher that can carry a runtime callout without mutating the receiver."

	| callbackMatcher |
	callbackMatcher := self copy.
	callbackMatcher options: options.
	context ifNotNil: [ callbackMatcher context: context copy autoRelease ].
	^ callbackMatcher
]

{ #category : 'private' }
PCRE2Matcher >> validatePartialOption: partialOption [

	(partialOption = PCRE2 partialSoft or: [ partialOption = PCRE2 partialHard ]) ifFalse: [
		self error: 'Partial matching option must be PCRE2 partialSoft or PCRE2 partialHard' ]
]

{ #category : 'private' }
PCRE2Matcher >> validateUsableMatchData: matchData [

	(matchData backend family = backend family and: [ matchData backend codeUnitWidth = self codeUnitWidth ]) ifFalse: [
		PCRE2Error signal: 'Match data must use the same backend and code-unit width as the matcher' ].
	(matchData isPersistent or: [ matchData isNull ]) ifTrue: [
		PCRE2Error signal: 'Match data must hold an external PCRE2 match data block' ]
]

{ #category : 'callouts' }
PCRE2Matcher >> withAutomaticCallouts: calloutBlock do: aBlock [
	"Evaluate aBlock with a temporary matcher compiled with automatic callouts, for tools and diagnostics. Start optimization is disabled on it so that callouts expose matching progress."

	| callbackMatcher |
	callbackMatcher := self temporaryMatcherAddingCompileOptions: (PCRE2 autoCallout bitOr: PCRE2 noStartOptimize) matchOptions: 0.
	callbackMatcher context calloutBlock: calloutBlock.
	^ [ aBlock cull: callbackMatcher ] ensure: [ callbackMatcher context clearCallout ]
]

{ #category : 'callouts' }
PCRE2Matcher >> withCallout: calloutBlock do: aBlock [
	"Evaluate aBlock with a temporary matcher that invokes calloutBlock for runtime callouts. calloutBlock receives a PCRE2CalloutEvent and may answer an integer return code to control matching; any other answer continues."

	| callbackMatcher |
	callbackMatcher := self temporaryMatcherForCallout.
	callbackMatcher context calloutBlock: calloutBlock.
	^ [ aBlock cull: callbackMatcher ] ensure: [ callbackMatcher context clearCallout ]
]
