"
I wrap a compiled PCRE2 pattern and provide the public matching API.

High-level methods accept normal Pharo strings and prepared `PCRE2UTF8Input` instances. Strings are prepared as UTF-8 bytes before calling PCRE2; ASCII ByteStrings can be reused directly, while other strings are encoded and decoded through Zinc.

Match operations create standalone `PCRE2Match` objects. The matcher does not own a reusable match result; callers may keep the returned match data and ask it for the matched text, groups, offsets, mark, partial/complete status, or persistence later.

The API has three layers:
- Convenience matching such as `matches:`, `matchesPrefix:`, `search:`, `find:`, `findWithGroups:`, and `findPartialMatch:`.
- Enumeration, splitting, and rewriting such as `findAll:`, `split:indicesDo:`, `copy:replacingMatchesWith:`, `copy:translatingMatchesUsing:`, and `substitute:with:`.
- Byte-level operations such as `matchBytes:from:to:` and DFA matching for callers that already manage UTF-8 storage and offsets.

Instances may be JIT-compiled when the native library supports it. Lifecycle restoration is handled by `PCRE2SessionManager`, which either deserializes compatible native codes or recompiles from the recorded pattern and options.
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

{ #category : 'compiling' }
PCRE2Matcher >> compileJIT [
	"Request JIT compilation for this compiled pattern using the compiler options.
	If supported and unless reconfigured, patterns are JIT-compiled by default."

	compiler compileJIT: self
]

{ #category : 'compiling' }
PCRE2Matcher >> compileJIT: anInteger [
	"Request JIT (re-)compilation for this compiled pattern.
	If supported and unless reconfigured, patterns are JIT-compiled by default.
	The available options are jitComplete, jitPartialSoft and jitPartialHard."

	| newCompiler |
	(newCompiler := PCRE2Compiler new)
		options: compiler options;
		context: compiler context;
		optionsJIT: anInteger;
		compileJIT: self.
	compiler := newCompiler
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
	"Copy the subject and execute a block for each match."

	| input lastIndex rs ws |
	input := self utf8InputFor: subject.
	lastIndex := 0.
	rs := ReadStream on: input bytes.
	ws := WriteStream on: (String new: 100).
	self
		matchAll: input bytes
		from: 1
		to: input size
		do: [ :match |
			| start |
			rs position: lastIndex.
			start := match startOffsetAt: 1.
			lastIndex := match endOffsetAt: 1.
			[ rs position < start ] whileTrue: [
				ws nextPut: (input nextFromStream: rs) ].
			aBlock
				value: ws
				value: input bytes
				value: start + 1
				value: lastIndex ].

	rs position: lastIndex.
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
	input := self utf8InputFor: subject.
	^ self copy: input matchesDo: [ :ws :utfSubject :start :end |
		  ws nextPutAll: (aBlock value:
				   (input decodeBytes: (utfSubject copyFrom: start to: end))) ]
]

{ #category : 'private' }
PCRE2Matcher >> createMatchContext [
	"This function creates and initializes a new match context.
	If its argument is NULL, malloc() is used to get the necessary memory; otherwise the memory allocation function within the general context is used.
	The result is NULL if the memory could not be obtained."

	self ffiCall: #(PCRE2MatchContext *pcre2_match_context_create_8(nil))
]

{ #category : 'private' }
PCRE2Matcher >> createMatchDataFromPattern [
	"Create a new match data structure with enough space to store the offsets of the match and all capture groups"

	"pcre2_match_data *pcre2_match_data_create_from_pattern(const pcre2_code *code, pcre2_general_context *gcontext)"

	self ffiCall: #(void *pcre2_match_data_create_from_pattern_8(self, nil))
]

{ #category : 'private' }
PCRE2Matcher >> createMatchDataWithOvectorSize: ovectorSize [
	"Create a new match data structure with room for an explicit number of offset pairs."

	"pcre2_match_data *pcre2_match_data_create(uint32_t ovecsize, pcre2_general_context *gcontext)"

	self ffiCall:
		#( void #* pcre2_match_data_create_8 #( uint32 ovectorSize
		      #, nil ) )
]

{ #category : 'private' }
PCRE2Matcher >> decodeUTF8Output: buffer upTo: byteSize [
	"Decode a PCRE2 UTF-8 output buffer back to a Pharo string."

	byteSize = 0 ifTrue: [ ^ String new ].
	^ ZnUTF8Encoder default decodeBytes:
		  (buffer copyFrom: 1 to: byteSize)
]

{ #category : 'matching' }
PCRE2Matcher >> dfaMatch: subject [
	"Run a DFA match and answer all same-start alternatives as standalone match data."

	^ self dfaMatch: subject workspaceSize: 100
]

{ #category : 'private' }
PCRE2Matcher >> dfaMatch: subject from: start to: end matchData: aMatchData workspace: workspace size: workspaceSize [
	"Run a DFA match with caller-managed match data and workspace storage. Subject and workspace are prepared raw buffers, so both use void* to avoid UFFI element/string conversion."

	"int pcre2_dfa_match_8(const pcre2_code *code, PCRE2_SPTR subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data *match_data, pcre2_match_context *mcontext, int *workspace, PCRE2_SIZE wscount)"

	self ffiCall:
		#( int pcre2_dfa_match_8 #( self #, void #* subject #, size_t end
		      #, size_t start #, uint32 options #, PCRE2Match #* aMatchData
		      #, void #* context #, void #* workspace #, size_t workspaceSize ) )
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
	input := self utf8InputFor: subject.
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
	"Run a DFA match over a UTF-8 encoded subject and answer standalone match data, or nil."

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
	"Run a DFA match over a UTF-8 encoded subject and populate caller-provided match data."

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

{ #category : 'match enumeration' }
PCRE2Matcher >> findAll: subject [
	"Returns all matching substrings within the subject."

	| input result |
	result := OrderedCollection new.
	input := self utf8InputFor: subject.
	self
		matchAll: input bytes
		from: 1
		to: input size
		do: [ :match |
			input recordOn: match.
			result add: match readMatch ].
	^ result
]

{ #category : 'match enumeration' }
PCRE2Matcher >> findAll: subject do: aBlock [
	"Iterate over all matching substrings within the subject."

	| input |
	input := self utf8InputFor: subject.
	self
		matchAll: input bytes
		from: 1
		to: input size
		do: [ :match |
			input recordOn: match.
			aBlock value: match readMatch ]
]

{ #category : 'match enumeration' }
PCRE2Matcher >> findAllWithGroups: subject [
	"Returns all matching substrings and groups within the subject."

	| input result |
	result := OrderedCollection new.
	input := self utf8InputFor: subject.
	self
		matchAll: input bytes
		from: 1
		to: input size
		do: [ :match |
			input recordOn: match.
			result add: match readMatches ].
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
	input := self utf8InputFor: subject.
	match := self matchBytes: input bytes from: 1 to: input size.
	match ifNotNil: [ input recordOn: match ].
	^ match
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
	input := self utf8InputFor: subject.
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

	self ffiCall: #(void pcre2_code_free_8(self))
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

	"int pcre2_pattern_info(const pcre2_code *code, uint32_t what, void *where)"

	self ffiCall: #(int pcre2_pattern_info_8(self, uint32 what, void *where))
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
PCRE2Matcher >> jitMatch: subject from: start to: end matchData: aMatchData [
	"Run pcre2_jit_match_8 with the matcher's current match options."

	^ self
		  jitMatch: subject
		  from: start
		  to: end
		  options: options
		  matchData: aMatchData
]

{ #category : 'private' }
PCRE2Matcher >> jitMatch: subject from: start to: end options: matchOptions matchData: aMatchData [
	"Run pcre2_jit_match_8 on a prepared UTF-8 subject buffer and write offsets into the provided match data. Use void* for the subject because encoding and lifetime are managed explicitly before the FFI call."

	"int pcre2_jit_match_8(const pcre2_code *code, PCRE2_SPTR subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data *match_data, pcre2_match_context *mcontext)"

	self ffiCall:
		#( int pcre2_jit_match_8 #( self #, void #* subject #, size_t end
		      #, size_t start #, uint32 matchOptions #, PCRE2Match
		      #* aMatchData #, void #* context ) )
]

{ #category : 'querying' }
PCRE2Matcher >> mark [
	"Matchers no longer keep the last match. Query mark on the returned PCRE2Match."

	self error:
		'PCRE2Matcher no longer keeps the last match; query mark on the returned PCRE2Match'
]

{ #category : 'private' }
PCRE2Matcher >> match: subject from: start to: end matchData: aMatchData [
	"Run pcre2_match_8 with the matcher's current match options."

	^ self
		  match: subject
		  from: start
		  to: end
		  options: options
		  matchData: aMatchData
]

{ #category : 'private' }
PCRE2Matcher >> match: subject from: start to: end options: matchOptions matchData: aMatchData [
	"Run pcre2_match_8 on a prepared UTF-8 subject buffer and write offsets into the provided match data. Use void* for the subject because encoding and lifetime are managed explicitly before the FFI call."

	"int pcre2_match_8(const pcre2_code *code, PCRE2_SPTR subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data *match_data, pcre2_match_context *mcontext)"

	self ffiCall:
		#( int pcre2_match_8 #( self #, void #* subject #, size_t end #, size_t
		      start #, uint32 matchOptions #, PCRE2Match #* aMatchData
		      #, void #* context ) )
]

{ #category : 'byte matching' }
PCRE2Matcher >> matchAll: subject from: start to: end do: aBlock [
	"Iteratively match over a range of the subject and execute aBlock with each standalone match."

	| match offset |
	offset := start.
	[
	offset > end or: [
		(match := self matchBytes: subject from: offset to: end) isNil ] ]
		whileFalse: [
			offset := match lastMatchIndex + 1.
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
	input := self utf8InputFor: subject.
	match := self matchBytes: input bytes from: 1 to: input size.
	match ifNil: [ ^ false ].
	match isPartial ifTrue: [ ^ false ].
	match offsetsDo: [ :start :end |
		^ start == 1 and: [ end == input size ] ].
	^ false
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
	input := self utf8InputFor: subject.
	match := self matchBytes: input bytes from: 1 to: input size.
	match ifNil: [ ^ false ].
	match isPartial ifTrue: [ ^ false ].
	match offsetsDo: [ :start :end | ^ start == 1 ].
	^ false
]

{ #category : 'match enumeration' }
PCRE2Matcher >> matchingRangesIn: subject [
	"Answer ranges of each match as 1-based Pharo character intervals."

	| input ranges |
	input := self utf8InputFor: subject.
	ranges := OrderedCollection new.
	self
		matchAll: input bytes
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
	^ (PCRE2Match fromHandle: pointer) initialize autoRelease
]

{ #category : 'external resource management' }
PCRE2Matcher >> newMatchDataWithOvectorSize: ovectorSize [
	"Create match data with an explicit number of offset pairs."

	| pointer |
	pointer := self createMatchDataWithOvectorSize: ovectorSize.
	pointer isNull ifTrue: [
		PCRE2Error signal: 'Failed to obtain memory to create match data' ].
	^ (PCRE2Match fromHandle: pointer) initialize autoRelease
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
PCRE2Matcher >> privateCopy [
	"This function makes a copy of the memory used for a compiled pattern, excluding any memory used by the JIT compiler.
	Without a subsequent call to jit_compile(), the copy can be used only for non-JIT matching.
	The pointer to the character tables is copied, not the tables themselves (see pcre2_code_copy_with_tables()).
	The yield of the function is NULL if code is NULL or if sufficient memory cannot be obtained."

	self ffiCall: #(void *pcre2_code_copy_8(self))
]

{ #category : 'private' }
PCRE2Matcher >> readNamedGroups [
	"Read PCRE2's name table into a sparse Array keyed by capture group number."

	| buffer captureCount entrySize nameCount rc table |
	buffer := ByteArray new: 4.

	rc := self info: PCRE2 infoNameCount output: buffer.
	rc < 0 ifTrue: [ self errorCode: rc ].
	(nameCount := buffer uint32AtOffset: 0) = 0 ifTrue: [ ^ #(  ) ].

	captureCount := self info: PCRE2 infoCaptureCount.
	table := Array new: captureCount.

	rc := self info: PCRE2 infoNameEntrySize output: buffer.
	rc < 0 ifTrue: [ self errorCode: rc ].
	entrySize := buffer uint32AtOffset: 0.

	buffer := ByteArray new: ExternalAddress wordSize.
	rc := self info: PCRE2 infoNameTable output: buffer.
	rc < 0 ifTrue: [ self errorCode: rc ].
	buffer := buffer pointerAtOffset: 0.

	1 to: nameCount do: [ :i |
		| captureIndex name offset |
		offset := entrySize * (i - 1).
		captureIndex := ((buffer uint8AtOffset: offset) bitShift: 8) bitOr:
			                (buffer uint8AtOffset: (offset := offset + 1)).
		name := ByteArray new: entrySize - 3 streamContents: [ :stream |
			        | char |
			        [
			        (char := buffer uint8AtOffset: (offset := offset + 1)) = 0 ]
				        whileFalse: [ stream nextPut: char ] ].
		table at: captureIndex put: name utf8Decoded ].
	^ table
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
	"This method is for convenience, it is much more effective to serialize matchers in bulk"

	LibPCRE2 restore: { self } from: bytes
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

{ #category : 'persistence' }
PCRE2Matcher >> serialize [
	"Serialize the external memory of the matcher structure, excluding JIT code.
	This method is for convenience, it is much more effective to serialize matchers in bulk,
	both in terms of speed and memory, since the character table (1088 bytes) is encoded in the result."

	^ LibPCRE2 serialize: { self }
]

{ #category : 'splitjoin' }
PCRE2Matcher >> split: subject indicesDo: aBlock [
	"Split subject on my matches, evaluating aBlock with each kept 1-based Pharo character range. Regex delimiters must consume at least one byte."

	| input lastEndOffset match nextStart subjectEnd |
	input := self utf8InputFor: subject.
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
	"Dispatch pcre2_substitute_8 with or without caller-supplied match data. A nil match data lets PCRE2 perform the match; a non-nil match data is used with PCRE2 substituteMatched."

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
	"Apply substitutions into caller-provided output storage using precomputed match data for the first match. Subject, replacement, and output are prepared byte buffers, so use void* for them and let PCRE2 handle the bytes exactly as supplied."

	"int pcre2_substitute_8(const pcre2_code *code, PCRE2_SPTR subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data *match_data, pcre2_match_context *mcontext, PCRE2_SPTR replacement, PCRE2_SIZE rlength, PCRE2_UCHAR *outputbuffer, PCRE2_SIZE *outlengthptr)"

	self ffiCall:
		#( int pcre2_substitute_8 #( self #, void #* subject #, size_t
		      end #, size_t start #, uint32 substituteOptions
		      #, PCRE2Match #* aPCRE2Match #, void #* context #, void #* replacement
		      #, size_t rLength #, void #* buffer #, SizeTHolder outSize ) )
]

{ #category : 'private' }
PCRE2Matcher >> substitute: subject from: start to: end options: substituteOptions replacement: replacement upTo: rLength output: buffer size: outSize [
	"Apply substitutions into caller-provided output storage without precomputed match data. Subject, replacement, and output are prepared byte buffers, so use void* for them and let PCRE2 handle the bytes exactly as supplied."

	"int pcre2_substitute_8(const pcre2_code *code, PCRE2_SPTR subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data *match_data, pcre2_match_context *mcontext, PCRE2_SPTR replacement, PCRE2_SIZE rlength, PCRE2_UCHAR *outputbuffer, PCRE2_SIZE *outlengthptr)"

	self ffiCall:
		#( int pcre2_substitute_8 #( self #, void #* subject #, size_t
		      end #, size_t start #, uint32 substituteOptions
		      #, nil #, void #* context #, void #* replacement #, size_t
		      rLength #, void #* buffer #, SizeTHolder outSize ) )
]

{ #category : 'private' }
PCRE2Matcher >> substitute: subject from: start to: end replacement: replacement upTo: rLength output: buffer size: outSize [
	"Backward-compatible private entry using the matcher substitution options sanitized for pcre2_substitute_8. Subject, replacement, and output are prepared byte buffers, so use void* for them and let PCRE2 handle the bytes exactly as supplied."

	^ self
		  substitute: subject
		  from: start
		  to: end
		  options: self substitutionOptions
		  replacement: replacement
		  upTo: rLength
		  output: buffer
		  size: outSize
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

{ #category : 'matching' }
PCRE2Matcher >> substitute: subject with: replacement options: substituteOptions [
	"Answer subject with substitutions applied using the supplied PCRE2 substitution options instead of the matcher options. PCRE2 treats replacement as a substitution expression unless PCRE2 substituteLiteral is set. The implementation may add PCRE2 substituteOverflowLength internally to size the output buffer."

	^ self
		  substitute: subject
		  with: replacement
		  options: substituteOptions
		  matchData: nil
]

{ #category : 'private' }
PCRE2Matcher >> substitute: subject with: replacement options: substituteOptions matchData: aPCRE2Match [
	"Private helper for pcre2_substitute_8. Encode a normal subject or reuse a prepared UTF-8 input, then pass optional PCRE2 match data to the byte-level helper."

	| input |
	input := self utf8InputFor: subject.
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
	"Apply pcre2_substitute_8 to prepared subject bytes. Automatically enable PCRE2 substituteOverflowLength so large outputs can be retried with the exact required buffer size."

	| buffer bufferSize effectiveOptions rc replacementInput |
	replacementInput := self utf8InputFor: replacement.
	effectiveOptions := substituteOptions bitOr:
		                    PCRE2 substituteOverflowLength.
	buffer := ByteArray new: (bufferSize := 4096).
	bufferSize := SizeTHolder new value: bufferSize.

	rc := self
		      substitute: subjectBytes
		      from: 0
		      to: subjectBytes size
		      options: effectiveOptions
		      matchData: aPCRE2Match
		      replacement: replacementInput bytes
		      upTo: replacementInput size
		      output: buffer
		      size: bufferSize.

	rc < 0 ifTrue: [
		rc == PCRE2 errorNoMemory ifFalse: [ self errorCode: rc ].
		rc := self
			      substitute: subjectBytes
			      from: 0
			      to: subjectBytes size
			      options: effectiveOptions
			      matchData: aPCRE2Match
			      replacement: replacementInput bytes
			      upTo: replacementInput size
			      output: (buffer := ByteArray new: bufferSize value)
			      size: bufferSize.
		rc < 0 ifTrue: [ self errorCode: rc ] ].

	^ self decodeUTF8Output: buffer upTo: bufferSize value
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

{ #category : 'private' }
PCRE2Matcher >> substitutionOptions [
	"Answer matcher options that are safe to pass to pcre2_substitute_8. Partial matching options are not valid for substitution."

	^ options bitAnd: (PCRE2 partialSoft | PCRE2 partialHard) bitInvert
]

{ #category : 'private' }
PCRE2Matcher >> utf8InputFor: aStringOrInput [

	^ aStringOrInput asPCRE2UTF8Input
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
