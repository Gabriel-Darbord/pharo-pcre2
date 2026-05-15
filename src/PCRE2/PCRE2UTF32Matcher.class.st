"
Represents a compiled PCRE2 pattern using 32-bit code units.

The public matching protocol is shared with PCRE2Matcher where possible. Width-specific FFI entry points live here so calls are bound to libpcre2-32 and offsets are interpreted as UTF-32 code-unit indexes.
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

{ #category : 'match enumeration' }
PCRE2UTF32Matcher >> copy: subject matchesDo: aBlock [
	"UTF-32 copy/replacement helpers need width-specific streaming before they are exposed."

	PCRE2Error signal: 'UTF-32 copy helpers are not implemented yet'
]

{ #category : 'private' }
PCRE2UTF32Matcher >> createMatchContext [
	"UTF-32 match contexts need width-specific wrappers before callouts/tracing can be safely exposed."

	PCRE2Error signal: 'UTF-32 match contexts are not implemented yet'
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
PCRE2UTF32Matcher >> dfaMatch: subject from: start to: end matchData: aMatchData workspace: workspace size: workspaceSize [
	"UTF-32 DFA matching needs width-specific tests before it is exposed."

	PCRE2Error signal: 'UTF-32 DFA matching is not implemented yet'
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
PCRE2UTF32Matcher >> substitute: subject with: replacement options: substituteOptions matchData: aPCRE2Match [
	"UTF-32 substitution needs width-specific output decoding before it is exposed."

	PCRE2Error signal: 'UTF-32 substitution is not implemented yet'
]

{ #category : 'private' }
PCRE2UTF32Matcher >> substituteBytes: subjectBytes replacement: replacement options: substituteOptions matchData: aPCRE2Match [
	"UTF-32 substitution needs width-specific output decoding before it is exposed."

	PCRE2Error signal: 'UTF-32 substitution is not implemented yet'
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
