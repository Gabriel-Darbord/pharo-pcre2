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
	compiler copyContextIfPresent ifNotNil: [ :contextCopy | newCompiler context: contextCopy ].
	newCompiler
		options: compiler options;
		optionsJIT: anInteger;
		compileJIT: self.
	compiler := newCompiler
]

{ #category : 'private' }
PCRE2UTF32Matcher >> compilerClass [

	^ PCRE2UTF32Compiler
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
	"Create 32-bit match data with room for an explicit number of code-unit offset pairs."

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
	"Run pcre2_dfa_match_32 with caller-managed match data and workspace storage. start is a zero-based code-unit offset, end is the subject length in code units, and PCRE2 writes code-unit offsets into the match data."

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
	"Run pcre2_jit_match_32 on a prepared PCRE2-32 subject buffer. start is a zero-based code-unit offset, end is the subject length in code units, and PCRE2 writes code-unit offsets into the match data."

	self ffiCall:
		#( int pcre2_jit_match_32 #( self #, void #* subject #, size_t
		      end #, size_t start #, uint32 matchOptions #, #PCRE2UTF32Match
		      #* aMatchData #, void #* context ) )
]

{ #category : 'private' }
PCRE2UTF32Matcher >> match: subject from: start to: end options: matchOptions matchData: aMatchData [
	"Run pcre2_match_32 on a prepared PCRE2-32 subject buffer. start is a zero-based code-unit offset, end is the subject length in code units, and PCRE2 writes code-unit offsets into the match data."

	self ffiCall:
		#( int pcre2_match_32 #( self #, void #* subject #, size_t end #, size_t
		      start #, uint32 matchOptions #, #PCRE2UTF32Match
		      #* aMatchData #, void #* context ) )
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
