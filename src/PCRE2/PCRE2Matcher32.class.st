"
Represents a compiled PCRE2 pattern using 32-bit code units.

The public matching protocol is shared with PCRE2Matcher where possible. Width-specific FFI entry points live here so calls are bound to libpcre2-32 and offsets are interpreted as UTF-32 code-unit indexes.
"
Class {
	#name : 'PCRE2Matcher32',
	#superclass : 'PCRE2Matcher',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'documentation' }
PCRE2Matcher32 >> codeUnitWidth [

	^ 32
]

{ #category : 'compiling' }
PCRE2Matcher32 >> compileJIT: anInteger [
	"Request JIT (re-)compilation for this 32-bit compiled pattern."

	| newCompiler |
	newCompiler := PCRE2Compiler32 new.
	compiler copyContextIfPresent ifNotNil: [ :contextCopy |
		newCompiler context: contextCopy ].
	newCompiler
		options: compiler options;
		optionsJIT: anInteger;
		compileJIT: self.
	compiler := newCompiler
]

{ #category : 'match enumeration' }
PCRE2Matcher32 >> copy: subject matchesDo: aBlock [
	"UTF-32 copy/replacement helpers need width-specific streaming before they are exposed."

	PCRE2Error signal: 'UTF-32 copy helpers are not implemented yet'
]

{ #category : 'private' }
PCRE2Matcher32 >> createMatchContext [
	"UTF-32 match contexts need width-specific wrappers before callouts/tracing can be safely exposed."

	PCRE2Error signal: 'UTF-32 match contexts are not implemented yet'
]

{ #category : 'private' }
PCRE2Matcher32 >> createMatchDataFromPattern [
	"Create match data sized for this 32-bit compiled pattern."

	self ffiCall: #( void #* pcre2_match_data_create_from_pattern_32
		   #( self #, nil ) )
]

{ #category : 'private' }
PCRE2Matcher32 >> createMatchDataWithOvectorSize: ovectorSize [
	"Create 32-bit match data with room for an explicit number of offset pairs."

	self ffiCall:
		#( void #* pcre2_match_data_create_32 #( uint32 ovectorSize
		      #, nil ) )
]

{ #category : 'private' }
PCRE2Matcher32 >> dfaMatch: subject from: start to: end matchData: aMatchData workspace: workspace size: workspaceSize [
	"UTF-32 DFA matching needs width-specific tests before it is exposed."

	PCRE2Error signal: 'UTF-32 DFA matching is not implemented yet'
]

{ #category : 'library path' }
PCRE2Matcher32 >> ffiLibraryName [

	^ LibPCRE232
]

{ #category : 'external resource management' }
PCRE2Matcher32 >> free [

	self ffiCall: #( void pcre2_code_free_32 #( self ) )
]

{ #category : 'private' }
PCRE2Matcher32 >> info: what output: where [
	"int pcre2_pattern_info_32(const pcre2_code *code, uint32_t what, void *where)"

	self ffiCall:
		#( int pcre2_pattern_info_32 #( self #, uint32 what #, void #* where ) )
]

{ #category : 'private' }
PCRE2Matcher32 >> jitMatch: subject from: start to: end options: matchOptions matchData: aMatchData [
	"Run pcre2_jit_match_32 on a prepared UTF-32 subject buffer and write offsets into the provided match data."

	self ffiCall:
		#( int pcre2_jit_match_32 #( self #, void #* subject #, size_t
		      end #, size_t start #, uint32 matchOptions #, PCRE2Match32
		      #* aMatchData #, void #* context ) )
]

{ #category : 'private' }
PCRE2Matcher32 >> match: subject from: start to: end options: matchOptions matchData: aMatchData [
	"Run pcre2_match_32 on a prepared UTF-32 subject buffer and write offsets into the provided match data.
	int pcre2_match_32(const pcre2_code *code, PCRE2_SPTR32 subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data *match_data, pcre2_match_context *mcontext)"

	self ffiCall:
		#( int pcre2_match_32 #( self #, void #* subject #, size_t end #, size_t
		      start #, uint32 matchOptions #, PCRE2Match32 #* aMatchData
		      #, void #* context ) )
]

{ #category : 'private' }
PCRE2Matcher32 >> matchClass [

	^ PCRE2Match32
]

{ #category : 'private' }
PCRE2Matcher32 >> preparedInputFor: aStringOrInput [

	^ aStringOrInput asPCRE2UTF32Input
]

{ #category : 'private' }
PCRE2Matcher32 >> privateCopy [
	"Copy a compiled 32-bit pattern. The copy does not include JIT data."

	self ffiCall: #( void #* pcre2_code_copy_32 #( self ) )
]

{ #category : 'private' }
PCRE2Matcher32 >> readNamedGroups [
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
PCRE2Matcher32 >> substitute: subject with: replacement options: substituteOptions matchData: aPCRE2Match [
	"UTF-32 substitution needs width-specific output decoding before it is exposed."

	PCRE2Error signal: 'UTF-32 substitution is not implemented yet'
]

{ #category : 'private' }
PCRE2Matcher32 >> substituteBytes: subjectBytes replacement: replacement options: substituteOptions matchData: aPCRE2Match [
	"UTF-32 substitution needs width-specific output decoding before it is exposed."

	PCRE2Error signal: 'UTF-32 substitution is not implemented yet'
]

{ #category : 'private' }
PCRE2Matcher32 >> temporaryMatcherAddingCompileOptions: compileOptions matchOptions: matchOptions [
	"Answer a temporary UTF-32 matcher compiled from the receiver's source with additional options."

	| sourceCompiler temporaryCompiler temporaryMatcher |
	sourceCompiler := compiler ifNil: [ PCRE2Compiler32 new ].
	temporaryCompiler := PCRE2Compiler32 new.
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
