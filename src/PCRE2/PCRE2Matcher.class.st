"
I am a compiled regular expression pattern.
I represent a set of rules, called a regular expression (regex), that defines a search pattern for text.

Regular expressions are a powerful tool for string processing, enabling tasks such as searching for specific text, extracting substrings, and replacing text based on complex criteria. For instance, the pattern `\d+` matches one or more digits in a string, and `\w+@\w+\.\w+` can match a simple email format.


## Lifecycle

My lifecycle follows three main steps:

### Compilation
The process starts with a plain string that defines the regular expression. This string is compiled into a pattern using a `PCRE2Compiler`. During compilation, options such as case insensitivity or multi-line matching can be specified. The result is a compiled pattern stored in external memory, which is accessed by an instance of me. This pattern can additionally be Just-In-Time (JIT) compiled, generating machine code for significantly faster matches compared to the interpretive approach.

### Matching
The compiled pattern is then applied to a subject string. The matcher attempts to locate the specified pattern within the string. The match operation may return:
- A success, indicating that the pattern matches the string (or part of it).
- A failure, indicating no match.

### Querying
After a successful match, detailed information about the match can be queried. This mainly includes:
- The range (start and end positions) of the substring that matched the entire pattern.
- The ranges of substrings matched by parenthesized subexpressions (groups) within the pattern.
These queries are possible immediately after a successful match and before any subsequent match operation. Multiple queries can be performed without re-matching.


## API
The `PCRE2Matcher` API is organized into four main categories: **Matching**, **Querying**, **Match Enumeration**, and **Byte Matching**.

### Matching
Matching methods apply the compiled pattern to a subject string and return the result of an initial query. After each match, the matcher is ready for either more queries or another matching operation.
Basic matching methods include:
- `find:` returns the first matching substring within the subject.
- `matches:` returns whether the regex fully matches the subject.
- `search:` returns whether the regex partially matches the subject.

### Querying
Query methods can be called after any successful match to get detailed information about the match.
Examples include:
- `mark` returns the name of the last `(*MARK)`, `(*PRUNE)`, or `(*THEN)` encountered during the matching process.
- `startIndex` returns the index where the compiled pattern started matching.
Matching groups are usually returned by the appropriate matching methods, but they can also be accessed separately using query methods. For more details, see the `PCRE2Match` class.

### Match Enumeration
Match enumeration is the highest-level API. These methods iteratively apply match and query operations to a subject string until no more matches are found. This simplifies operations that need to process all matches in a subject. This includes methods such as `copy:replacingMatchesWith:` and `copy:translatingMatchesUsing:`, and other familiar methods from the Regex package.

### Byte Matching
Byte-matching methods provide a low-level API for operating directly on byte arrays representing UTF8-encoded string subjects. These methods are the basic building blocks for all other matching operations. They allow fine-grained control over matching within specific subranges of the subject. While not typically used by casual users, these methods are available for advanced scenarios.


## Implementation Details

### UTF Checking
The option for UTF support is enabled by default, see the `PCRE2Compiler` comment. Note that UTF validity checking can take time. If the same data string is to be matched many times, you can use the `noUTFCheck` option for the second and subsequent matches to avoid running redundant checks, like so: `regex addOptions: PCRE2 noUTFCheck`.

### JIT
If supported by the running architecture, I can be JIT-compiled. Just-In-Time compilation translates the pattern into machine code, significantly speeding up the matching process. The JIT status can be checked with `isJIT`. The size in memory of the JIT compiled code can be obtained using `regex info: PCRE2 infoJITSize`.

### Copying
A compiled pattern can be copied using the regular `copy` method. A new pattern object will be created by the compiler of the original pattern, with the same options, including the JIT compilation state.

### Matching Ranges
Most of the API does not support matching a specific range of the subject string. This limitation is due to the way string marshalling works with FFI: strings are always encoded as UTF8 `ByteArray`s before being processed. Consequently, passing a substring copy of the subject is more efficient than passing the entire subject, having it converted to UTF8, and then specifying a range within it. If you are already working with encoded strings, or if your scenario requires it, you can use the **Byte Matching** protocol methods that support ranges.
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
		'options'
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

	| encoder utfSubject lastIndex rs ws |
	encoder := ZnUTF8Encoder default.
	utfSubject := encoder encodeString: subject.
	lastIndex := 0.
	rs := ReadStream on: utfSubject.
	ws := WriteStream on: (ByteString new: 100).
	self
		matchAll: utfSubject
		from: 1
		to: utfSubject size
		do: [ :match |
			| start |
			rs position: lastIndex.
			start := match startOffsetAt: 1.
			lastIndex := match endOffsetAt: 1.
			[ rs position < start ] whileTrue: [
				ws nextPut: (encoder nextFromStream: rs) ].
			aBlock
				value: ws
				value: utfSubject
				value: start + 1
				value: lastIndex ].

	rs position: lastIndex.
	[ rs atEnd ] whileFalse: [ ws nextPut: (encoder nextFromStream: rs) ].
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
	"Copy the subject replacing each match by evaluating aBlock with the matched substring.
	Expect the block to answer a String, and replace the match with the answer."

	^ self copy: subject matchesDo: [ :ws :utfSubject :start :end |
		  ws nextPutAll: (aBlock value: (ZnUTF8Encoder default decodeBytes:
					    (utfSubject copyFrom: start to: end))) ]
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
	rc == -1 ifTrue: [ ^ nil ].
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
PCRE2Matcher >> findMatch: subject [
	"Returns standalone match data for the first matching substring, or nil."

	| input match |
	input := self utf8InputFor: subject.
	match := self matchBytes: input bytes from: 1 to: input size.
	match ifNotNil: [ input recordOn: match ].
	^ match
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
	"Initialize matcher-local options. Match data is created per match operation."

	options := 0
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
	"Run pcre2_jit_match_8 on a prepared UTF-8 subject buffer and write offsets into the provided match data. Use void* for the subject because encoding and lifetime are managed explicitly before the FFI call."

	"int pcre2_jit_match_8(const pcre2_code *code, PCRE2_SPTR subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data *match_data, pcre2_match_context *mcontext)"

	self ffiCall:
		#( int pcre2_jit_match_8 #( self #, void #* subject #, size_t end
		      #, size_t start #, uint32 options #, PCRE2Match #* aMatchData
		      #, void #* context ) )
]

{ #category : 'querying' }
PCRE2Matcher >> mark [
	"Matchers no longer keep the last match. Query mark on the returned PCRE2Match."

	self error:
		'PCRE2Matcher no longer keeps the last match; query mark on the returned PCRE2Match'
]

{ #category : 'private' }
PCRE2Matcher >> match: subject from: start to: end matchData: aMatchData [
	"Run pcre2_match_8 on a prepared UTF-8 subject buffer and write offsets into the provided match data. Use void* for the subject because encoding and lifetime are managed explicitly before the FFI call."

	"int pcre2_match_8(const pcre2_code *code, PCRE2_SPTR subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data *match_data, pcre2_match_context *mcontext)"

	self ffiCall:
		#( int pcre2_match_8 #( self #, void #* subject #, size_t end #, size_t
		      start #, uint32 options #, PCRE2Match #* aMatchData #, void
		      #* context ) )
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
	rc == -1 ifTrue: [ ^ nil ].
	match subject: subject decoder: nil.
	^ match
]

{ #category : 'byte matching' }
PCRE2Matcher >> matchBytes: subject from: start to: end into: aPCRE2Match [
	"Run a match over a UTF-encoded subject range and populate caller-provided match data."

	| rc |
	self validateUsableMatchData: aPCRE2Match.
	aPCRE2Match reset.

	rc := isJIT
		      ifFalse: [
			      self
				      match: subject
				      from: start - 1
				      to: end
				      matchData: aPCRE2Match ]
		      ifTrue: [
			      self
				      jitMatch: subject
				      from: start - 1
				      to: end
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
	"Returns whether the regex matches the start of the subject."

	| input match |
	input := self utf8InputFor: subject.
	match := self matchBytes: input bytes from: 1 to: input size.
	match ifNil: [ ^ false ].
	match offsetsDo: [ :start :end | ^ start == 1 ].
	^ false
]

{ #category : 'matching' }
PCRE2Matcher >> matchingRangesIn: subject [
	"Equivalent of RxMatcher >> #matchingRangesIn:"

	| ranges |
	self shouldBeImplemented. "requires utf offset when decoding"
	ranges := OrderedCollection new.
	self findAll: subject do: [  ].
	^ ranges
]

{ #category : 'documentation' }
PCRE2Matcher >> namedGroups [
	"Returns the table of named capture groups associated to their index
	Because multiple groups can have the same name when using dupNames compile option, the index is used as the key"

	| table buffer rc count entrySize |
	buffer := ByteArray new: 4.

	"get the number of named capture groups"
	rc := self info: PCRE2 infoNameCount output: buffer.
	rc < 0 ifTrue: [ self errorCode: rc ].
	(count := buffer uint32AtOffset: 0) = 0 ifTrue: [ ^ {  } ].

	"get the size of each name table entry"
	rc := self info: PCRE2 infoNameEntrySize output: buffer.
	rc < 0 ifTrue: [ self errorCode: rc ].
	entrySize := buffer uint32AtOffset: 0.

	"get the name table"
	buffer := ByteArray new: ExternalAddress wordSize.
	rc := self info: PCRE2 infoNameTable output: buffer.
	rc < 0 ifTrue: [ self errorCode: rc ].
	buffer := buffer pointerAtOffset: 0. "buffer is a pointer to the name table"

	"each entry begins with a uint16 for the index, followed by the name as a C string"
	table := Array new: count.
	1 to: count do: [ :i |
		| offset index name |
		offset := entrySize * (i - 1).
		"index is encoded as `(entry[0] << 8) | entry[1]`"
		index := ((buffer uint8AtOffset: offset) bitShift: 8) bitOr:
			         (buffer uint8AtOffset: (offset := offset + 1)).
		name := ByteArray new: entrySize - 3 streamContents: [ :s |
			        | char |
			        [
			        (char := buffer uint8AtOffset: (offset := offset + 1)) == 0 ]
				        whileFalse: [ s nextPut: char ] ].
		table at: index put: name utf8Decoded ].
	^ table
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

{ #category : 'accessing' }
PCRE2Matcher >> pattern [
	"The original string of this compiled pattern"

	^ pattern
]

{ #category : 'accessing' }
PCRE2Matcher >> pattern: aString [
	"Must only be used by the compiler"

	pattern := aString
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

	rc > 0 ifTrue: [
		aPCRE2Match count: rc.
		^ rc ].

	rc == -2 ifTrue: [
		aPCRE2Match count: 1.
		^ rc ].

	aPCRE2Match count: 0.
	rc == -1 ifTrue: [ ^ rc ].

	rc == 0 ifTrue: [
		PCRE2Error signal:
			'Not enough match data ovector slots to store DFA results' ].

	self errorCode: rc
]

{ #category : 'private' }
PCRE2Matcher >> recordMatchResult: rc in: aPCRE2Match [

	rc > 0 ifTrue: [
		aPCRE2Match count: rc.
		^ rc ].

	rc == -2 ifTrue: [
		aPCRE2Match count: 1.
		^ rc ].

	aPCRE2Match count: 0.
	rc == -1 ifTrue: [ ^ rc ].

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

{ #category : 'querying' }
PCRE2Matcher >> startIndex [
	"Matchers no longer keep the last match. Query startIndex on the returned PCRE2Match."

	self error:
		'PCRE2Matcher no longer keeps the last match; query startIndex on the returned PCRE2Match'
]

{ #category : 'private' }
PCRE2Matcher >> substitute: subject from: start to: end replacement: replacement upTo: rLength output: buffer size: outSize [
	"Apply substitutions into caller-provided output storage. Subject, replacement, and output are prepared byte buffers, so use void* for them and let PCRE2 handle the bytes exactly as supplied."

	"int pcre2_substitute_8(const pcre2_code *code, PCRE2_SPTR subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data *match_data, pcre2_match_context *mcontext, PCRE2_SPTR replacement, PCRE2_SIZE rlength, PCRE2_UCHAR *outputbuffer, PCRE2_SIZE *outlengthptr)"

	self ffiCall:
		#( int pcre2_substitute_8 #( self #, void #* subject #, size_t
		      end #, size_t start #, uint32 options #, nil #, void #* context
		      #, void #* replacement #, size_t rLength #, void #* buffer
		      #, SizeTHolder outSize ) )
]

{ #category : 'matching' }
PCRE2Matcher >> substitute: subject with: replacement [
	"Returns the subject with each match substituted with the replacement.
	The replacement string is treated as a regex substitution expression
	that can reference captured groups or use conditional substitutions."

	| encoder utfSubject utfReplacement buffer bufferSize rc |
	encoder := ZnUTF8Encoder default.
	utfSubject := encoder encodeString: subject.
	utfReplacement := encoder encodeString: replacement.
	"Arbitrary buffer size that allows a first-shot on short results.
	If the size is too small and the substituteOverflowLength option is set,
	the second shot will succeed unless the VM is out of memory."
	buffer := ByteArray new: (bufferSize := 4096).
	bufferSize := SizeTHolder new value: bufferSize.

	"matchData can be nil and will be created and freed during the ffi call"
	rc := self
		      substitute: utfSubject
		      from: 0
		      to: utfSubject size
		      replacement: utfReplacement
		      upTo: utfReplacement size
		      output: buffer
		      size: bufferSize.
	">= 0 number of substitutions made"
	rc < 0 ifTrue: [
		(rc == -48 and: [ "noMemory & substituteOverflowLength => updated bufferSize"
			 (options bitAnd: 4096) == 4096 ]) ifFalse: [ self errorCode: rc ].

		"second shot should always be correct"
		rc := self
			      substitute: utfSubject
			      from: 0
			      to: utfSubject size
			      replacement: utfReplacement
			      upTo: utfReplacement size
			      output: (buffer := ByteArray new: bufferSize value)
			      size: bufferSize.
		rc < 0 ifTrue: [ self errorCode: rc ] ].

	^ (String new: (bufferSize := bufferSize value))
		  replaceFrom: 1
		  to: bufferSize
		  with: buffer
		  startingAt: 1
]

{ #category : 'private' }
PCRE2Matcher >> utf8InputFor: aString [

	^ PCRE2UTF8Input fromString: aString
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
PCRE2Matcher >> validateUsableMatchData: aPCRE2Match [

	(aPCRE2Match isPersistent or: [ aPCRE2Match isNull ]) ifTrue: [
		PCRE2Error signal:
			'Match data must hold an external PCRE2 match data block' ]
]
