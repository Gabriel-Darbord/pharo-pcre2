"
Abstract superclass for compiled PCRE2 matchers.

Concrete subclasses bind the width-specific native API: PCRE2UTF8Matcher, PCRE2UTF16Matcher, and PCRE2UTF32Matcher. This class keeps shared matching, enumeration, groups, split, substitution, DFA, callout, tracing, persistence, and diagnostic behavior that can be expressed independently of the code-unit width.

Match operations create standalone PCRE2Match subclasses. A matcher does not own a reusable match result, so callers can keep a returned match and inspect text, groups, offsets, marks, partial/complete status, and native match-data diagnostics later.
"
Class {
	#name : 'PCRE2Matcher',
	#superclass : 'PCRE2Object',
	#traits : 'PCRE2TWithOptions',
	#classTraits : 'PCRE2TWithOptions classTrait',
	#instVars : [
		'pattern',
		'context',
		'compiler',
		'isJIT',
		'options',
		'nameTable'
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

{ #category : 'persistence' }
PCRE2Matcher >> bePersistent [
	"Compiled-pattern persistence is handled by PCRE2SessionManager. Match data is standalone."

	^ self
]

{ #category : 'private' }
PCRE2Matcher >> calloutSiteFromEnumerationBlock: anExternalAddress [
	"Answer a static callout site decoded for this matcher's code-unit width."

	^ PCRE2CalloutSite
		  fromEnumerationBlock: anExternalAddress
		  codeUnitWidth: self codeUnitWidth
]

{ #category : 'documentation' }
PCRE2Matcher >> calloutSites [
	"Answer the static callout sites compiled into this pattern. This is passive metadata: it does not install a runtime callout or affect matching."

	| sites |
	sites := OrderedCollection new.
	self calloutSitesDo: [ :site | sites add: site ].
	^ sites asArray
]

{ #category : 'documentation' }
PCRE2Matcher >> calloutSitesDo: aBlock [
	"Evaluate aBlock with each static callout site in this compiled pattern. This is passive metadata: it does not install a runtime callout or affect matching."

	| callback rc |
	callback := FFICallback
		            signature:
		            #( int #( void #* calloutBlock #, void #* userData ) )
		            block: [ :calloutBlock :userData |
			            aBlock value:
				            (self calloutSiteFromEnumerationBlock: calloutBlock).
			            0 ].
	rc := self enumerateCalloutsWith: callback.
	rc < 0 ifTrue: [ self errorCode: rc ].
	^ self
]

{ #category : 'private' }
PCRE2Matcher >> canUseJITForOptions: matchOptions [
	"Answer whether the compiled pattern has JIT code for the requested matching mode. The direct pcre2_jit_match() fast path does not fall back when a complete/partial mode was not JIT-compiled."

	isJIT ifFalse: [ ^ false ].
	(matchOptions bitAnd: PCRE2 noJIT) ~~ 0 ifTrue: [ ^ false ].
	(matchOptions bitAnd: PCRE2 partialHard) ~~ 0 ifTrue: [
		^ (compiler optionsJIT bitAnd: PCRE2 jitPartialHard) ~~ 0 ].
	(matchOptions bitAnd: PCRE2 partialSoft) ~~ 0 ifTrue: [
		^ (compiler optionsJIT bitAnd: PCRE2 jitPartialSoft) ~~ 0 ].
	^ (compiler optionsJIT bitAnd: PCRE2 jitComplete) ~~ 0
]

{ #category : 'private' }
PCRE2Matcher >> codeUnitByteSize [
	"Answer the number of bytes in one PCRE2 code unit for this matcher."

	^ self codeUnitWidth // 8
]

{ #category : 'documentation' }
PCRE2Matcher >> codeUnitWidth [
	^ self subclassResponsibility
]

{ #category : 'compiling' }
PCRE2Matcher >> compileJIT [
	"Request JIT compilation for this compiled pattern using the compiler options.
	If supported and unless reconfigured, patterns are JIT-compiled by default."

	compiler compileJIT: self
]

{ #category : 'compiling' }
PCRE2Matcher >> compileJIT: anInteger [
	^ self subclassResponsibility
]

{ #category : 'accessing' }
PCRE2Matcher >> compiler [
	"The compiler that processed this pattern"

	^ compiler
]

{ #category : 'accessing' }
PCRE2Matcher >> compiler: aPCRE2Compiler [
	"Should only be used by the compiler that processed this pattern"

	compiler := aPCRE2Compiler
]

{ #category : 'accessing' }
PCRE2Matcher >> context [

	^ context ifNil: [
		  context := self createMatchContext.
		  context isNull ifTrue: [
			  context := nil.
			  PCRE2Error signal:
				  'Failed to obtain memory to create match context' ].
		  context autoRelease ]
]

{ #category : 'accessing' }
PCRE2Matcher >> context: aMatchContext [

	context := aMatchContext
]

{ #category : 'match enumeration' }
PCRE2Matcher >> copy: subject matchesDo: aBlock [
	"Copy the subject and execute aBlock for each match.
	The block receives the output stream, raw subject bytes, and 1-based byte indexes for the matched slice."

	| bytesPerCodeUnit input lastByteIndex rs ws |
	input := self preparedInputFor: subject.
	bytesPerCodeUnit := self codeUnitByteSize.
	lastByteIndex := 0.
	rs := ReadStream on: input bytes.
	ws := WriteStream on: (String new: 100).
	self
		matchAllIn: input
		from: 1
		to: input size
		do: [ :match |
			| byteEnd byteStart startOffset |
			startOffset := match startOffsetAt: 1.
			byteStart := startOffset * bytesPerCodeUnit + 1.
			byteEnd := (match endOffsetAt: 1) * bytesPerCodeUnit.
			rs position: lastByteIndex.
			[ rs position < (byteStart - 1) ] whileTrue: [
				ws nextPut: (input nextFromStream: rs) ].
			aBlock
				value: ws
				value: input bytes
				value: byteStart
				value: byteEnd.
			lastByteIndex := byteEnd ].

	rs position: lastByteIndex.
	[ rs atEnd ] whileFalse: [ ws nextPut: (input nextFromStream: rs) ].
	^ ws contents
]

{ #category : 'match enumeration' }
PCRE2Matcher >> copy: subject replacingMatchesWith: aString [
	"Copy the subject replacing each match with aString"

	^ self
		  copy: subject
		  matchesDo: [ :ws :utfSubject :start :end | ws nextPutAll: aString ]
]

{ #category : 'match enumeration' }
PCRE2Matcher >> copy: subject translatingMatchesUsing: aBlock [
	"Copy the subject replacing each match by evaluating aBlock with the matched substring. Expect the block to answer a String, and replace the match with the answer."

	| input |
	input := self preparedInputFor: subject.
	^ self copy: input matchesDo: [ :ws :utfSubject :start :end |
		  ws nextPutAll: (aBlock value:
				   (input decodeBytes: (utfSubject copyFrom: start to: end))) ]
]

{ #category : 'copying' }
PCRE2Matcher >> copyWithCharacterTables [
	"Answer a copy whose native compiled pattern owns a copy of its low-character tables. JIT code is not copied and is rebuilt best-effort when needed."

	| copy newHandle |
	newHandle := self privateCopyWithCharacterTables.
	newHandle isNull ifTrue: [
		PCRE2Error signal:
			'Failed to obtain memory to copy matcher with character tables' ].
	copy := self shallowCopy.
	copy setHandle: newHandle.
	copy autoRelease initialize.
	copy options: self options.
	^ copy restoreJITIfNeeded
]

{ #category : 'private' }
PCRE2Matcher >> createMatchContext [
	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2Matcher >> createMatchDataFromPattern [
	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2Matcher >> createMatchDataWithOvectorSize: ovectorSize [
	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2Matcher >> decodeSubstitutionOutput: buffer codeUnits: codeUnitCount [

	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2Matcher >> decodeUTF8Output: buffer upTo: byteSize [
	^ self subclassResponsibility
]

{ #category : 'matching' }
PCRE2Matcher >> dfaMatch: subject [
	"Run a DFA match and answer all same-start alternatives as standalone match data."

	^ self dfaMatch: subject workspaceSize: 100
]

{ #category : 'private' }
PCRE2Matcher >> dfaMatch: subject from: start to: end matchData: aMatchData workspace: workspace size: workspaceSize [
	^ self subclassResponsibility
]

{ #category : 'matching' }
PCRE2Matcher >> dfaMatch: subject workspaceSize: workspaceSize [
	"Run a DFA match with caller-controlled workspace storage."

	^ self dfaMatch: subject workspaceSize: workspaceSize ovectorSize: 20
]

{ #category : 'matching' }
PCRE2Matcher >> dfaMatch: subject workspaceSize: workspaceSize ovectorSize: ovectorSize [
	"Run a DFA match with explicit workspace and ovector sizes."

	| input match |
	input := self preparedInputFor: subject.
	match := self
		         dfaMatchBytes: input bytes
		         from: 1
		         to: input size
		         workspaceSize: workspaceSize
		         ovectorSize: ovectorSize.
	match ifNotNil: [ input recordOn: match ].
	^ match
]

{ #category : 'byte matching' }
PCRE2Matcher >> dfaMatchBytes: subject from: start to: end workspaceSize: workspaceSize ovectorSize: ovectorSize [
	"Run a DFA match over a prepared subject buffer and answer standalone match data, or nil."

	| match rc |
	match := self newMatchDataWithOvectorSize: ovectorSize.
	rc := self
		      dfaMatchBytes: subject
		      from: start
		      to: end
		      workspaceSize: workspaceSize
		      ovectorSize: ovectorSize
		      into: match.
	rc == PCRE2 errorNoMatch ifTrue: [ ^ nil ].
	match subject: subject decoder: nil.
	^ match
]

{ #category : 'byte matching' }
PCRE2Matcher >> dfaMatchBytes: subject from: start to: end workspaceSize: workspaceSize ovectorSize: ovectorSize into: aPCRE2Match [
	"Run a DFA match over a prepared subject buffer and populate caller-provided match data."

	| rc workspace |
	self validateDFAWorkspaceSize: workspaceSize ovectorSize: ovectorSize.
	self validateUsableMatchData: aPCRE2Match.
	aPCRE2Match reset.
	workspace := ByteArray new: workspaceSize * 4.
	rc := self
		      dfaMatch: subject
		      from: start - 1
		      to: end
		      matchData: aPCRE2Match
		      workspace: workspace
		      size: workspaceSize.
	^ self recordDFAMatchResult: rc in: aPCRE2Match
]

{ #category : 'matching' }
PCRE2Matcher >> dfaMatches: subject [
	"Return all same-start DFA alternatives decoded back to Pharo strings."

	^ self dfaMatches: subject workspaceSize: 100
]

{ #category : 'matching' }
PCRE2Matcher >> dfaMatches: subject workspaceSize: workspaceSize [
	"Return all same-start DFA alternatives decoded back to Pharo strings."

	^ self
		  dfaMatches: subject
		  workspaceSize: workspaceSize
		  ovectorSize: 20
]

{ #category : 'matching' }
PCRE2Matcher >> dfaMatches: subject workspaceSize: workspaceSize ovectorSize: ovectorSize [
	"Return all same-start DFA alternatives decoded back to Pharo strings."

	^ (self
		   dfaMatch: subject
		   workspaceSize: workspaceSize
		   ovectorSize: ovectorSize)
		  ifNil: [ #(  ) ]
		  ifNotNil: [ :match | match readMatches ]
]

{ #category : 'private' }
PCRE2Matcher >> enumerateCalloutsWith: callback [
	^ self subclassResponsibility
]

{ #category : 'error handling' }
PCRE2Matcher >> errorCode: errorCode [

	<debuggerCompleteToSender>
	PCRE2MatchError signal: (PCRE2 translateErrorCode: errorCode)
]

{ #category : 'matching' }
PCRE2Matcher >> find: subject [
	"Returns the first matching substring within the subject."

	^ (self findMatch: subject) ifNotNil: [ :match | match readMatch ]
]

{ #category : 'callouts' }
PCRE2Matcher >> find: subject calloutsDo: calloutBlock [
	"Answer the first matching substring while invoking calloutBlock for runtime PCRE2 callouts."

	^ self
		  withCallout: calloutBlock
		  do: [ :callbackMatcher | callbackMatcher find: subject ]
]

{ #category : 'match enumeration' }
PCRE2Matcher >> findAll: subject [
	"Returns all matching substrings within the subject."

	| input result |
	result := OrderedCollection new.
	input := self preparedInputFor: subject.
	self
		matchAllIn: input
		from: 1
		to: input size
		do: [ :match | result add: match readMatch ].
	^ result
]

{ #category : 'callouts' }
PCRE2Matcher >> findAll: subject calloutsDo: calloutBlock [
	"Answer all matching substrings while invoking calloutBlock for runtime PCRE2 callouts."

	^ self
		  withCallout: calloutBlock
		  do: [ :callbackMatcher | callbackMatcher findAll: subject ]
]

{ #category : 'match enumeration' }
PCRE2Matcher >> findAll: subject do: aBlock [
	"Iterate over all matching substrings within the subject."

	| input |
	input := self preparedInputFor: subject.
	self
		matchAllIn: input
		from: 1
		to: input size
		do: [ :match | aBlock value: match readMatch ]
]

{ #category : 'match enumeration' }
PCRE2Matcher >> findAllWithGroups: subject [
	"Returns all matching substrings and groups within the subject."

	| input result |
	result := OrderedCollection new.
	input := self preparedInputFor: subject.
	self
		matchAllIn: input
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
	match ifNotNil: [ input recordOn: match ].
	^ match
]

{ #category : 'callouts' }
PCRE2Matcher >> findMatch: subject calloutsDo: calloutBlock [
	"Answer the first match while invoking calloutBlock for runtime PCRE2 callouts."

	^ self
		  withCallout: calloutBlock
		  do: [ :callbackMatcher | callbackMatcher findMatch: subject ]
]

{ #category : 'matching' }
PCRE2Matcher >> findPartialMatch: subject [
	"Answer the first complete or soft-partial match in subject, or nil. Soft partial matching prefers a complete match when one exists. Ask the returned PCRE2Match whether it isPartial."

	^ self findPartialMatch: subject option: PCRE2 partialSoft
]

{ #category : 'matching' }
PCRE2Matcher >> findPartialMatch: subject option: partialOption [
	"Answer the first complete or partial match using the requested PCRE2 partial option. Ask the returned PCRE2Match whether it isPartial or isComplete."

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
	input recordOn: match.
	^ match
]

{ #category : 'matching' }
PCRE2Matcher >> findSoftPartialMatch: subject [
	"Answer the first complete or soft-partial match in subject, or nil. Soft partial matching prefers a complete match when one exists."

	^ self findPartialMatch: subject option: PCRE2 partialSoft
]

{ #category : 'matching' }
PCRE2Matcher >> findWithGroups: subject [
	"Returns the first matching substring and groups within the subject."

	^ (self findMatch: subject)
		  ifNil: [ #(  ) ]
		  ifNotNil: [ :match | match readMatches ]
]

{ #category : 'external resource management' }
PCRE2Matcher >> free [
	^ self subclassResponsibility
]

{ #category : 'documentation' }
PCRE2Matcher >> info: option [
	"Returns some information about the compiled pattern.
	See class-side methods of PCRE2 starting with 'info' to find valid options."

	| buffer size rc |
	size := (option == PCRE2 infoSize or: [
		         option == PCRE2 infoJITSize or: [
			         option == PCRE2 infoFirstBitmap or: [
				         option == PCRE2 infoNameTable ] ] ])
		        ifTrue: [ "size_t or pointer" ExternalAddress wordSize ]
		        ifFalse: [ "uint32" 4 ].
	buffer := ByteArray new: size.
	rc := self info: option output: buffer.
	rc < 0 ifTrue: [
		rc == PCRE2 errorUnset ifTrue: [ ^ nil ].
		super errorCode: rc "not a match error" ].

	(option == PCRE2 infoSize or: [ option == PCRE2 infoJITSize ])
		ifTrue: [ "info is a size_t"
			^ size == 8
				  ifTrue: [ buffer uint64AtOffset: 0 ]
				  ifFalse: [ "assume size == 4, make an issue if it crashes!"
				  buffer uint32AtOffset: 0 ] ].
	(option == PCRE2 infoFirstBitmap or: [ option == PCRE2 infoNameTable ])
		ifTrue: [ "a pointer to external data"
			^ (buffer allSatisfy: [ :byte | byte == 0 ])
				  ifTrue: [ nil ]
				  ifFalse: [ buffer ] ].
	"info is a uint32 in all other cases"
	^ buffer uint32AtOffset: 0
]

{ #category : 'private' }
PCRE2Matcher >> info: what output: where [
	^ self subclassResponsibility
]

{ #category : 'initialization' }
PCRE2Matcher >> initialize [
	"Initialize matcher-local options and lazily-computed metadata. Match data is created per match operation."

	options := 0.
	nameTable := nil
]

{ #category : 'accessing' }
PCRE2Matcher >> isJIT [

	^ isJIT
]

{ #category : 'accessing' }
PCRE2Matcher >> isJIT: aBoolean [
	"Indicates whether the pattern is JIT-compiled.
	Can be set to false if using match() over the jit_match() fast path is required for additional validity checks,
	and if the pattern is JIT-compiled, the fast machine code is still used.
	Setting to true when the pattern is not really JIT-compiled will cause matches to throw an error."

	isJIT := aBoolean and: [ compiler optionsJIT ~~ 0 ]
]

{ #category : 'private' }
PCRE2Matcher >> jitMatch: subject from: start to: end options: matchOptions matchData: aMatchData [
	^ self subclassResponsibility
]

{ #category : 'querying' }
PCRE2Matcher >> mark [
	"Matchers no longer keep the last match. Query mark on the returned PCRE2Match."

	self error:
		'PCRE2Matcher no longer keeps the last match; query mark on the returned PCRE2Match'
]

{ #category : 'private' }
PCRE2Matcher >> match: subject from: start to: end options: matchOptions matchData: aMatchData [
	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2Matcher >> matchAll: subject from: start to: end advancingEmptyMatchesWith: nextStartBlock do: aBlock [
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

{ #category : 'byte matching' }
PCRE2Matcher >> matchAll: subject from: start to: end do: aBlock [
	"Iteratively match over raw code-unit storage and execute aBlock with each standalone match. Empty matches retry with PCRE2_NOTEMPTY_ATSTART before advancing by one code unit."

	self
		matchAll: subject
		from: start
		to: end
		advancingEmptyMatchesWith: [ :offset | offset + 1 ]
		do: [ :match |
			match subject: subject decoder: nil.
			aBlock cull: match ]
]

{ #category : 'byte matching' }
PCRE2Matcher >> matchAll: subject from: start to: end offsetsDo: aBlock [
	"Iteratively match over a range of the subject and execute aBlock with each match's offsets."

	self
		matchAll: subject
		from: start
		to: end
		do: [ :match | aBlock value: match offsets ]
]

{ #category : 'match enumeration' }
PCRE2Matcher >> matchAllIn: input from: start to: end do: aBlock [
	"Iteratively match over a prepared input and execute aBlock with each standalone match. Empty-match fallback advances by the input's character boundary protocol."

	self
		matchAll: input bytes
		from: start
		to: end
		advancingEmptyMatchesWith: [ :offset |
		input nextMatchStartOffsetAfter: offset ]
		do: [ :match |
			input recordOn: match.
			aBlock cull: match ]
]

{ #category : 'byte matching' }
PCRE2Matcher >> matchBytes: subject from: start to: end [
	"Run a match over a UTF-encoded subject range and answer standalone match data, or nil."

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

	^ self withCallout: calloutBlock do: [ :callbackMatcher |
		  callbackMatcher matchBytes: subject from: start to: end ]
]

{ #category : 'byte matching' }
PCRE2Matcher >> matchBytes: subject from: start to: end into: aPCRE2Match [
	"Run a match over a UTF-encoded subject range and populate caller-provided match data."

	^ self
		  matchBytes: subject
		  from: start
		  to: end
		  options: options
		  into: aPCRE2Match
]

{ #category : 'byte matching' }
PCRE2Matcher >> matchBytes: subject from: start to: end options: matchOptions into: aPCRE2Match [
	"Run a match over a UTF-encoded subject range with explicit PCRE2 match options and populate caller-provided match data."

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
	^ self subclassResponsibility
]

{ #category : 'accessing' }
PCRE2Matcher >> matchData [
	"Matchers no longer own match data. Use findMatch: or matchBytes:from:to: and query the returned PCRE2Match."

	self error:
		'PCRE2Matcher no longer keeps match data; query the PCRE2Match returned by a match operation'
]

{ #category : 'accessing' }
PCRE2Matcher >> matchData: aPCRE2Match [
	"Matchers no longer own match data. Reuse match data with matchBytes:from:to:into:."

	self error:
		'PCRE2Matcher no longer accepts stored match data; pass it to a match operation instead'
]

{ #category : 'matching' }
PCRE2Matcher >> matches: subject [
	"Returns whether the regex fully matches the subject."

	| input match |
	input := self preparedInputFor: subject.
	match := self matchBytes: input bytes from: 1 to: input size.
	match ifNil: [ ^ false ].
	match isPartial ifTrue: [ ^ false ].
	match offsetsDo: [ :start :end |
		^ start == 1 and: [ end == input size ] ].
	^ false
]

{ #category : 'callouts' }
PCRE2Matcher >> matches: subject calloutsDo: calloutBlock [
	"Answer whether the subject is fully matched while invoking calloutBlock for runtime PCRE2 callouts."

	^ self
		  withCallout: calloutBlock
		  do: [ :callbackMatcher | callbackMatcher matches: subject ]
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
	self
		findAll: subject
		do: [ :match | result add: (aBlock value: match) ].
	^ result
]

{ #category : 'match enumeration' }
PCRE2Matcher >> matchesIn: subject do: aBlock [
	"Equivalent of RxMatcher >> #matchesIn:do:"

	self findAll: subject do: aBlock
]

{ #category : 'matching' }
PCRE2Matcher >> matchesPrefix: subject [
	"Returns whether the regex completely matches the start of the subject."

	| input match |
	input := self preparedInputFor: subject.
	match := self matchBytes: input bytes from: 1 to: input size.
	match ifNil: [ ^ false ].
	match isPartial ifTrue: [ ^ false ].
	match offsetsDo: [ :start :end | ^ start == 1 ].
	^ false
]

{ #category : 'callouts' }
PCRE2Matcher >> matchesPrefix: subject calloutsDo: calloutBlock [
	"Answer whether the subject prefix matches while invoking calloutBlock for runtime PCRE2 callouts."

	^ self
		  withCallout: calloutBlock
		  do: [ :callbackMatcher | callbackMatcher matchesPrefix: subject ]
]

{ #category : 'match enumeration' }
PCRE2Matcher >> matchingRangesIn: subject [
	"Answer ranges of each match as 1-based Pharo character intervals."

	| input ranges |
	input := self preparedInputFor: subject.
	ranges := OrderedCollection new.
	self
		matchAllIn: input
		from: 1
		to: input size
		do: [ :match |
			| offsets |
			offsets := match offsetsAt: 1.
			ranges add: (input
					 characterRangeFromStartOffset: offsets first
					 endOffset: offsets second) ].
	^ ranges
]

{ #category : 'documentation' }
PCRE2Matcher >> namedGroups [
	"Answer a sparse Array mapping PCRE2 capture group numbers to their names.
	Capture group 1 is the first parenthesized group; group 0 is the whole match and is not named. Duplicate names can appear at multiple indexes when the pattern was compiled with PCRE2 dupNames."

	^ nameTable ifNil: [ nameTable := self readNamedGroups ]
]

{ #category : 'external resource management' }
PCRE2Matcher >> newMatchData [
	"Create match data sized for this pattern's capture groups."

	| pointer |
	pointer := self createMatchDataFromPattern.
	pointer isNull ifTrue: [
		PCRE2Error signal: 'Failed to obtain memory to create match data' ].
	^ (self matchClass fromHandle: pointer) initialize autoRelease
]

{ #category : 'external resource management' }
PCRE2Matcher >> newMatchDataWithOvectorSize: ovectorSize [
	"Create match data with an explicit number of offset pairs."

	| pointer |
	pointer := self createMatchDataWithOvectorSize: ovectorSize.
	pointer isNull ifTrue: [
		PCRE2Error signal: 'Failed to obtain memory to create match data' ].
	^ (self matchClass fromHandle: pointer) initialize autoRelease
]

{ #category : 'private' }
PCRE2Matcher >> optionsWithPartialOption: partialOption [
	"Answer my match options with exactly the requested partial-matching mode."

	self validatePartialOption: partialOption.
	^ (options bitAnd: (PCRE2 partialSoft | PCRE2 partialHard) bitInvert)
		  bitOr: partialOption
]

{ #category : 'accessing' }
PCRE2Matcher >> pattern [
	"The original string of this compiled pattern"

	^ pattern
]

{ #category : 'accessing' }
PCRE2Matcher >> pattern: aString [
	"Must only be used by the compiler."

	pattern := aString.
	nameTable := nil
]

{ #category : 'copying' }
PCRE2Matcher >> postCopy [
	"Copy the external structure of the compiled pattern."

	handle := self privateCopy.
	handle isNull ifTrue: [
		PCRE2Error signal: 'Failed to obtain memory to copy matcher' ].
	self autoRelease initialize.
	self restoreJITIfNeeded
]

{ #category : 'private' }
PCRE2Matcher >> preparedInputFor: aStringOrInput [
	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2Matcher >> privateCopy [
	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2Matcher >> privateCopyWithCharacterTables [

	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2Matcher >> readNamedGroups [
	^ self subclassResponsibility
]

{ #category : 'persistence' }
PCRE2Matcher >> recompile [
	"Recreate the external compiled pattern from the Smalltalk-side source of truth."

	| wantsJIT |
	wantsJIT := self isJIT.
	self setHandle: (compiler compileBasic: pattern).
	wantsJIT == true ifTrue: [ self restoreJITIfNeeded ]
]

{ #category : 'private' }
PCRE2Matcher >> recordDFAMatchResult: rc in: aPCRE2Match [

	aPCRE2Match resultCode: rc.
	rc > 0 ifTrue: [
		aPCRE2Match count: rc.
		^ rc ].

	rc == PCRE2 errorPartial ifTrue: [
		aPCRE2Match count: 1.
		^ rc ].

	aPCRE2Match count: 0.
	rc == PCRE2 errorNoMatch ifTrue: [ ^ rc ].

	rc == 0 ifTrue: [
		PCRE2Error signal:
			'Not enough match data ovector slots to store DFA results' ].

	self errorCode: rc
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

	rc == 0 ifTrue: [
		PCRE2Error signal:
			'Not enough memory in match structure to store results' ].

	self errorCode: rc
]

{ #category : 'persistence' }
PCRE2Matcher >> restoreFrom: bytes [
	"Restore this matcher from serialized compiled-pattern bytes produced for the same code-unit width."

	self ffiLibraryName restore: { self } from: bytes
]

{ #category : 'persistence' }
PCRE2Matcher >> restoreJITIfNeeded [
	"Serialized and copied PCRE2 code does not include JIT data. Rebuild it when requested, but keep the pattern usable without JIT if the platform cannot provide it now."

	self isJIT == true ifFalse: [ ^ self ].
	[ compiler compileJIT: self ]
		on: PCRE2Error
		do: [ :ex | self isJIT: false ].
	^ self
]

{ #category : 'matching' }
PCRE2Matcher >> search: subject [
	"Returns whether the regex partially matches the subject."

	^ (self findMatch: subject) notNil
]

{ #category : 'callouts' }
PCRE2Matcher >> search: subject calloutsDo: calloutBlock [
	"Answer whether the subject contains a match while invoking calloutBlock for runtime PCRE2 callouts."

	^ self
		  withCallout: calloutBlock
		  do: [ :callbackMatcher | callbackMatcher search: subject ]
]

{ #category : 'persistence' }
PCRE2Matcher >> serialize [
	"Serialize this matcher's compiled pattern, excluding JIT code.
	This convenience method is less efficient than serializing same-width matchers in bulk, because PCRE2 repeats shared tables in each serialized blob."

	^ self ffiLibraryName serialize: { self }
]

{ #category : 'splitjoin' }
PCRE2Matcher >> split: subject indicesDo: aBlock [
	"Split subject on my matches, evaluating aBlock with each kept 1-based Pharo character range. Regex delimiters must consume at least one code unit."

	| input lastEndOffset match nextStart subjectEnd |
	input := self preparedInputFor: subject.
	lastEndOffset := 0.
	nextStart := 1.
	subjectEnd := input characterCountUpToByteOffset: input size.
	[
	nextStart <= (input size + 1) and: [
		(match := self
			          matchBytes: input bytes
			          from: nextStart
			          to: input size) notNil ] ] whileTrue: [
		| offsets startOffset endOffset |
		offsets := match offsetsAt: 1.
		startOffset := offsets first.
		endOffset := offsets second.
		[ startOffset < endOffset ] assertWithDescription:
			'Regex cannot match null string'.
		aBlock
			value: (input characterCountUpToByteOffset: lastEndOffset) + 1
			value: (input characterCountUpToByteOffset: startOffset).
		lastEndOffset := endOffset.
		nextStart := endOffset + 1 ].
	aBlock
		value: (input characterCountUpToByteOffset: lastEndOffset) + 1
		value: subjectEnd
]

{ #category : 'querying' }
PCRE2Matcher >> startIndex [
	"Matchers no longer keep the last match. Query startIndex on the returned PCRE2Match."

	self error:
		'PCRE2Matcher no longer keeps the last match; query startIndex on the returned PCRE2Match'
]

{ #category : 'private' }
PCRE2Matcher >> substitute: subject from: start to: end options: substituteOptions matchData: aPCRE2Match replacement: replacement upTo: rLength output: buffer size: outSize [
	"Dispatch pcre2_substitute() with or without caller-supplied match data. A nil match data lets PCRE2 perform the match; a non-nil match data is used with PCRE2 substituteMatched."

	aPCRE2Match ifNil: [
		^ self
			  substitute: subject
			  from: start
			  to: end
			  options: substituteOptions
			  replacement: replacement
			  upTo: rLength
			  output: buffer
			  size: outSize ].
	^ self
		  substitute: subject
		  from: start
		  to: end
		  options: substituteOptions
		  matchedData: aPCRE2Match
		  replacement: replacement
		  upTo: rLength
		  output: buffer
		  size: outSize
]

{ #category : 'private' }
PCRE2Matcher >> substitute: subject from: start to: end options: substituteOptions matchedData: aPCRE2Match replacement: replacement upTo: rLength output: buffer size: outSize [
	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2Matcher >> substitute: subject from: start to: end options: substituteOptions replacement: replacement upTo: rLength output: buffer size: outSize [
	^ self subclassResponsibility
]

{ #category : 'matching' }
PCRE2Matcher >> substitute: subject with: replacement [
	"Answer subject with the first match substituted by replacement. PCRE2 treats replacement as a substitution expression unless substituteLiteral is set in the matcher options."

	^ self
		  substitute: subject
		  with: replacement
		  options: self substitutionOptions
]

{ #category : 'matching' }
PCRE2Matcher >> substitute: subject with: replacement addingOptions: substituteOptions [
	"Answer subject with substitutions applied using my substitution options plus substituteOptions."

	^ self
		  substitute: subject
		  with: replacement
		  options: (self substitutionOptions bitOr: substituteOptions)
]

{ #category : 'callouts' }
PCRE2Matcher >> substitute: subject with: replacement calloutsDo: calloutBlock [
	"Answer subject with the first match substituted while invoking calloutBlock after the processed replacement."

	^ self
		  substitute: subject
		  with: replacement
		  options: self substitutionOptions
		  calloutsDo: calloutBlock
]

{ #category : 'callouts' }
PCRE2Matcher >> substitute: subject with: replacement caseCallout: caseBlock [
	"Answer subject with the first match substituted while caseBlock handles replacement case escapes."

	^ self
		  substitute: subject
		  with: replacement
		  options: self substitutionOptions
		  caseCallout: caseBlock
]

{ #category : 'matching' }
PCRE2Matcher >> substitute: subject with: replacement options: substituteOptions [
	"Answer subject with substitutions applied using the supplied PCRE2 substitution options instead of the matcher options. PCRE2 treats replacement as a substitution expression unless PCRE2 substituteLiteral is set. The implementation may add PCRE2 substituteOverflowLength internally to size the output buffer."

	^ self
		  substitute: subject
		  with: replacement
		  options: substituteOptions
		  matchData: nil
]

{ #category : 'callouts' }
PCRE2Matcher >> substitute: subject with: replacement options: substituteOptions calloutsDo: calloutBlock [
	"Answer subject with substitutions applied using substituteOptions while invoking calloutBlock after each processed replacement."

	^ self withSubstituteCallout: calloutBlock do: [ :callbackMatcher |
		  callbackMatcher
			  substitute: subject
			  with: replacement
			  options: substituteOptions ]
]

{ #category : 'callouts' }
PCRE2Matcher >> substitute: subject with: replacement options: substituteOptions caseCallout: caseBlock [
	"Answer subject with substitutions applied using substituteOptions while caseBlock handles replacement case escapes. Case escapes require PCRE2 substituteExtended."

	^ self withSubstituteCaseCallout: caseBlock do: [ :callbackMatcher |
		  callbackMatcher
			  substitute: subject
			  with: replacement
			  options: substituteOptions ]
]

{ #category : 'private' }
PCRE2Matcher >> substitute: subject with: replacement options: substituteOptions matchData: aPCRE2Match [
	"Private helper for pcre2_substitute(). Prepare a normal subject or reuse a prepared input, then pass optional PCRE2 match data to the byte-level helper."

	| input |
	input := self preparedInputFor: subject.
	^ self
		  substituteBytes: input bytes
		  replacement: replacement
		  options: substituteOptions
		  matchData: aPCRE2Match
]

{ #category : 'matching' }
PCRE2Matcher >> substitute: subject withLiteral: replacement [
	"Answer subject with the first match substituted by replacement, treating replacement as literal text rather than a PCRE2 substitution expression."

	^ self
		  substitute: subject
		  with: replacement
		  addingOptions: PCRE2 substituteLiteral
]

{ #category : 'matching' }
PCRE2Matcher >> substitute: subject withUnknownCapturesEmpty: replacement [
	"Answer subject with the first match substituted by replacement, treating unknown and unset captures as empty strings. Use with care because typos in replacement group names no longer signal."

	^ self
		  substitute: subject
		  with: replacement
		  addingOptions:
		  PCRE2 substituteUnknownUnset | PCRE2 substituteUnsetEmpty
]

{ #category : 'matching' }
PCRE2Matcher >> substitute: subject withUnsetCapturesEmpty: replacement [
	"Answer subject with the first match substituted by replacement, treating unset captures referenced by replacement as empty strings."

	^ self
		  substitute: subject
		  with: replacement
		  addingOptions: PCRE2 substituteUnsetEmpty
]

{ #category : 'matching' }
PCRE2Matcher >> substituteAll: subject with: replacement [
	"Answer subject with every non-overlapping match substituted by replacement."

	^ self
		  substitute: subject
		  with: replacement
		  addingOptions: PCRE2 substituteGlobal
]

{ #category : 'callouts' }
PCRE2Matcher >> substituteAll: subject with: replacement calloutsDo: calloutBlock [
	"Answer subject with every non-overlapping match substituted while invoking calloutBlock after each processed replacement."

	^ self
		  substitute: subject
		  with: replacement
		  options: self substitutionOptions | PCRE2 substituteGlobal
		  calloutsDo: calloutBlock
]

{ #category : 'callouts' }
PCRE2Matcher >> substituteAll: subject with: replacement caseCallout: caseBlock [
	"Answer subject with every non-overlapping match substituted while caseBlock handles replacement case escapes."

	^ self
		  substitute: subject
		  with: replacement
		  options: self substitutionOptions | PCRE2 substituteGlobal
		  caseCallout: caseBlock
]

{ #category : 'callouts' }
PCRE2Matcher >> substituteAll: subject with: replacement options: substituteOptions caseCallout: caseBlock [
	"Answer subject with every non-overlapping match substituted using substituteOptions while caseBlock handles replacement case escapes."

	^ self
		  substitute: subject
		  with: replacement
		  options: substituteOptions | PCRE2 substituteGlobal
		  caseCallout: caseBlock
]

{ #category : 'matching' }
PCRE2Matcher >> substituteAll: subject withLiteral: replacement [
	"Answer subject with every non-overlapping match substituted by replacement, treating replacement as literal text."

	^ self
		  substitute: subject
		  with: replacement
		  addingOptions: PCRE2 substituteGlobal | PCRE2 substituteLiteral
]

{ #category : 'matching' }
PCRE2Matcher >> substituteAll: subject withUnknownCapturesEmpty: replacement [
	"Answer subject with every non-overlapping match substituted by replacement, treating unknown and unset captures as empty strings. Use with care because typos in replacement group names no longer signal."

	^ self
		  substitute: subject
		  with: replacement
		  addingOptions:
			  PCRE2 substituteGlobal | PCRE2 substituteUnknownUnset
			  | PCRE2 substituteUnsetEmpty
]

{ #category : 'matching' }
PCRE2Matcher >> substituteAll: subject withUnsetCapturesEmpty: replacement [
	"Answer subject with every non-overlapping match substituted by replacement, treating unset captures as empty strings."

	^ self
		  substitute: subject
		  with: replacement
		  addingOptions: PCRE2 substituteGlobal | PCRE2 substituteUnsetEmpty
]

{ #category : 'matching' }
PCRE2Matcher >> substituteAllReplacementsOnly: subject with: replacement [
	"Answer only the replacement text generated for all non-overlapping matches, concatenated in match order."

	^ self
		  substitute: subject
		  with: replacement
		  addingOptions:
		  PCRE2 substituteGlobal | PCRE2 substituteReplacementOnly
]

{ #category : 'private' }
PCRE2Matcher >> substituteBytes: subjectBytes replacement: replacement options: substituteOptions matchData: aPCRE2Match [
	"Apply pcre2_substitute() to prepared subject bytes.
	The SizeTHolder values are PCRE2 code-unit counts, while ByteArray storage is sized in bytes. Case callouts can make PCRE2 underestimate output size, so retry until the native call succeeds or fails for a reason other than output capacity."

	| buffer bufferCodeUnitSize bytesPerCodeUnit effectiveOptions holder rc replacementInput subjectCodeUnitSize |
	bytesPerCodeUnit := self codeUnitByteSize.
	subjectCodeUnitSize := subjectBytes size // bytesPerCodeUnit.
	replacementInput := self preparedInputFor: replacement.
	effectiveOptions := substituteOptions bitOr:
		                    PCRE2 substituteOverflowLength.
	bufferCodeUnitSize := 4096.

	[
	holder := SizeTHolder new value: bufferCodeUnitSize.
	buffer := ByteArray new: bufferCodeUnitSize * bytesPerCodeUnit.
	rc := self
		      substitute: subjectBytes
		      from: 0
		      to: subjectCodeUnitSize
		      options: effectiveOptions
		      matchData: aPCRE2Match
		      replacement: replacementInput bytes
		      upTo: replacementInput size
		      output: buffer
		      size: holder.
	rc = PCRE2 errorNoMemory ] whileTrue: [
		bufferCodeUnitSize := holder value max: bufferCodeUnitSize * 2 ].

	rc < 0 ifTrue: [ self errorCode: rc ].
	^ self decodeSubstitutionOutput: buffer codeUnits: holder value
]

{ #category : 'matching' }
PCRE2Matcher >> substituteReplacementsOnly: subject with: replacement [
	"Answer only the replacement text generated for the first match."

	^ self
		  substitute: subject
		  with: replacement
		  addingOptions: PCRE2 substituteReplacementOnly
]

{ #category : 'matching' }
PCRE2Matcher >> substituteUsingMatch: aPCRE2Match with: replacement [
	"Answer the subject remembered by aPCRE2Match after substituting replacement for that already-computed match. The match must have been produced by this matcher over the same subject bytes."

	^ self
		  substituteUsingMatch: aPCRE2Match
		  with: replacement
		  options: self substitutionOptions
]

{ #category : 'callouts' }
PCRE2Matcher >> substituteUsingMatch: aPCRE2Match with: replacement calloutsDo: calloutBlock [
	"Answer the subject remembered by aPCRE2Match after substituting replacement for that already-computed match, while invoking calloutBlock after each processed replacement."

	^ self
		  substituteUsingMatch: aPCRE2Match
		  with: replacement
		  options: self substitutionOptions
		  calloutsDo: calloutBlock
]

{ #category : 'callouts' }
PCRE2Matcher >> substituteUsingMatch: aPCRE2Match with: replacement caseCallout: caseBlock [
	"Answer the subject remembered by aPCRE2Match after substituting replacement for that match, while caseBlock handles replacement case escapes."

	^ self
		  substituteUsingMatch: aPCRE2Match
		  with: replacement
		  options: self substitutionOptions
		  caseCallout: caseBlock
]

{ #category : 'matching' }
PCRE2Matcher >> substituteUsingMatch: aPCRE2Match with: replacement options: substituteOptions [
	"Answer the subject remembered by aPCRE2Match after substituting replacement for that already-computed match. PCRE2 requires the match data to come from this pattern, subject, and compatible match options."

	self validateSubstitutionMatchData: aPCRE2Match.
	^ self
		  substituteBytes: aPCRE2Match subject
		  replacement: replacement
		  options: substituteOptions | PCRE2 substituteMatched
		  matchData: aPCRE2Match
]

{ #category : 'callouts' }
PCRE2Matcher >> substituteUsingMatch: aPCRE2Match with: replacement options: substituteOptions calloutsDo: calloutBlock [
	"Answer the subject remembered by aPCRE2Match after substituting replacement for that already-computed match, while invoking calloutBlock after each processed replacement. This uses the receiver directly because PCRE2_SUBSTITUTE_MATCHED requires the same native compiled-pattern handle that produced the match data."

	self context substituteCalloutBlock: calloutBlock.
	^ [
	  self
		  substituteUsingMatch: aPCRE2Match
		  with: replacement
		  options: substituteOptions ] ensure: [
		  self context clearSubstituteCallout ]
]

{ #category : 'callouts' }
PCRE2Matcher >> substituteUsingMatch: aPCRE2Match with: replacement options: substituteOptions caseCallout: caseBlock [
	"Answer the subject remembered by aPCRE2Match after substituting replacement for that match, while caseBlock handles replacement case escapes. This uses the receiver directly because PCRE2_SUBSTITUTE_MATCHED requires the same native compiled-pattern handle that produced the match data."

	self context substituteCaseCalloutBlock: caseBlock.
	^ [
	  self
		  substituteUsingMatch: aPCRE2Match
		  with: replacement
		  options: substituteOptions ] ensure: [
		  self context clearSubstituteCaseCallout ]
]

{ #category : 'private' }
PCRE2Matcher >> substitutionOptions [
	"Answer matcher options that are safe to pass to pcre2_substitute_8. Partial matching options are not valid for substitution."

	^ options bitAnd: (PCRE2 partialSoft | PCRE2 partialHard) bitInvert
]

{ #category : 'private' }
PCRE2Matcher >> temporaryMatcherAddingCompileOptions: compileOptions matchOptions: matchOptions [
	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2Matcher >> temporaryMatcherForCallout [
	"Answer a temporary matcher that can carry a runtime callout without mutating the receiver."

	| callbackMatcher |
	callbackMatcher := self copy.
	callbackMatcher options: options.
	context ifNotNil: [
		callbackMatcher context: context copy autoRelease ].
	^ callbackMatcher
]

{ #category : 'debugging' }
PCRE2Matcher >> traceMatch: aStringOrInput [
	"Run an instrumented non-JIT match and answer a trace without mutating the receiver."

	| eventSnapshots input match patternInput resultCode traceMatcher |
	traceMatcher := self traceMatcher.
	input := self preparedInputFor: aStringOrInput.
	patternInput := compiler preparedPatternFor: pattern.
	eventSnapshots := OrderedCollection new.
	traceMatcher context calloutBlock: [ :event |
		eventSnapshots add: event.
		0 ].
	match := traceMatcher newMatchData.
	resultCode := traceMatcher
		              matchBytes: input bytes
		              from: 1
		              to: input size
		              into: match.
	resultCode = PCRE2 errorNoMatch
		ifTrue: [ match := nil ]
		ifFalse: [ input recordOn: match ].
	^ PCRE2MatchTrace
		  pattern: pattern
		  patternInput: patternInput
		  subject: aStringOrInput
		  input: input
		  calloutSites: traceMatcher calloutSites
		  events: eventSnapshots asArray
		  match: match
		  resultCode: resultCode
]

{ #category : 'debugging' }
PCRE2Matcher >> traceMatcher [
	"Answer a temporary matcher compiled for tracing. The receiver is not mutated."

	^ self
		  temporaryMatcherAddingCompileOptions:
		  (PCRE2 autoCallout bitOr: PCRE2 noStartOptimize)
		  matchOptions: PCRE2 noJIT
]

{ #category : 'private' }
PCRE2Matcher >> utf8InputFor: aStringOrInput [
	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2Matcher >> validateDFAWorkspaceSize: workspaceSize ovectorSize: ovectorSize [

	(workspaceSize isInteger and: [ workspaceSize >= 20 ]) ifFalse: [
		self error:
			'DFA workspace size must be an integer greater than or equal to 20' ].
	(ovectorSize isInteger and: [ ovectorSize >= 1 ]) ifFalse: [
		self error: 'DFA ovector size must be a positive integer' ]
]

{ #category : 'private' }
PCRE2Matcher >> validatePartialOption: partialOption [

	(partialOption = PCRE2 partialSoft or: [
		 partialOption = PCRE2 partialHard ]) ifFalse: [
		self error:
			'Partial matching option must be PCRE2 partialSoft or PCRE2 partialHard' ]
]

{ #category : 'private' }
PCRE2Matcher >> validateSubstitutionMatchData: aPCRE2Match [

	aPCRE2Match ifNil: [
		PCRE2Error signal:
			'Substitution match data must hold an external PCRE2 match data block' ].
	aPCRE2Match isPersistent ifTrue: [
		PCRE2Error signal:
			'Persistent match data cannot be passed back to pcre2_substitute_8' ].
	aPCRE2Match isNull ifTrue: [
		PCRE2Error signal:
			'Substitution match data must hold an external PCRE2 match data block' ].
	aPCRE2Match subject ifNil: [
		PCRE2Error signal:
			'Substitution match data must remember its subject bytes' ].
	aPCRE2Match isComplete ifFalse: [
		PCRE2Error signal:
			'Substitution match data must contain a complete match' ]
]

{ #category : 'private' }
PCRE2Matcher >> validateUsableMatchData: aPCRE2Match [

	(aPCRE2Match isPersistent or: [ aPCRE2Match isNull ]) ifTrue: [
		PCRE2Error signal:
			'Match data must hold an external PCRE2 match data block' ]
]

{ #category : 'callouts' }
PCRE2Matcher >> withAutomaticCallouts: calloutBlock do: aBlock [
	"Evaluate aBlock with a temporary matcher compiled with automatic callouts. This is intended for tools and diagnostics: it does not mutate the receiver, and it disables start optimization on the temporary matcher so generated callouts expose matching progress."

	| callbackMatcher |
	callbackMatcher := self
		                   temporaryMatcherAddingCompileOptions:
		                   (PCRE2 autoCallout bitOr: PCRE2 noStartOptimize)
		                   matchOptions: 0.
	callbackMatcher context calloutBlock: calloutBlock.
	^ [ aBlock cull: callbackMatcher ] ensure: [
		  callbackMatcher context clearCallout ]
]

{ #category : 'callouts' }
PCRE2Matcher >> withCallout: calloutBlock do: aBlock [
	"Evaluate aBlock with a temporary matcher whose match context invokes calloutBlock for runtime PCRE2 callouts. The callout block receives a PCRE2CalloutEvent and may answer an integer PCRE2 return code to control matching, or any non-integer value to continue."

	| callbackMatcher |
	callbackMatcher := self temporaryMatcherForCallout.
	callbackMatcher context calloutBlock: calloutBlock.
	^ [ aBlock cull: callbackMatcher ] ensure: [
		  callbackMatcher context clearCallout ]
]

{ #category : 'callouts' }
PCRE2Matcher >> withSubstituteCallout: calloutBlock do: aBlock [
	"Evaluate aBlock with a temporary matcher whose match context invokes calloutBlock after each processed pcre2_substitute_8 replacement. The callout block receives a PCRE2SubstitutionCalloutEvent and may answer a PCRE2 substitute-callout return code; non-integer answers accept the replacement."

	| callbackMatcher |
	callbackMatcher := self temporaryMatcherForCallout.
	callbackMatcher context substituteCalloutBlock: calloutBlock.
	^ [ aBlock cull: callbackMatcher ] ensure: [
		  callbackMatcher context clearSubstituteCallout ]
]

{ #category : 'callouts' }
PCRE2Matcher >> withSubstituteCaseCallout: caseBlock do: aBlock [
	"Evaluate aBlock with a temporary matcher whose match context lets caseBlock transform replacement case escapes such as \U, \L, \u, and \l. The case block receives a PCRE2SubstitutionCaseCalloutEvent and should answer transformed text."

	| callbackMatcher |
	callbackMatcher := self temporaryMatcherForCallout.
	callbackMatcher context substituteCaseCalloutBlock: caseBlock.
	^ [ aBlock cull: callbackMatcher ] ensure: [
		  callbackMatcher context clearSubstituteCaseCallout ]
]
