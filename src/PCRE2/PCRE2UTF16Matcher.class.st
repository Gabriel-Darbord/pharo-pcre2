"
Represents a compiled PCRE2 pattern using 16-bit code units.

The public matching protocol is shared with PCRE2Matcher where possible. Width-specific FFI entry points live here so calls are bound to libpcre2-16 and offsets are interpreted as UTF-16 code-unit indexes.
"
Class {
	#name : 'PCRE2UTF16Matcher',
	#superclass : 'PCRE2Matcher',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'documentation' }
PCRE2UTF16Matcher >> codeUnitWidth [

	^ 16
]

{ #category : 'compiling' }
PCRE2UTF16Matcher >> compileJIT: anInteger [
	"Request JIT (re-)compilation for this 16-bit compiled pattern."

	| newCompiler |
	newCompiler := PCRE2UTF16Compiler new.
	compiler copyContextIfPresent ifNotNil: [ :contextCopy |
		newCompiler context: contextCopy ].
	newCompiler
		options: compiler options;
		optionsJIT: anInteger;
		compileJIT: self.
	compiler := newCompiler
]

{ #category : 'private' }
PCRE2UTF16Matcher >> createMatchContext [
	"UTF-16 match contexts need width-specific wrappers before callouts/tracing can be safely exposed."

	PCRE2Error signal: 'UTF-16 match contexts are not implemented yet'
]

{ #category : 'private' }
PCRE2UTF16Matcher >> createMatchDataFromPattern [
	"Create match data sized for this 16-bit compiled pattern."

	self ffiCall: #( void #* pcre2_match_data_create_from_pattern_16
		   #( self #, nil ) )
]

{ #category : 'private' }
PCRE2UTF16Matcher >> createMatchDataWithOvectorSize: ovectorSize [
	"Create 16-bit match data with room for an explicit number of offset pairs."

	self ffiCall:
		#( void #* pcre2_match_data_create_16 #( uint32 ovectorSize
		      #, nil ) )
]

{ #category : 'private' }
PCRE2UTF16Matcher >> decodeSubstitutionOutput: buffer codeUnits: codeUnitCount [
	"Decode a native-endian UTF-16 substitution output buffer."

	| byteSize bytes |
	codeUnitCount = 0 ifTrue: [ ^ String new ].
	byteSize := codeUnitCount * self codeUnitByteSize.
	bytes := buffer copyFrom: 1 to: byteSize.
	^ (PCRE2UTF16Input fromNativeEndianBytes: bytes) decodeBytes: bytes
]

{ #category : 'private' }
PCRE2UTF16Matcher >> dfaMatch: subject from: start to: end matchData: aMatchData workspace: workspace size: workspaceSize [
	"UTF-16 DFA matching needs width-specific tests before it is exposed."

	PCRE2Error signal: 'UTF-16 DFA matching is not implemented yet'
]

{ #category : 'private' }
PCRE2UTF16Matcher >> enumerateCalloutsWith: callback [
	"Enumerate static callout sites in the compiled 16-bit pattern. This does not run a match or change the matcher.
	int pcre2_callout_enumerate_16(const pcre2_code_16 *code, int (*callback)(pcre2_callout_enumerate_block_16 *, void *), void *user_data)"

	self ffiCall:
		#( int pcre2_callout_enumerate_16 #( self #, FFICallback callback
		      #, nil ) )
]

{ #category : 'library path' }
PCRE2UTF16Matcher >> ffiLibraryName [

	^ LibPCRE2UTF16
]

{ #category : 'external resource management' }
PCRE2UTF16Matcher >> free [

	self ffiCall: #( void pcre2_code_free_16 #( self ) )
]

{ #category : 'private' }
PCRE2UTF16Matcher >> info: what output: where [
	"int pcre2_pattern_info_16(const pcre2_code *code, uint32_t what, void *where)"

	self ffiCall:
		#( int pcre2_pattern_info_16 #( self #, uint32 what #, void #* where ) )
]

{ #category : 'private' }
PCRE2UTF16Matcher >> jitMatch: subject from: start to: end options: matchOptions matchData: aMatchData [
	"Run pcre2_jit_match_16 on a prepared UTF-16 subject buffer and write offsets into the provided match data."

	self ffiCall:
		#( int pcre2_jit_match_16 #( self #, void #* subject #, size_t
		      end #, size_t start #, uint32 matchOptions #, #PCRE2UTF16Match
		      #* aMatchData #, void #* context ) )
]

{ #category : 'private' }
PCRE2UTF16Matcher >> match: subject from: start to: end options: matchOptions matchData: aMatchData [
	"Run pcre2_match_16 on a prepared UTF-16 subject buffer and write offsets into the provided match data.
	int pcre2_match_16(const pcre2_code *code, PCRE2_SPTR16 subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data *match_data, pcre2_match_context *mcontext)"

	self ffiCall:
		#( int pcre2_match_16 #( self #, void #* subject #, size_t end #, size_t
		      start #, uint32 matchOptions #, #PCRE2UTF16Match
		      #* aMatchData #, void #* context ) )
]

{ #category : 'private' }
PCRE2UTF16Matcher >> matchClass [

	^ PCRE2UTF16Match
]

{ #category : 'private' }
PCRE2UTF16Matcher >> preparedInputFor: aStringOrInput [

	^ aStringOrInput asPCRE2UTF16Input
]

{ #category : 'private' }
PCRE2UTF16Matcher >> privateCopy [
	"Copy a compiled 16-bit pattern. The copy does not include JIT data."

	self ffiCall: #( void #* pcre2_code_copy_16 #( self ) )
]

{ #category : 'private' }
PCRE2UTF16Matcher >> readNamedGroups [
	"Read PCRE2-16's name table into a sparse Array keyed by capture group number."

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
		captureIndex := buffer uint16AtOffset: offset * 2.
		name := String streamContents: [ :stream |
			        | codeUnit |
			        [
			        offset := offset + 1.
			        codeUnit := buffer uint16AtOffset: offset * 2.
			        codeUnit = 0 ] whileFalse: [
				        stream nextPut: (Character value: codeUnit) ] ].
		table at: captureIndex put: name ].
	^ table
]

{ #category : 'private' }
PCRE2UTF16Matcher >> substitute: subject from: start to: end options: substituteOptions matchedData: aPCRE2Match replacement: replacement upTo: rLength output: buffer size: outSize [
	"Apply substitutions into caller-provided UTF-16 output storage using precomputed match data for the first match."

	self ffiCall:
		#( int pcre2_substitute_16 #( self #, void #* subject #, size_t
		      end #, size_t start #, uint32 substituteOptions
		      #, #PCRE2UTF16Match #* aPCRE2Match #, void #* context #, void
		      #* replacement #, size_t rLength #, void #* buffer #, SizeTHolder
		      outSize ) )
]

{ #category : 'private' }
PCRE2UTF16Matcher >> substitute: subject from: start to: end options: substituteOptions replacement: replacement upTo: rLength output: buffer size: outSize [
	"Apply substitutions into caller-provided UTF-16 output storage without precomputed match data.
	Subject, replacement, and output are prepared native-endian code-unit buffers, so use void* to keep UFFI string conversion out of the call.
	int pcre2_substitute_16(const pcre2_code_16 *code, PCRE2_SPTR16 subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data_16 *match_data, pcre2_match_context_16 *mcontext, PCRE2_SPTR16 replacement, PCRE2_SIZE rlength, PCRE2_UCHAR16 *outputbuffer, PCRE2_SIZE *outlengthptr)"

	self ffiCall:
		#( int pcre2_substitute_16 #( self #, void #* subject #, size_t
		      end #, size_t start #, uint32 substituteOptions
		      #, nil #, void #* context #, void #* replacement #, size_t
		      rLength #, void #* buffer #, SizeTHolder outSize ) )
]

{ #category : 'private' }
PCRE2UTF16Matcher >> temporaryMatcherAddingCompileOptions: compileOptions matchOptions: matchOptions [
	"Answer a temporary UTF-16 matcher compiled from the receiver's source with additional options."

	| sourceCompiler temporaryCompiler temporaryMatcher |
	sourceCompiler := compiler ifNil: [ PCRE2UTF16Compiler new ].
	temporaryCompiler := PCRE2UTF16Compiler new.
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
