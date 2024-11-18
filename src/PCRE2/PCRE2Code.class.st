"
I am a compiled regular expression pattern.
My goal is to help you find patterns within strings using a set of rules defined by a regular expression (regex).
A regex matcher allows you to search, match, and manipulate strings based on these predefined patterns.

### UTF Checking
The option for UTF support is enabled by default, see the `PCRE2Compiler` comment. Note that UTF validity checking can take time. If the same data string is to be matched many times, you can use the `noUTFCheck` option for the second and subsequent matches to avoid running redundant checks, like so: `regex addOptions: PCRE2 noUTFCheck`.

### JIT
If supported by the running architecture, I can be JIT-compiled (Just-In-Time compiled). JIT compilation translates the pattern into machine code, significantly speeding up the matching process. The JIT status can be checked with `PCRE2Code>>#isJIT`. The size in memory of the JIT compiled code can be obtained using `regex info: PCRE2 infoJITSize`.

### Copying
A compiled pattern can be copied with the regular `copy` method, excluding any memory used by the JIT compiler. Without a subsequent call to `PCRE2Code>>#compileJIT`, the copy can be used only for non-JIT matching.

### Matching Ranges
The main API does not provide support for matching a range of the subject due to the way string marshaling works with FFI. Strings are always encoded as UTF8 `ByteArray`s. Thus, making a copy of the range of the string to match is much more efficient than passing the whole string and specifying ranges. If you are already working directly with encoded strings, you can use the `match...` family of methods, which does support ranges.
"
Class {
	#name : 'PCRE2Code',
	#superclass : 'PCRE2Object',
	#traits : 'PCRE2TWithOptions',
	#classTraits : 'PCRE2TWithOptions classTrait',
	#instVars : [
		'pattern',
		'matchData',
		'context',
		'compiler',
		'isJIT'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'documentation' }
PCRE2Code >> allInfo [
	"Use `PCRE2 allInfoOnRegex:` for a human-readable format"

	^ (0 to: 26) collect: [ :i | self info: i ]
]

{ #category : 'persistence' }
PCRE2Code >> bePersistent [
	"Make the state of the matcher persistent between sessions"

	matchData ifNotNil: [ matchData bePersistent ]
]

{ #category : 'compiling' }
PCRE2Code >> compileJIT [
	"Request JIT compilation for this compiled pattern using the compiler options.
	If supported and unless reconfigured, patterns are JIT-compiled by default."

	compiler compileJIT: self
]

{ #category : 'compiling' }
PCRE2Code >> compileJIT: anInteger [
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
PCRE2Code >> compiler [
	"The compiler that processed this pattern"

	^ compiler
]

{ #category : 'accessing' }
PCRE2Code >> compiler: aPCRE2Compiler [
	"Should only be used by the compiler that processed this pattern"

	compiler := aPCRE2Compiler
]

{ #category : 'accessing' }
PCRE2Code >> context [

	^ context ifNil: [
		  context := self createMatchContext.
		  context isNull ifTrue: [
			  context := nil.
			  PCRE2Error signal:
				  'Failed to obtain memory to create match context' ].
		  context autoRelease ]
]

{ #category : 'accessing' }
PCRE2Code >> context: aMatchContext [

	context := aMatchContext
]

{ #category : 'enumerating' }
PCRE2Code >> copy: subject matchesDo: aBlock [
	"Copy the subject and execute a block for each match"

	| encoder utfSubject lastIndex rs ws |
	encoder := ZnUTF8Encoder default.
	utfSubject := encoder encodeString: subject.
	lastIndex := 0.
	rs := ReadStream on: utfSubject.
	ws := WriteStream on: (String new: 100).
	self
		matchAll: utfSubject
		from: 1
		to: utfSubject size
		do: [
			| start |
			rs position: lastIndex.
			start := matchData startOffsetAt: 1.
			lastIndex := matchData endOffsetAt: 1.
			[ rs position < start ] whileTrue: [ "copy unmatched range"
				ws nextPut: (encoder nextFromStream: rs) ].
			"normalize the start-end range: [n-1,m) -> [n,m]"
			aBlock
				value: ws
				value: utfSubject
				value: start + 1
				value: lastIndex ].

	rs position: lastIndex.
	[ rs atEnd ] whileFalse: [ "copy from last match to end"
		ws nextPut: (encoder nextFromStream: rs) ].
	^ ws contents
]

{ #category : 'copying' }
PCRE2Code >> copy: subject replacingMatchesWith: aString [
	"Copy the subject replacing each match with aString"

	^ self
		  copy: subject
		  matchesDo: [ :ws :utfSubject :start :end | ws nextPutAll: aString ]
]

{ #category : 'copying' }
PCRE2Code >> copy: subject translatingMatchesUsing: aBlock [
	"Copy the subject replacing each match by evaluating aBlock with the matched substring.
	Expect the block to answer a String, and replace the match with the answer."

	^ self copy: subject matchesDo: [ :ws :utfSubject :start :end |
		  ws nextPutAll:
			  (aBlock value: (utfSubject copyFrom: start to: end)) ]
]

{ #category : 'private' }
PCRE2Code >> createMatchContext [
	"This function creates and initializes a new match context.
	If its argument is NULL, malloc() is used to get the necessary memory; otherwise the memory allocation function within the general context is used.
	The result is NULL if the memory could not be obtained."

	self ffiCall: #(PCRE2MatchContext *pcre2_match_context_create_8(nil))
]

{ #category : 'private' }
PCRE2Code >> createMatchDataFromPattern [
	"Create a new match data structure with enough space to store the offsets of the match and all capture groups"

	"pcre2_match_data *pcre2_match_data_create_from_pattern(const pcre2_code *code, pcre2_general_context *gcontext)"

	self ffiCall: #(void *pcre2_match_data_create_from_pattern_8(self, nil))
]

{ #category : 'error handling' }
PCRE2Code >> errorCode: errorCode [

	<debuggerCompleteToSender>
	PCRE2MatchError signal: (PCRE2 translateErrorCode: errorCode)
]

{ #category : 'matching' }
PCRE2Code >> find: subject [
	"Returns the first matching substring within the subject"

	| encoder utfSubject |
	encoder := ZnUTF8Encoder default.
	utfSubject := encoder encodeString: subject.
	self matchBytes: utfSubject from: 1 to: utfSubject size.
	^ (matchData readMatch: utfSubject) ifNotNil: [ :match |
		  encoder decodeBytes: match ]
]

{ #category : 'matching' }
PCRE2Code >> findAll: subject [
	"Returns all matching substrings within the subject"

	| result encoder utfSubject |
	result := OrderedCollection new.
	encoder := ZnUTF8Encoder default.
	utfSubject := encoder encodeString: subject.
	self
		matchAll: utfSubject
		from: 1
		to: utfSubject size
		do: [
			result add:
				(encoder decodeBytes: (matchData readMatch: utfSubject)) ].
	^ result
]

{ #category : 'matching' }
PCRE2Code >> findAll: subject do: aBlock [
	"Iterate over all matching substrings within the subject"

	| encoder utfSubject |
	encoder := ZnUTF8Encoder default.
	utfSubject := encoder encodeString: subject.
	self
		matchAll: utfSubject
		from: 1
		to: utfSubject size
		do: [
			aBlock value:
				(encoder decodeBytes: (matchData readMatch: utfSubject)) ]
]

{ #category : 'matching' }
PCRE2Code >> findAllWithGroups: subject [
	"Returns all matching substrings within the subject"

	| result encoder utfSubject |
	result := OrderedCollection new.
	encoder := ZnUTF8Encoder default.
	utfSubject := encoder encodeString: subject.
	self
		matchAll: utfSubject
		from: 1
		to: utfSubject size
		do: [
		result add: (matchData readMatches: utfSubject decodeWith: encoder) ].
	^ result
]

{ #category : 'matching' }
PCRE2Code >> findWithGroups: subject [
	"Returns the first matching substring and groups within the subject"

	| encoder utfSubject |
	encoder := ZnUTF8Encoder default.
	utfSubject := encoder encodeString: subject.
	self matchBytes: utfSubject from: 1 to: utfSubject size.
	^ matchData readMatches: utfSubject decodeWith: encoder
]

{ #category : 'initialize-release' }
PCRE2Code >> free [

	self ffiCall: #(void pcre2_code_free_8(self))
]

{ #category : 'documentation' }
PCRE2Code >> info: option [
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
PCRE2Code >> info: what output: where [

	"int pcre2_pattern_info(const pcre2_code *code, uint32_t what, void *where)"

	self ffiCall: #(int pcre2_pattern_info_8(self, uint32 what, void *where))
]

{ #category : 'initialization' }
PCRE2Code >> initialize [
	"Create a default match data in advance based on the pattern.
	This is what is expected for the vast majority of cases."

	options := 0.
	self useMatchDataFromPattern
]

{ #category : 'accessing' }
PCRE2Code >> isJIT [

	^ isJIT
]

{ #category : 'accessing' }
PCRE2Code >> isJIT: aBoolean [
	"Indicates whether the pattern is JIT-compiled.
	Can be set to false if using match() over the jit_match() fast path is required for additional validity checks,
	and if the pattern is JIT-compiled, the fast machine code is still used.
	Setting to true when the pattern is not really JIT-compiled will cause matches to throw an error."

	isJIT := aBoolean and: [ compiler optionsJIT ~~ 0 ]
]

{ #category : 'private' }
PCRE2Code >> jitMatch: subject from: start to: end [
"This function runs a JIT pattern match.

Arguments:
  code            points to the compiled expression
  subject         points to the subject string
  length          length of subject string (may contain binary zeros)
  start_offset    where to start in the subject string
  options         option bits
  match_data      points to a match_data block
  mcontext        points to a match context

Returns:          > 0 => success; value is the number of ovector pairs filled
                  = 0 => success, but ovector is not big enough
                   -1 => failed to match (PCRE_ERROR_NOMATCH)
                 < -1 => some kind of unexpected problem"

	"int pcre2_jit_match(const pcre2_code *code, PCRE2_SPTR subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data *match_data, pcre2_match_context *mcontext)"
	
	self ffiCall: #(int pcre2_jit_match_8(self, char *subject, size_t end, size_t start, uint32 options, PCRE2Match *matchData, void *context))
]

{ #category : 'private' }
PCRE2Code >> mark [
	"The name of the last (*MARK), (*PRUNE), or (*THEN) that was encountered during the matching process"

	^ matchData ifNotNil: [ matchData mark ]
]

{ #category : 'private' }
PCRE2Code >> match: subject from: start to: end [
"This function applies a compiled pattern to a subject string and picks out
portions of the string if it matches. Two elements in the vector are set for
each substring: the offsets to the start and end of the substring.

Arguments:
  code            points to the compiled expression
  subject         points to the subject string
  length          length of subject string (may contain binary zeros)
  start_offset    where to start in the subject string
  options         option bits
  match_data      points to a match_data block
  mcontext        points a PCRE2 context

Returns:          > 0 => success; value is the number of ovector pairs filled
                  = 0 => success, but ovector is not big enough
                  = -1 => failed to match (PCRE2_ERROR_NOMATCH)
                  = -2 => partial match (PCRE2_ERROR_PARTIAL)
                  < -2 => some kind of unexpected problem"

	"int pcre2_match(const pcre2_code *code, PCRE2_SPTR subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data *match_data, pcre2_match_context *mcontext)"

	self ffiCall: #(int pcre2_match_8(self, char *subject, size_t end, size_t start, uint32 options, PCRE2Match *matchData, void *context))
]

{ #category : 'private' }
PCRE2Code >> matchAll: subject from: start to: end do: aBlock [
	"Iteratively match over a range of the subject and execute a block after each successful match"

	| offset |
	offset := start.
	[
	offset > end or: [
		(self matchBytes: subject from: offset to: end) == -1 ] ]
		whileFalse: [
			offset := matchData lastMatchIndex + 1.
			aBlock value ]
]

{ #category : 'private' }
PCRE2Code >> matchAll: subject from: start to: end offsetsDo: aBlock [
	"Iteratively match over a range of the subject and execute a block with the match and groups' offsets after each successful match"

	| offset |
	offset := start.
	[
	offset > end or: [
		(self matchBytes: subject from: offset to: end) == -1 ] ]
		whileFalse: [
			| offsets |
			aBlock value: (offsets := matchData offsets).
			offset := (offsets at: 2) + 1 ]
]

{ #category : 'private' }
PCRE2Code >> matchBytes: subject from: start to: end [
	"Run a match over a range of the UTF-encoded subject and populate the match data.
	This is a single match operation that ends when the pattern either has no matches
	or is fully matched once, no matter how many times it can match in the subject."

	| rc |
	(matchData isPersistent or: [ matchData isNull ])
		ifTrue: [ self reuseMatchDataFromPattern ]
		ifFalse: [ matchData reset ].

	rc := isJIT
		      ifFalse: [ self match: subject from: start - 1 to: end ]
		      ifTrue: [ self jitMatch: subject from: start - 1 to: end ].

	rc > 0 ifTrue: [ "success -> rc is the number of offset pairs, maximum is 65536 (match and up to 65535 capture groups)"
		matchData count: rc.
		^ rc ].

	rc == -2 ifTrue: [ "partial match -> match data contains a single offset pair of what partially matched"
		matchData count: 1.
		^ rc ].

	"beyond this point, only error codes remain"
	matchData count: 0. "maintain a correct state"

	rc == -1 ifTrue: [ ^ rc ]. "failed to match -> empty match, no signal"

	rc == 0 ifTrue: [ "success, but ovector is not big enough -> should only happen when the match data is created manually"
		PCRE2Error signal:
			'Not enough memory in match structure to store results' ].

	self errorCode: rc "some kind of unexpected problem -> signal"
]

{ #category : 'accessing' }
PCRE2Code >> matchData [

	^ matchData
]

{ #category : 'accessing' }
PCRE2Code >> matchData: aPCRE2Match [
	"Only useful for using match data created with a context, or not based on the regex object"

	matchData := aPCRE2Match
]

{ #category : 'matching' }
PCRE2Code >> matches: subject [
	"Returns whether the regex fully matches the subject"

	| utfSubject |
	utfSubject := ZnUTF8Encoder default encodeString: subject.
	self matchBytes: utfSubject from: 1 to: utfSubject size.
	matchData offsetsDo: [ :start :end |
		^ start == 1 and: [ end == utfSubject size ] ].
	^ false
]

{ #category : 'matching' }
PCRE2Code >> matchesIn: subject [
	"Equivalent of RxMatcher >> #matchesIn:"

	^ self findAll: subject
]

{ #category : 'matching' }
PCRE2Code >> matchesIn: subject collect: aBlock [
	"Equivalent of RxMatcher >> #matchesIn:collect:"

	| result |
	result := OrderedCollection new.
	self
		findAll: subject
		do: [ :match | result add: (aBlock value: match) ].
	^ result
]

{ #category : 'matching' }
PCRE2Code >> matchesIn: subject do: aBlock [
	"Equivalent of RxMatcher >> #matchesIn:do:"

	self findAll: subject do: aBlock
]

{ #category : 'private' }
PCRE2Code >> matchesPrefix: subject [
	"Returns whether the regex matches the start of the subject"

	| utfSubject |
	utfSubject := ZnUTF8Encoder default encodeString: subject.
	self matchBytes: utfSubject from: 1 to: utfSubject size.
	matchData offsetsDo: [ :start :end | ^ start == 1 ].
	^ false
]

{ #category : 'matching' }
PCRE2Code >> matchingRangesIn: subject [
	"Equivalent of RxMatcher >> #matchingRangesIn:"

	| ranges |
	self shouldBeImplemented. "requires utf offset when decoding"
	ranges := OrderedCollection new.
	self findAll: subject do: [  ].
	^ ranges
]

{ #category : 'documentation' }
PCRE2Code >> namedGroups [
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

{ #category : 'accessing' }
PCRE2Code >> pattern: aString [
	"Must only be used by the compiler"

	pattern := aString
]

{ #category : 'copying' }
PCRE2Code >> postCopy [
	"Copy the external structure of the compiled pattern"

	handle := self privateCopy.
	handle isNull ifTrue: [
		PCRE2Error signal: 'Failed to obtain memory to copy matcher' ].
	self autoRelease initialize.
	isJIT ifTrue: [ self compileJIT ]
]

{ #category : 'private' }
PCRE2Code >> privateCopy [
	"This function makes a copy of the memory used for a compiled pattern, excluding any memory used by the JIT compiler.
	Without a subsequent call to jit_compile(), the copy can be used only for non-JIT matching.
	The pointer to the character tables is copied, not the tables themselves (see pcre2_code_copy_with_tables()).
	The yield of the function is NULL if code is NULL or if sufficient memory cannot be obtained."

	self ffiCall: #(void *pcre2_code_copy_8(self))
]

{ #category : 'persistence' }
PCRE2Code >> recompile [
	"Recreate the external compiled pattern"

	self setHandle: (compiler compileBasic: pattern).
	self isJIT ifTrue: [ compiler compileJIT: self ]
]

{ #category : 'persistence' }
PCRE2Code >> restoreFrom: bytes [
	"This method is for convenience, it is much more effective to serialize matchers in bulk"

	LibPCRE2 restore: { self } from: bytes
]

{ #category : 'initialization' }
PCRE2Code >> reuseMatchDataFromPattern [
	"Keep the same match data instance and update its handle"

	| pointer |
	pointer := self createMatchDataFromPattern.
	pointer isNull ifTrue: [ "should only happen if out of memory"
		PCRE2Error signal: 'Failed to obtain memory to create match data' ].
	matchData reset setHandle: pointer
]

{ #category : 'matching' }
PCRE2Code >> search: subject [
	"Returns whether the regex partially matches the subject"

	| utfSubject |
	utfSubject := ZnUTF8Encoder default encodeString: subject.
	self matchBytes: utfSubject from: 1 to: utfSubject size.
	^ matchData count > 0
]

{ #category : 'persistence' }
PCRE2Code >> serialize [
	"Serialize the external memory of the matcher structure, excluding JIT code.
	This method is for convenience, it is much more effective to serialize matchers in bulk,
	both in terms of speed and memory, since the character table (1088 bytes) is encoded in the result."

	^ LibPCRE2 serialize: { self }
]

{ #category : 'accessing' }
PCRE2Code >> startIndex [
	"Available after a match, returns the index where the compiled pattern started matching"

	^ matchData ifNotNil: [ "as 1-based" matchData startIndex + 1 ]
]

{ #category : 'private' }
PCRE2Code >> substitute: subject from: start to: end replacement: replacement upTo: rLength output: buffer size: outSize [
"This function applies a compiled re to a subject string and creates a new
string with substitutions. The first 7 arguments are the same as for
pcre2_match(). Either string length may be PCRE2_ZERO_TERMINATED.

Arguments:
  code            points to the compiled expression
  subject         points to the subject string
  length          length of subject string (may contain binary zeros)
  start_offset    where to start in the subject string
  options         option bits
  match_data      points to a match_data block, or is NULL
  context         points a PCRE2 context
  replacement     points to the replacement string
  rlength         length of replacement string
  buffer          where to put the substituted string
  blength         points to length of buffer; updated to length of string

Returns:          >= 0 number of substitutions made
                  < 0 an error code
                  PCRE2_ERROR_BADREPLACEMENT means invalid use of $"

	"int pcre2_substitute(const pcre2_code *code, PCRE2_SPTR subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data *match_data, pcre2_match_context *mcontext, PCRE2_SPTR replacement, PCRE2_SIZE rlength, PCRE2_UCHAR *outputbuffer, PCRE2_SIZE *outlengthptr)"

	self ffiCall: #(int pcre2_substitute_8(self, char *subject, size_t end, size_t start, uint32 options, void *matchData, void *context, char *replacement, size_t rLength, void *buffer, SizeTHolder outSize))
]

{ #category : 'matching' }
PCRE2Code >> substitute: subject with: replacement [
	"Returns the subject with each match substituted with the replacement.
	The replacement string is treated as a regex substitution expression
	that can reference captured groups or use conditional substitutions."

	| encoder utfSubject utfReplacement buffer bufferSize rc |
	encoder := ZnUTF8Encoder default.
	utfSubject := encoder encodeString: subject.
	utfReplacement := ZnUTF8Encoder default encodeString: replacement.
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

{ #category : 'initialization' }
PCRE2Code >> useMatchDataFromPattern [
	"Create a new match data based on the pattern"

	| pointer |
	pointer := self createMatchDataFromPattern.
	pointer isNull ifTrue: [ "should only happen if out of memory"
		PCRE2Error signal: 'Failed to obtain memory to create match data' ].
	(matchData := PCRE2Match fromHandle: pointer) initialize autoRelease
]
