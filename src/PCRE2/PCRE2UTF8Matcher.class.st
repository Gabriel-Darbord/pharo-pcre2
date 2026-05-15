"
Represents a compiled PCRE2 pattern using 8-bit UTF-8 code units.

Most users get this class through PCRE2Compiler or String>>asPerlCompatibleRegex. The shared matching API lives on PCRE2Matcher; this subclass supplies the libpcre2-8 FFI entry points, UTF-8 input preparation, substitution, callouts, tracing, and DFA support.
"
Class {
	#name : 'PCRE2UTF8Matcher',
	#superclass : 'PCRE2Matcher',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'documentation' }
PCRE2UTF8Matcher >> codeUnitWidth [
	"Answer the PCRE2 code-unit width used by this matcher."

	^ 8
]

{ #category : 'compiling' }
PCRE2UTF8Matcher >> compileJIT: anInteger [
	"Request JIT (re-)compilation for this 8-bit compiled pattern."

	| newCompiler |
	newCompiler := PCRE2UTF8Compiler new.
	compiler copyContextIfPresent ifNotNil: [ :contextCopy |
		newCompiler context: contextCopy ].
	newCompiler
		options: compiler options;
		optionsJIT: anInteger;
		compileJIT: self.
	compiler := newCompiler
]

{ #category : 'match enumeration' }
PCRE2UTF8Matcher >> copy: subject matchesDo: aBlock [
	"Copy the subject and execute a block for each match."

	| input lastIndex rs ws |
	input := self preparedInputFor: subject.
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

{ #category : 'private' }
PCRE2UTF8Matcher >> createMatchContext [
	"This function creates and initializes a new match context.
	If its argument is NULL, malloc() is used to get the necessary memory; otherwise the memory allocation function within the general context is used.
	The result is NULL if the memory could not be obtained."

	self ffiCall: #(PCRE2MatchContext *pcre2_match_context_create_8(nil))
]

{ #category : 'private' }
PCRE2UTF8Matcher >> createMatchDataFromPattern [
	"Create a new match data structure with enough space to store the offsets of the match and all capture groups
	pcre2_match_data *pcre2_match_data_create_from_pattern(const pcre2_code *code, pcre2_general_context *gcontext)"

	self ffiCall: #(void *pcre2_match_data_create_from_pattern_8(self, nil))
]

{ #category : 'private' }
PCRE2UTF8Matcher >> createMatchDataWithOvectorSize: ovectorSize [
	"Create a new match data structure with room for an explicit number of offset pairs.
	pcre2_match_data *pcre2_match_data_create(uint32_t ovecsize, pcre2_general_context *gcontext)"

	self ffiCall:
		#( void #* pcre2_match_data_create_8 #( uint32 ovectorSize
		      #, nil ) )
]

{ #category : 'private' }
PCRE2UTF8Matcher >> decodeUTF8Output: buffer upTo: byteSize [
	"Decode a PCRE2 UTF-8 output buffer back to a Pharo string."

	byteSize = 0 ifTrue: [ ^ String new ].
	^ ZnUTF8Encoder default decodeBytes:
		  (buffer copyFrom: 1 to: byteSize)
]

{ #category : 'private' }
PCRE2UTF8Matcher >> dfaMatch: subject from: start to: end matchData: aMatchData workspace: workspace size: workspaceSize [
	"Run a DFA match with caller-managed match data and workspace storage. Subject and workspace are prepared raw buffers, so both use void* to avoid UFFI element/string conversion.
	int pcre2_dfa_match_8(const pcre2_code *code, PCRE2_SPTR subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data *match_data, pcre2_match_context *mcontext, int *workspace, PCRE2_SIZE wscount)"

	self ffiCall:
		#( int pcre2_dfa_match_8 #( self #, void #* subject #, size_t end
		      #, size_t start #, uint32 options #, PCRE2Match #* aMatchData
		      #, void #* context #, void #* workspace #, size_t workspaceSize ) )
]

{ #category : 'private' }
PCRE2UTF8Matcher >> enumerateCalloutsWith: callback [
	"Enumerate static callout sites in the compiled pattern. This does not run a match or change the matcher.
	int pcre2_callout_enumerate_8(const pcre2_code *code, int (*callback)(pcre2_callout_enumerate_block *, void *), void *user_data)"

	self ffiCall:
		#( int pcre2_callout_enumerate_8 #( self #, FFICallback callback
		      #, nil ) )
]

{ #category : 'external resource management' }
PCRE2UTF8Matcher >> free [

	self ffiCall: #(void pcre2_code_free_8(self))
]

{ #category : 'private' }
PCRE2UTF8Matcher >> info: what output: where [

	"int pcre2_pattern_info(const pcre2_code *code, uint32_t what, void *where)"

	self ffiCall: #(int pcre2_pattern_info_8(self, uint32 what, void *where))
]

{ #category : 'private' }
PCRE2UTF8Matcher >> jitMatch: subject from: start to: end options: matchOptions matchData: aMatchData [
	"Run pcre2_jit_match_8 on a prepared UTF-8 subject buffer and write offsets into the provided match data. Use void* for the subject because encoding and lifetime are managed explicitly before the FFI call.
	int pcre2_jit_match_8(const pcre2_code *code, PCRE2_SPTR subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data *match_data, pcre2_match_context *mcontext)"

	self ffiCall:
		#( int pcre2_jit_match_8 #( self #, void #* subject #, size_t end
		      #, size_t start #, uint32 matchOptions #, PCRE2Match
		      #* aMatchData #, void #* context ) )
]

{ #category : 'private' }
PCRE2UTF8Matcher >> match: subject from: start to: end options: matchOptions matchData: aMatchData [
	"Run pcre2_match_8 on a prepared UTF-8 subject buffer and write offsets into the provided match data. Use void* for the subject because encoding and lifetime are managed explicitly before the FFI call.
	int pcre2_match_8(const pcre2_code *code, PCRE2_SPTR subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data *match_data, pcre2_match_context *mcontext)"

	self ffiCall:
		#( int pcre2_match_8 #( self #, void #* subject #, size_t end #, size_t
		      start #, uint32 matchOptions #, PCRE2Match #* aMatchData
		      #, void #* context ) )
]

{ #category : 'private' }
PCRE2UTF8Matcher >> matchClass [

	^ PCRE2UTF8Match
]

{ #category : 'private' }
PCRE2UTF8Matcher >> preparedInputFor: aStringOrInput [

	^ aStringOrInput asPCRE2UTF8Input
]

{ #category : 'private' }
PCRE2UTF8Matcher >> privateCopy [
	"This function makes a copy of the memory used for a compiled pattern, excluding any memory used by the JIT compiler.
	Without a subsequent call to jit_compile(), the copy can be used only for non-JIT matching.
	The pointer to the character tables is copied, not the tables themselves (see pcre2_code_copy_with_tables()).
	The yield of the function is NULL if code is NULL or if sufficient memory cannot be obtained."

	self ffiCall: #(void *pcre2_code_copy_8(self))
]

{ #category : 'private' }
PCRE2UTF8Matcher >> readNamedGroups [
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

{ #category : 'private' }
PCRE2UTF8Matcher >> substitute: subject from: start to: end options: substituteOptions matchData: aPCRE2Match replacement: replacement upTo: rLength output: buffer size: outSize [
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
PCRE2UTF8Matcher >> substitute: subject from: start to: end options: substituteOptions matchedData: aPCRE2Match replacement: replacement upTo: rLength output: buffer size: outSize [
	"Apply substitutions into caller-provided output storage using precomputed match data for the first match. Subject, replacement, and output are prepared byte buffers, so use void* for them and let PCRE2 handle the bytes exactly as supplied.
	int pcre2_substitute_8(const pcre2_code *code, PCRE2_SPTR subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data *match_data, pcre2_match_context *mcontext, PCRE2_SPTR replacement, PCRE2_SIZE rlength, PCRE2_UCHAR *outputbuffer, PCRE2_SIZE *outlengthptr)"

	self ffiCall:
		#( int pcre2_substitute_8 #( self #, void #* subject #, size_t
		      end #, size_t start #, uint32 substituteOptions
		      #, PCRE2Match #* aPCRE2Match #, void #* context #, void #* replacement
		      #, size_t rLength #, void #* buffer #, SizeTHolder outSize ) )
]

{ #category : 'private' }
PCRE2UTF8Matcher >> substitute: subject from: start to: end options: substituteOptions replacement: replacement upTo: rLength output: buffer size: outSize [
	"Apply substitutions into caller-provided output storage without precomputed match data. Subject, replacement, and output are prepared byte buffers, so use void* for them and let PCRE2 handle the bytes exactly as supplied.
	int pcre2_substitute_8(const pcre2_code *code, PCRE2_SPTR subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data *match_data, pcre2_match_context *mcontext, PCRE2_SPTR replacement, PCRE2_SIZE rlength, PCRE2_UCHAR *outputbuffer, PCRE2_SIZE *outlengthptr)"

	self ffiCall:
		#( int pcre2_substitute_8 #( self #, void #* subject #, size_t
		      end #, size_t start #, uint32 substituteOptions
		      #, nil #, void #* context #, void #* replacement #, size_t
		      rLength #, void #* buffer #, SizeTHolder outSize ) )
]

{ #category : 'private' }
PCRE2UTF8Matcher >> substitute: subject with: replacement options: substituteOptions matchData: aPCRE2Match [
	"Private helper for pcre2_substitute_8. Encode a normal subject or reuse a prepared UTF-8 input, then pass optional PCRE2 match data to the byte-level helper."

	| input |
	input := self preparedInputFor: subject.
	^ self
		  substituteBytes: input bytes
		  replacement: replacement
		  options: substituteOptions
		  matchData: aPCRE2Match
]

{ #category : 'private' }
PCRE2UTF8Matcher >> substituteBytes: subjectBytes replacement: replacement options: substituteOptions matchData: aPCRE2Match [
	"Apply pcre2_substitute_8 to prepared subject bytes. Automatically enable PCRE2 substituteOverflowLength so large outputs can be retried with the exact required buffer size."

	| buffer bufferSize effectiveOptions rc replacementInput |
	replacementInput := self preparedInputFor: replacement.
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

{ #category : 'private' }
PCRE2UTF8Matcher >> temporaryMatcherAddingCompileOptions: compileOptions matchOptions: matchOptions [
	"Answer a temporary matcher compiled from the receiver's source with additional options."

	| sourceCompiler temporaryCompiler temporaryMatcher |
	sourceCompiler := compiler ifNil: [ PCRE2UTF8Compiler new ].
	temporaryCompiler := PCRE2UTF8Compiler new.
	sourceCompiler copyContextIfPresent ifNotNil: [ :contextCopy |
		temporaryCompiler context: contextCopy ].
	temporaryCompiler
		options: (sourceCompiler options bitOr: compileOptions);
		optionsJIT: sourceCompiler optionsJIT.
	temporaryMatcher := temporaryCompiler compile: pattern.
	temporaryMatcher options: (options bitOr: matchOptions).
	context ifNotNil: [
		temporaryMatcher context: context copy autoRelease ].
	^ temporaryMatcher
]

{ #category : 'private' }
PCRE2UTF8Matcher >> utf8InputFor: aStringOrInput [
	"Compatibility helper for callers using the old internal name."

	^ self preparedInputFor: aStringOrInput
]
