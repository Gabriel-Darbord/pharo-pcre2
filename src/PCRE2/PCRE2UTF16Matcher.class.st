"
Represents a compiled PCRE2 pattern using 16-bit code units.

The shared matching API lives on PCRE2Matcher. This subclass supplies the libpcre2-16 FFI entry points, and offsets are interpreted as UTF-16 code-unit indexes before prepared input translates them back to Pharo character ranges.
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
	compiler copyContextIfPresent ifNotNil: [ :contextCopy | newCompiler context: contextCopy ].
	newCompiler
		options: compiler options;
		optionsJIT: anInteger;
		compileJIT: self.
	compiler := newCompiler
]

{ #category : 'private' }
PCRE2UTF16Matcher >> compilerClass [

	^ PCRE2UTF16Compiler
]

{ #category : 'private' }
PCRE2UTF16Matcher >> createMatchContext [
	"Create and initialize a new UTF-16 match context.
	The result is NULL if memory could not be obtained."

	self ffiCall:
		#( #PCRE2UTF16MatchContext #* pcre2_match_context_create_16
		   #( nil ) )
]

{ #category : 'private' }
PCRE2UTF16Matcher >> createMatchDataFromPattern [
	"Create match data sized for this 16-bit compiled pattern."

	self ffiCall: #( void #* pcre2_match_data_create_from_pattern_16
		   #( self #, nil ) )
]

{ #category : 'private' }
PCRE2UTF16Matcher >> createMatchDataWithOvectorSize: ovectorSize [
	"Create 16-bit match data with room for an explicit number of code-unit offset pairs."

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
	"Run pcre2_dfa_match_16 with caller-managed match data and workspace storage. start is a zero-based code-unit offset, end is the subject length in code units, and PCRE2 writes code-unit offsets into the match data."

	self ffiCall:
		#( int pcre2_dfa_match_16 #( self #, void #* subject #, size_t
		      end #, size_t start #, uint32 options #, #PCRE2UTF16Match
		      #* aMatchData #, void #* context #, void #* workspace
		      #, size_t workspaceSize ) )
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
	"Run pcre2_jit_match_16 on a prepared PCRE2-16 subject buffer. start is a zero-based code-unit offset, end is the subject length in code units, and PCRE2 writes code-unit offsets into the match data."

	self ffiCall:
		#( int pcre2_jit_match_16 #( self #, void #* subject #, size_t
		      end #, size_t start #, uint32 matchOptions #, #PCRE2UTF16Match
		      #* aMatchData #, void #* context ) )
]

{ #category : 'private' }
PCRE2UTF16Matcher >> match: subject from: start to: end options: matchOptions matchData: aMatchData [
	"Run pcre2_match_16 on a prepared PCRE2-16 subject buffer. start is a zero-based code-unit offset, end is the subject length in code units, and PCRE2 writes code-unit offsets into the match data."

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
PCRE2UTF16Matcher >> privateCopyWithCharacterTables [
	"Copy a compiled 16-bit pattern and any referenced low-character tables. The copy does not include JIT data.
	pcre2_code *pcre2_code_copy_with_tables_16(const pcre2_code *code)"

	self ffiCall: #( void #* pcre2_code_copy_with_tables_16
		   #( self ) )
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
