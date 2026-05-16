"
Represents a compiled PCRE2 pattern using 32-bit code units.

The shared matching API lives on PCRE2Matcher. This subclass supplies the libpcre2-32 FFI entry points, and offsets are interpreted as UTF-32 code-unit indexes before prepared input translates them back to Pharo character ranges.
"
Class {
	#name : 'PCRE2UTF32Matcher',
	#superclass : 'PCRE2Matcher',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'documentation' }
PCRE2UTF32Matcher >> codeUnitWidth [

	^ 32
]

{ #category : 'compiling' }
PCRE2UTF32Matcher >> compileJIT: anInteger [
	"Request JIT (re-)compilation for this 32-bit compiled pattern."

	| newCompiler |
	newCompiler := PCRE2UTF32Compiler new.
	compiler copyContextIfPresent ifNotNil: [ :contextCopy |
		newCompiler context: contextCopy ].
	newCompiler
		options: compiler options;
		optionsJIT: anInteger;
		compileJIT: self.
	compiler := newCompiler
]

{ #category : 'private' }
PCRE2UTF32Matcher >> createMatchContext [
	"Create and initialize a new UTF-32 match context.
	The result is NULL if memory could not be obtained."

	self ffiCall:
		#( #PCRE2UTF32MatchContext #* pcre2_match_context_create_32
		   #( nil ) )
]

{ #category : 'private' }
PCRE2UTF32Matcher >> createMatchDataFromPattern [
	"Create match data sized for this 32-bit compiled pattern."

	self ffiCall: #( void #* pcre2_match_data_create_from_pattern_32
		   #( self #, nil ) )
]

{ #category : 'private' }
PCRE2UTF32Matcher >> createMatchDataWithOvectorSize: ovectorSize [
	"Create 32-bit match data with room for an explicit number of offset pairs."

	self ffiCall:
		#( void #* pcre2_match_data_create_32 #( uint32 ovectorSize
		      #, nil ) )
]

{ #category : 'private' }
PCRE2UTF32Matcher >> decodeSubstitutionOutput: buffer codeUnits: codeUnitCount [
	"Decode a native-endian UTF-32 substitution output buffer."

	| byteSize bytes |
	codeUnitCount = 0 ifTrue: [ ^ String new ].
	byteSize := codeUnitCount * self codeUnitByteSize.
	bytes := buffer copyFrom: 1 to: byteSize.
	^ (PCRE2UTF32Input fromNativeEndianBytes: bytes) decodeBytes: bytes
]

{ #category : 'private' }
PCRE2UTF32Matcher >> dfaMatch: subject from: start to: end matchData: aMatchData workspace: workspace size: workspaceSize [
	"Run a UTF-32 DFA match with caller-managed match data and workspace storage.
	Subject and workspace are prepared raw buffers, so both use void* to avoid UFFI element/string conversion.
	int pcre2_dfa_match_32(const pcre2_code_32 *code, PCRE2_SPTR32 subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data_32 *match_data, pcre2_match_context_32 *mcontext, int *workspace, PCRE2_SIZE wscount)"

	self ffiCall:
		#( int pcre2_dfa_match_32 #( self #, void #* subject #, size_t
		      end #, size_t start #, uint32 options #, #PCRE2UTF32Match
		      #* aMatchData #, void #* context #, void #* workspace
		      #, size_t workspaceSize ) )
]

{ #category : 'private' }
PCRE2UTF32Matcher >> enumerateCalloutsWith: callback [
	"Enumerate static callout sites in the compiled 32-bit pattern. This does not run a match or change the matcher.
	int pcre2_callout_enumerate_32(const pcre2_code_32 *code, int (*callback)(pcre2_callout_enumerate_block_32 *, void *), void *user_data)"

	self ffiCall:
		#( int pcre2_callout_enumerate_32 #( self #, FFICallback callback
		      #, nil ) )
]

{ #category : 'library path' }
PCRE2UTF32Matcher >> ffiLibraryName [

	^ LibPCRE2UTF32
]

{ #category : 'external resource management' }
PCRE2UTF32Matcher >> free [

	self ffiCall: #( void pcre2_code_free_32 #( self ) )
]

{ #category : 'private' }
PCRE2UTF32Matcher >> info: what output: where [
	"int pcre2_pattern_info_32(const pcre2_code *code, uint32_t what, void *where)"

	self ffiCall:
		#( int pcre2_pattern_info_32 #( self #, uint32 what #, void #* where ) )
]

{ #category : 'private' }
PCRE2UTF32Matcher >> jitMatch: subject from: start to: end options: matchOptions matchData: aMatchData [
	"Run pcre2_jit_match_32 on a prepared UTF-32 subject buffer and write offsets into the provided match data."

	self ffiCall:
		#( int pcre2_jit_match_32 #( self #, void #* subject #, size_t
		      end #, size_t start #, uint32 matchOptions #, #PCRE2UTF32Match
		      #* aMatchData #, void #* context ) )
]

{ #category : 'private' }
PCRE2UTF32Matcher >> match: subject from: start to: end options: matchOptions matchData: aMatchData [
	"Run pcre2_match_32 on a prepared UTF-32 subject buffer and write offsets into the provided match data.
	int pcre2_match_32(const pcre2_code *code, PCRE2_SPTR32 subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data *match_data, pcre2_match_context *mcontext)"

	self ffiCall:
		#( int pcre2_match_32 #( self #, void #* subject #, size_t end #, size_t
		      start #, uint32 matchOptions #, #PCRE2UTF32Match #* aMatchData
		      #, void #* context ) )
]

{ #category : 'private' }
PCRE2UTF32Matcher >> matchClass [

	^ PCRE2UTF32Match
]

{ #category : 'private' }
PCRE2UTF32Matcher >> preparedInputFor: aStringOrInput [

	^ aStringOrInput asPCRE2UTF32Input
]

{ #category : 'private' }
PCRE2UTF32Matcher >> privateCopy [
	"Copy a compiled 32-bit pattern. The copy does not include JIT data."

	self ffiCall: #( void #* pcre2_code_copy_32 #( self ) )
]

{ #category : 'private' }
PCRE2UTF32Matcher >> privateCopyWithCharacterTables [
	"Copy a compiled 32-bit pattern and any referenced low-character tables. The copy does not include JIT data.
	pcre2_code *pcre2_code_copy_with_tables_32(const pcre2_code *code)"

	self ffiCall: #( void #* pcre2_code_copy_with_tables_32
		   #( self ) )
]

{ #category : 'private' }
PCRE2UTF32Matcher >> readNamedGroups [
	"Read PCRE2-32's name table into a sparse Array keyed by capture group number."

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

	1 to: nameCount do: [ :entryIndex |
		| captureIndex name offset |
		offset := entrySize * (entryIndex - 1).
		captureIndex := buffer uint32AtOffset: offset * 4.
		name := String streamContents: [ :stream |
			        | codeUnit |
			        [
			        offset := offset + 1.
			        codeUnit := buffer uint32AtOffset: offset * 4.
			        codeUnit = 0 ] whileFalse: [
				        stream nextPut: (Character value: codeUnit) ] ].
		table at: captureIndex put: name ].
	^ table
]

{ #category : 'private' }
PCRE2UTF32Matcher >> substitute: subject from: start to: end options: substituteOptions matchedData: aPCRE2Match replacement: replacement upTo: rLength output: buffer size: outSize [
	"Apply substitutions into caller-provided UTF-32 output storage using precomputed match data for the first match."

	self ffiCall:
		#( int pcre2_substitute_32 #( self #, void #* subject #, size_t
		      end #, size_t start #, uint32 substituteOptions
		      #, #PCRE2UTF32Match #* aPCRE2Match #, void #* context #, void
		      #* replacement #, size_t rLength #, void #* buffer #, SizeTHolder
		      outSize ) )
]

{ #category : 'private' }
PCRE2UTF32Matcher >> substitute: subject from: start to: end options: substituteOptions replacement: replacement upTo: rLength output: buffer size: outSize [
	"Apply substitutions into caller-provided UTF-32 output storage without precomputed match data.
	Subject, replacement, and output are prepared native-endian code-unit buffers, so use void* to keep UFFI string conversion out of the call.
	int pcre2_substitute_32(const pcre2_code_32 *code, PCRE2_SPTR32 subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data_32 *match_data, pcre2_match_context_32 *mcontext, PCRE2_SPTR32 replacement, PCRE2_SIZE rlength, PCRE2_UCHAR32 *outputbuffer, PCRE2_SIZE *outlengthptr)"

	self ffiCall:
		#( int pcre2_substitute_32 #( self #, void #* subject #, size_t
		      end #, size_t start #, uint32 substituteOptions
		      #, nil #, void #* context #, void #* replacement #, size_t
		      rLength #, void #* buffer #, SizeTHolder outSize ) )
]

{ #category : 'private' }
PCRE2UTF32Matcher >> temporaryMatcherAddingCompileOptions: compileOptions matchOptions: matchOptions [
	"Answer a temporary UTF-32 matcher compiled from the receiver's source with additional options."

	| sourceCompiler temporaryCompiler temporaryMatcher |
	sourceCompiler := compiler ifNil: [ PCRE2UTF32Compiler new ].
	temporaryCompiler := PCRE2UTF32Compiler new.
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
