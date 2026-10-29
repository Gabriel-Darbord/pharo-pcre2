Class {
	#name : 'PCRE2MatcherUTF8FFIBackend',
	#superclass : 'PCRE2MatcherFFIBackend',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'private - native' }
PCRE2MatcherUTF8FFIBackend >> codeUnitWidth [
	"Answer the PCRE2 code-unit width used by this matcher."

	^ 8
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> createMatchDataFromPattern [
	"Create match data with enough room for the full match and capture-group code-unit offset pairs."

	self ffiCall: #(void *pcre2_match_data_create_from_pattern_8(self, nil))
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> createMatchDataWithOvectorSize: ovectorSize [
	"Create 8-bit match data with room for an explicit number of code-unit offset pairs."

	self ffiCall: #(void *pcre2_match_data_create_8(uint32 ovectorSize, nil))
]

{ #category : 'private - native' }
PCRE2MatcherUTF8FFIBackend >> decodeSubstitutionOutput: buffer codeUnits: codeUnitCount [
	"Decode a PCRE2-8 substitution output buffer. For this width, code units are bytes."

	codeUnitCount = 0 ifTrue: [ ^ String new ].
	^ ZnUTF8Encoder default decodeBytes: (buffer copyFrom: 1 to: codeUnitCount)
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> dfaMatch: subject from: start to: end matchData: aMatchData workspace: workspace size: workspaceSize [
	"Run pcre2_dfa_match_8 with caller-managed match data and workspace storage. start is a zero-based code-unit offset, end is the subject length in code units, and PCRE2 writes code-unit offsets into the match data."

	self ffiCall: #(int pcre2_dfa_match_8(self, void *subject, size_t end, size_t start, uint32 options, PCRE2MatchUTF8FFIBackend *aMatchData, void *context, void *workspace, size_t workspaceSize))
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> enumerateCalloutsWith: callback [
	"Enumerate static callout sites in the compiled pattern. This does not run a match or change the matcher.
	int pcre2_callout_enumerate_8(const pcre2_code *code, int (*callback)(pcre2_callout_enumerate_block *, void *), void *user_data)"

	self ffiCall: #(int pcre2_callout_enumerate_8(self, FFICallback callback, nil))
]

{ #category : 'private - native' }
PCRE2MatcherUTF8FFIBackend >> ffiLibraryName [

	^ LibPCRE2UTF8
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> free [

	self ffiCall: #(void pcre2_code_free_8(self))
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> info: what output: where [
	"int pcre2_pattern_info(const pcre2_code *code, uint32_t what, void *where)"

	self ffiCall: #(int pcre2_pattern_info_8(self, uint32 what, void *where))
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> jitMatch: subject from: start to: end options: matchOptions matchData: aMatchData [
	"Run pcre2_jit_match_8 on a prepared PCRE2-8 subject buffer. start is a zero-based code-unit offset, end is the subject length in code units, and PCRE2 writes code-unit offsets into the match data."

	self ffiCall: #(int pcre2_jit_match_8(self, void *subject, size_t end, size_t start, uint32 matchOptions, PCRE2MatchUTF8FFIBackend *aMatchData, void *context))
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> match: subject from: start to: end options: matchOptions matchData: aMatchData [
	"Run pcre2_match_8 on a prepared PCRE2-8 subject buffer. start is a zero-based code-unit offset, end is the subject length in code units, and PCRE2 writes code-unit offsets into the match data."

	self ffiCall: #(int pcre2_match_8(self, void *subject, size_t end, size_t start, uint32 matchOptions, PCRE2MatchUTF8FFIBackend *aMatchData, void *context))
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> matchBackendClass [

	^ PCRE2MatchUTF8FFIBackend
]

{ #category : 'private - native' }
PCRE2MatcherUTF8FFIBackend >> preparedInputFor: aStringOrInput [

	^ aStringOrInput asPCRE2UTF8Input
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> privateCopy [
	"This function makes a copy of the memory used for a compiled pattern, excluding any memory used by the JIT compiler.
	Without a subsequent call to jit_compile(), the copy can be used only for non-JIT matching.
	The pointer to the character tables is copied, not the tables themselves (see pcre2_code_copy_with_tables()).
	The yield of the function is NULL if code is NULL or if sufficient memory cannot be obtained."

	self ffiCall: #(void *pcre2_code_copy_8(self))
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> privateCopyWithCharacterTables [
	"Copy a compiled 8-bit pattern and any referenced low-character tables. The copy does not include JIT data.
	pcre2_code *pcre2_code_copy_with_tables_8(const pcre2_code *code)"

	self ffiCall: #(void *pcre2_code_copy_with_tables_8(self))
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> substitute: subject from: start to: end options: substituteOptions matchData: aPCRE2Match replacement: replacement upTo: rLength output: buffer size: outSize [
	"Apply substitutions into caller-provided output storage. Subject, replacement, and output are prepared byte buffers, so use void* for them and let PCRE2 handle the bytes exactly as supplied.
	int pcre2_substitute_8(const pcre2_code *code, PCRE2_SPTR subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data *match_data, pcre2_match_context *mcontext, PCRE2_SPTR replacement, PCRE2_SIZE rlength, PCRE2_UCHAR *outputbuffer, PCRE2_SIZE *outlengthptr)"

	self ffiCall: #(int pcre2_substitute_8(self, void *subject, size_t end, size_t start, uint32 substituteOptions, void *aPCRE2Match, void *context, void *replacement, size_t rLength, void *buffer, SizeTHolder outSize))
]
